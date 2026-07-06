Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ([Threading.Thread]::CurrentThread.ApartmentState -ne 'STA' -and $PSCommandPath) {
    $powershellExe = Join-Path $env:WINDIR 'System32\WindowsPowerShell\v1.0\powershell.exe'
    if (Test-Path -LiteralPath $powershellExe) {
        Start-Process -FilePath $powershellExe -ArgumentList @(
            '-NoProfile',
            '-ExecutionPolicy', 'Bypass',
            '-STA',
            '-File', $PSCommandPath
        )
        return
    }
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

$IpEnvVarName = 'COMPUTER_SCAN_IPS'
$OutputRoot = Split-Path -Parent $PSScriptRoot
$DriverShopRoot = Join-Path $OutputRoot 'Data\DriverShop'
$RemoteDriverShopRoot = Join-Path $DriverShopRoot 'Remote'
$InventoryGuiPath = Join-Path $PSScriptRoot 'Portable-Network-Inventory-GUI.ps1'

function Get-PresetIPsFromGuiScript {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return @()
    }

    $content = Get-Content -LiteralPath $Path
    $startIndex = -1
    for ($i = 0; $i -lt $content.Count; $i++) {
        if ($content[$i] -match '^\$PresetIPs\s*=\s*@\(') {
            $startIndex = $i + 1
            break
        }
    }

    if ($startIndex -lt 0) {
        return @()
    }

    $items = New-Object System.Collections.Generic.List[string]
    for ($i = $startIndex; $i -lt $content.Count; $i++) {
        $line = $content[$i].Trim()
        if ($line -eq ')') {
            break
        }

        if ($line -match "^'([^']+)'\s*,?$") {
            $items.Add($matches[1])
        }
    }

    return @($items)
}

function Get-ConfiguredIPs {
    $sourceValue = [Environment]::GetEnvironmentVariable($IpEnvVarName, 'Process')
    if ([string]::IsNullOrWhiteSpace($sourceValue)) {
        $sourceValue = [Environment]::GetEnvironmentVariable($IpEnvVarName, 'User')
    }
    if ([string]::IsNullOrWhiteSpace($sourceValue)) {
        $sourceValue = [Environment]::GetEnvironmentVariable($IpEnvVarName, 'Machine')
    }

    $rawItems = if ([string]::IsNullOrWhiteSpace($sourceValue)) {
        Get-PresetIPsFromGuiScript -Path $InventoryGuiPath
    } else {
        $sourceValue -split '[,;`r`n ]+'
    }

    $ipList = foreach ($item in $rawItems) {
        $trimmed = $item.Trim()
        if (-not $trimmed) {
            continue
        }

        $parsed = $null
        if ([Net.IPAddress]::TryParse($trimmed, [ref]$parsed) -and $parsed.AddressFamily -eq [Net.Sockets.AddressFamily]::InterNetwork) {
            $trimmed
        }
    }

    $distinct = @($ipList | Sort-Object -Unique)
    if (-not $distinct) {
        throw "No valid IPv4 addresses were found. Edit `$PresetIPs in Portable-Network-Inventory-GUI.ps1 or set the $IpEnvVarName environment variable."
    }

    return $distinct
}

function Test-RemoteStatus {
    param(
        [Parameter(Mandatory)]
        [string]$IPAddress
    )

    try {
        $null = Test-WSMan -ComputerName $IPAddress -ErrorAction Stop
        return 'WinRM Ready'
    } catch {
        try {
            if (Test-Connection -ComputerName $IPAddress -Count 1 -Quiet -ErrorAction Stop) {
                return 'Ping OK, WinRM failed'
            }
        } catch {
        }
    }

    return 'No response'
}

function Ensure-DriverShopFolders {
    foreach ($path in $DriverShopRoot, $RemoteDriverShopRoot) {
        if (-not (Test-Path -LiteralPath $path)) {
            New-Item -ItemType Directory -Path $path -Force | Out-Null
        }
    }
}

function New-RemoteDriverPullSessionFolder {
    param(
        [Parameter(Mandatory)]
        [string]$ComputerName
    )

    $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $folder = Join-Path $RemoteDriverShopRoot ("{0}_{1}" -f $ComputerName, $timestamp)
    New-Item -ItemType Directory -Path $folder -Force | Out-Null
    return $folder
}

function Invoke-RemoteDriverPull {
    param(
        [Parameter(Mandatory)]
        [string]$IPAddress,
        [pscredential]$Credential
    )

    $sessionArgs = @{
        ComputerName = $IPAddress
    }
    if ($Credential) {
        $sessionArgs.Credential = $Credential
        $sessionArgs.Authentication = 'Negotiate'
    }

    $session = $null
    $remoteRoot = $null
    $localZip = $null

    try {
        $session = New-PSSession @sessionArgs
        $exportResult = Invoke-Command -Session $session -ScriptBlock {
            $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
            $remoteRoot = Join-Path $env:TEMP ("ERDS_DriverShop_{0}" -f $timestamp)
            $packageFolder = Join-Path $remoteRoot 'Packages'

            New-Item -ItemType Directory -Path $packageFolder -Force | Out-Null

            $inventoryPath = Join-Path $remoteRoot 'DriverInventory.txt'
            $devicesPath = Join-Path $remoteRoot 'InstalledDevices.txt'
            $summaryPath = Join-Path $remoteRoot 'ExportSummary.txt'

            pnputil /enum-drivers | Out-File -FilePath $inventoryPath -Encoding utf8
            pnputil /enum-devices /connected | Out-File -FilePath $devicesPath -Encoding utf8

            $exportMethod = ''
            $exportCmd = Get-Command -Name Export-WindowsDriver -ErrorAction SilentlyContinue
            if ($exportCmd) {
                Export-WindowsDriver -Online -Destination $packageFolder | Out-Null
                $exportMethod = 'Export-WindowsDriver'
            } else {
                $arguments = @('/Online', "/Export-Driver", "/Destination:$packageFolder")
                $process = Start-Process -FilePath dism.exe -ArgumentList $arguments -Wait -PassThru -WindowStyle Hidden
                if ($process.ExitCode -ne 0) {
                    throw "DISM export failed with exit code $($process.ExitCode)."
                }
                $exportMethod = 'DISM'
            }

            $summary = @(
                "ComputerName: $env:COMPUTERNAME"
                "ExportedAt: $((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))"
                "RemoteSourceIP: $using:IPAddress"
                "PackageFolder: $packageFolder"
                "ExportMethod: $exportMethod"
                'InstallOnTarget: pnputil /add-driver ".\Packages\*.inf" /subdirs /install'
            ) -join [Environment]::NewLine

            [IO.File]::WriteAllText($summaryPath, $summary, [Text.UTF8Encoding]::new($false))

            $zipPath = Join-Path $env:TEMP ("ERDS_DriverShop_{0}_{1}.zip" -f $env:COMPUTERNAME, $timestamp)
            if (Test-Path -LiteralPath $zipPath) {
                Remove-Item -LiteralPath $zipPath -Force
            }
            Compress-Archive -Path (Join-Path $remoteRoot '*') -DestinationPath $zipPath -Force

            [pscustomobject]@{
                ComputerName = $env:COMPUTERNAME
                RemoteRoot   = $remoteRoot
                ZipPath      = $zipPath
                ExportMethod = $exportMethod
            }
        }

        $localFolder = New-RemoteDriverPullSessionFolder -ComputerName $exportResult.ComputerName
        $localZip = Join-Path $localFolder ("{0}.zip" -f $exportResult.ComputerName)
        Copy-Item -FromSession $session -Path $exportResult.ZipPath -Destination $localZip -Force
        Expand-Archive -Path $localZip -DestinationPath $localFolder -Force
        Remove-Item -LiteralPath $localZip -Force -ErrorAction SilentlyContinue

        Invoke-Command -Session $session -ScriptBlock {
            param(
                [string]$RemoteRoot,
                [string]$ZipPath
            )

            if (Test-Path -LiteralPath $RemoteRoot) {
                Remove-Item -LiteralPath $RemoteRoot -Recurse -Force
            }
            if (Test-Path -LiteralPath $ZipPath) {
                Remove-Item -LiteralPath $ZipPath -Force
            }
        } -ArgumentList $exportResult.RemoteRoot, $exportResult.ZipPath | Out-Null

        return [pscustomobject]@{
            IPAddress    = $IPAddress
            ComputerName = $exportResult.ComputerName
            OutputFolder = $localFolder
            ExportMethod = $exportResult.ExportMethod
        }
    } finally {
        if ($session) {
            Remove-PSSession -Session $session -ErrorAction SilentlyContinue
        }
    }
}

Ensure-DriverShopFolders

$script:ConfiguredIPs = Get-ConfiguredIPs
$script:SelectedCredential = $null

$form = New-Object System.Windows.Forms.Form
$form.Text = 'Remote DriverShop Pull'
$form.StartPosition = 'CenterScreen'
$form.Size = New-Object System.Drawing.Size(900, 560)
$form.MinimumSize = New-Object System.Drawing.Size(900, 560)

$labelTitle = New-Object System.Windows.Forms.Label
$labelTitle.Text = 'Select remote computers from the configured IP list'
$labelTitle.Font = New-Object System.Drawing.Font('Segoe UI', 14, [System.Drawing.FontStyle]::Bold)
$labelTitle.Location = New-Object System.Drawing.Point(14, 14)
$labelTitle.Size = New-Object System.Drawing.Size(540, 30)
$form.Controls.Add($labelTitle)

$labelSubtitle = New-Object System.Windows.Forms.Label
$labelSubtitle.Text = "Exports land in $RemoteDriverShopRoot"
$labelSubtitle.Location = New-Object System.Drawing.Point(16, 45)
$labelSubtitle.Size = New-Object System.Drawing.Size(840, 20)
$form.Controls.Add($labelSubtitle)

$btnCredential = New-Object System.Windows.Forms.Button
$btnCredential.Text = 'Set Credential'
$btnCredential.Location = New-Object System.Drawing.Point(16, 78)
$btnCredential.Size = New-Object System.Drawing.Size(120, 30)
$form.Controls.Add($btnCredential)

$btnRefresh = New-Object System.Windows.Forms.Button
$btnRefresh.Text = 'Refresh Status'
$btnRefresh.Location = New-Object System.Drawing.Point(148, 78)
$btnRefresh.Size = New-Object System.Drawing.Size(120, 30)
$form.Controls.Add($btnRefresh)

$btnSelectAll = New-Object System.Windows.Forms.Button
$btnSelectAll.Text = 'Select All'
$btnSelectAll.Location = New-Object System.Drawing.Point(280, 78)
$btnSelectAll.Size = New-Object System.Drawing.Size(100, 30)
$form.Controls.Add($btnSelectAll)

$btnPull = New-Object System.Windows.Forms.Button
$btnPull.Text = 'Pull Selected Drivers'
$btnPull.Location = New-Object System.Drawing.Point(392, 78)
$btnPull.Size = New-Object System.Drawing.Size(160, 30)
$form.Controls.Add($btnPull)

$labelCredential = New-Object System.Windows.Forms.Label
$labelCredential.Text = 'Credential: current Windows logon'
$labelCredential.Location = New-Object System.Drawing.Point(570, 84)
$labelCredential.Size = New-Object System.Drawing.Size(300, 20)
$form.Controls.Add($labelCredential)

$listView = New-Object System.Windows.Forms.ListView
$listView.Location = New-Object System.Drawing.Point(16, 122)
$listView.Size = New-Object System.Drawing.Size(520, 385)
$listView.View = 'Details'
$listView.CheckBoxes = $true
$listView.FullRowSelect = $true
$listView.GridLines = $true
$listView.MultiSelect = $true
[void]$listView.Columns.Add('IP Address', 145)
[void]$listView.Columns.Add('Status', 170)
[void]$listView.Columns.Add('Host', 175)
$form.Controls.Add($listView)

$txtLog = New-Object System.Windows.Forms.TextBox
$txtLog.Location = New-Object System.Drawing.Point(550, 122)
$txtLog.Size = New-Object System.Drawing.Size(320, 385)
$txtLog.Multiline = $true
$txtLog.ReadOnly = $true
$txtLog.ScrollBars = 'Vertical'
$txtLog.Font = New-Object System.Drawing.Font('Consolas', 9)
$form.Controls.Add($txtLog)

function Write-Log {
    param(
        [Parameter(Mandatory)]
        [string]$Message
    )

    $timestamp = Get-Date -Format 'HH:mm:ss'
    $txtLog.AppendText("[$timestamp] $Message$([Environment]::NewLine)")
}

function Populate-IpList {
    $listView.Items.Clear()
    foreach ($ip in $script:ConfiguredIPs) {
        $item = New-Object System.Windows.Forms.ListViewItem($ip)
        [void]$item.SubItems.Add('Configured')
        [void]$item.SubItems.Add('')
        $item.Checked = $true
        [void]$listView.Items.Add($item)
    }
}

$btnCredential.Add_Click({
    try {
        $script:SelectedCredential = Get-Credential -Message 'Enter authorized credentials for remote driver export, or cancel to use the current Windows logon.'
        if ($script:SelectedCredential) {
            $labelCredential.Text = "Credential: $($script:SelectedCredential.UserName)"
        } else {
            $labelCredential.Text = 'Credential: current Windows logon'
        }
    } catch {
        [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, 'Credential Error', 'OK', 'Error') | Out-Null
    }
})

$btnSelectAll.Add_Click({
    foreach ($item in $listView.Items) {
        $item.Checked = $true
    }
})

$btnRefresh.Add_Click({
    $btnRefresh.Enabled = $false
    try {
        Write-Log 'Refreshing remote status...'
        foreach ($item in $listView.Items) {
            $ip = $item.Text
            $status = Test-RemoteStatus -IPAddress $ip
            $item.SubItems[1].Text = $status
            if ($status -eq 'WinRM Ready') {
                $item.BackColor = [System.Drawing.Color]::Honeydew
            } elseif ($status -like 'Ping OK*') {
                $item.BackColor = [System.Drawing.Color]::Moccasin
            } else {
                $item.BackColor = [System.Drawing.Color]::MistyRose
            }
            [System.Windows.Forms.Application]::DoEvents()
        }
        Write-Log 'Status refresh complete.'
    } finally {
        $btnRefresh.Enabled = $true
    }
})

$btnPull.Add_Click({
    $selectedItems = @($listView.CheckedItems)
    if (-not $selectedItems) {
        [System.Windows.Forms.MessageBox]::Show('Select at least one IP address first.', 'Nothing Selected', 'OK', 'Information') | Out-Null
        return
    }

    $btnPull.Enabled = $false
    $btnRefresh.Enabled = $false
    $btnCredential.Enabled = $false

    try {
        $results = New-Object System.Collections.Generic.List[object]
        foreach ($item in $selectedItems) {
            $ip = $item.Text
            Write-Log "Pulling drivers from $ip..."
            [System.Windows.Forms.Application]::DoEvents()

            try {
                $result = Invoke-RemoteDriverPull -IPAddress $ip -Credential $script:SelectedCredential
                $item.SubItems[1].Text = 'Pulled'
                $item.SubItems[2].Text = $result.ComputerName
                $item.BackColor = [System.Drawing.Color]::LightCyan
                $results.Add($result)
                Write-Log "Saved $($result.ComputerName) to $($result.OutputFolder)"
            } catch {
                $item.SubItems[1].Text = 'Pull failed'
                $item.BackColor = [System.Drawing.Color]::LightPink
                Write-Log ("Failed for {0}: {1}" -f $ip, $_.Exception.Message)
            }
        }

        if ($results.Count -gt 0) {
            $summary = $results | ForEach-Object { "{0} ({1}) -> {2}" -f $_.ComputerName, $_.IPAddress, $_.OutputFolder }
            [System.Windows.Forms.MessageBox]::Show(
                "Remote driver pull complete.`r`n`r`n$($summary -join "`r`n")",
                'Remote Driver Pull Complete',
                'OK',
                'Information'
            ) | Out-Null
        }
    } finally {
        $btnPull.Enabled = $true
        $btnRefresh.Enabled = $true
        $btnCredential.Enabled = $true
    }
})

Populate-IpList
Write-Log "Loaded $($script:ConfiguredIPs.Count) configured IP address(es)."

try {
    $script:SelectedCredential = Get-Credential -Message 'Enter authorized credentials for remote driver export, or cancel to use the current Windows logon.'
    if ($script:SelectedCredential) {
        $labelCredential.Text = "Credential: $($script:SelectedCredential.UserName)"
    }
} catch {
    $labelCredential.Text = 'Credential: current Windows logon'
}

[void]$form.ShowDialog()
