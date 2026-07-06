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

$outputRoot = Split-Path -Parent $PSScriptRoot
$inventoryGuiPath = Join-Path $PSScriptRoot 'Portable-Network-Inventory-GUI.ps1'
$scannerPrepPath = Join-Path $PSScriptRoot 'Prepare-Inventory-Scanner.ps1'
$driverShopPath = Join-Path $PSScriptRoot 'Export-DriverShop.ps1'
$remoteDriverPullPath = Join-Path $PSScriptRoot 'Remote-DriverShop-Pull.ps1'
$driverShopRoot = Join-Path $outputRoot 'Data\DriverShop'

foreach ($requiredPath in $inventoryGuiPath, $scannerPrepPath, $driverShopPath, $remoteDriverPullPath) {
    if (-not (Test-Path -LiteralPath $requiredPath)) {
        throw "Missing required script: $requiredPath"
    }
}

if (-not (Test-Path -LiteralPath $driverShopRoot)) {
    New-Item -ItemType Directory -Path $driverShopRoot -Force | Out-Null
}

function Start-ElevatedPowerShellScript {
    param(
        [Parameter(Mandatory)]
        [string]$ScriptPath,
        [string[]]$AdditionalArguments = @()
    )

    $argumentList = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $ScriptPath) + $AdditionalArguments
    $process = Start-Process -FilePath 'powershell.exe' -Verb RunAs -Wait -PassThru -ArgumentList $argumentList
    return $process.ExitCode
}

$form = New-Object System.Windows.Forms.Form
$form.Text = 'ERDS Toolbox'
$form.StartPosition = 'CenterScreen'
$form.Size = New-Object System.Drawing.Size(760, 250)
$form.MinimumSize = New-Object System.Drawing.Size(760, 250)
$form.MaximumSize = New-Object System.Drawing.Size(760, 250)

$title = New-Object System.Windows.Forms.Label
$title.Text = 'Choose a task'
$title.Font = New-Object System.Drawing.Font('Segoe UI', 18, [System.Drawing.FontStyle]::Bold)
$title.Location = New-Object System.Drawing.Point(20, 18)
$title.Size = New-Object System.Drawing.Size(300, 35)
$form.Controls.Add($title)

$subtitle = New-Object System.Windows.Forms.Label
$subtitle.Text = 'Inventory scanning plus local or remote driver export'
$subtitle.Font = New-Object System.Drawing.Font('Segoe UI', 10)
$subtitle.Location = New-Object System.Drawing.Point(22, 55)
$subtitle.Size = New-Object System.Drawing.Size(420, 22)
$form.Controls.Add($subtitle)

$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Text = "DriverShop folder: $driverShopRoot"
$statusLabel.Location = New-Object System.Drawing.Point(22, 175)
$statusLabel.Size = New-Object System.Drawing.Size(700, 40)
$form.Controls.Add($statusLabel)

$inventoryButton = New-Object System.Windows.Forms.Button
$inventoryButton.Text = 'Inventory Scan'
$inventoryButton.Font = New-Object System.Drawing.Font('Segoe UI', 12, [System.Drawing.FontStyle]::Bold)
$inventoryButton.Location = New-Object System.Drawing.Point(22, 95)
$inventoryButton.Size = New-Object System.Drawing.Size(220, 60)
$form.Controls.Add($inventoryButton)

$driverShopButton = New-Object System.Windows.Forms.Button
$driverShopButton.Text = 'DriverShop Export'
$driverShopButton.Font = New-Object System.Drawing.Font('Segoe UI', 12, [System.Drawing.FontStyle]::Bold)
$driverShopButton.Location = New-Object System.Drawing.Point(267, 95)
$driverShopButton.Size = New-Object System.Drawing.Size(220, 60)
$form.Controls.Add($driverShopButton)

$remoteDriverButton = New-Object System.Windows.Forms.Button
$remoteDriverButton.Text = 'Remote Driver Pull'
$remoteDriverButton.Font = New-Object System.Drawing.Font('Segoe UI', 12, [System.Drawing.FontStyle]::Bold)
$remoteDriverButton.Location = New-Object System.Drawing.Point(512, 95)
$remoteDriverButton.Size = New-Object System.Drawing.Size(220, 60)
$form.Controls.Add($remoteDriverButton)

$inventoryButton.Add_Click({
    try {
        $inventoryButton.Enabled = $false
        $driverShopButton.Enabled = $false
        $remoteDriverButton.Enabled = $false
        $statusLabel.Text = 'Preparing scanner trust for inventory...'
        [System.Windows.Forms.Application]::DoEvents()

        $exitCode = Start-ElevatedPowerShellScript -ScriptPath $scannerPrepPath -AdditionalArguments @('-GuiScriptPath', $inventoryGuiPath)
        if ($exitCode -ne 0) {
            throw "Scanner preparation ended with exit code $exitCode."
        }

        $statusLabel.Text = 'Launching inventory GUI...'
        [System.Windows.Forms.Application]::DoEvents()
        Start-Process -FilePath 'powershell.exe' -ArgumentList @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-STA', '-File', $inventoryGuiPath) | Out-Null
        $form.Close()
    } catch {
        [System.Windows.Forms.MessageBox]::Show(
            $_.Exception.Message,
            'Inventory Launch Error',
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        ) | Out-Null
        $statusLabel.Text = "Inventory launch failed: $($_.Exception.Message)"
        $inventoryButton.Enabled = $true
        $driverShopButton.Enabled = $true
        $remoteDriverButton.Enabled = $true
    }
})

$driverShopButton.Add_Click({
    try {
        $inventoryButton.Enabled = $false
        $driverShopButton.Enabled = $false
        $remoteDriverButton.Enabled = $false
        $statusLabel.Text = 'Exporting local installed drivers to DriverShop...'
        [System.Windows.Forms.Application]::DoEvents()

        $exitCode = Start-ElevatedPowerShellScript -ScriptPath $driverShopPath
        if ($exitCode -ne 0) {
            throw "Driver export ended with exit code $exitCode."
        }

        $statusLabel.Text = "Driver export complete. Folder root: $driverShopRoot"
        $inventoryButton.Enabled = $true
        $driverShopButton.Enabled = $true
        $remoteDriverButton.Enabled = $true
    } catch {
        [System.Windows.Forms.MessageBox]::Show(
            $_.Exception.Message,
            'DriverShop Export Error',
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        ) | Out-Null
        $statusLabel.Text = "Driver export failed: $($_.Exception.Message)"
        $inventoryButton.Enabled = $true
        $driverShopButton.Enabled = $true
        $remoteDriverButton.Enabled = $true
    }
})

$remoteDriverButton.Add_Click({
    try {
        $inventoryButton.Enabled = $false
        $driverShopButton.Enabled = $false
        $remoteDriverButton.Enabled = $false
        $statusLabel.Text = 'Preparing scanner trust for remote driver pull...'
        [System.Windows.Forms.Application]::DoEvents()

        $exitCode = Start-ElevatedPowerShellScript -ScriptPath $scannerPrepPath -AdditionalArguments @('-GuiScriptPath', $inventoryGuiPath)
        if ($exitCode -ne 0) {
            throw "Scanner preparation ended with exit code $exitCode."
        }

        $statusLabel.Text = 'Launching remote driver selector...'
        [System.Windows.Forms.Application]::DoEvents()
        Start-Process -FilePath 'powershell.exe' -ArgumentList @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-STA', '-File', $remoteDriverPullPath) | Out-Null
        $form.Close()
    } catch {
        [System.Windows.Forms.MessageBox]::Show(
            $_.Exception.Message,
            'Remote Driver Pull Error',
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        ) | Out-Null
        $statusLabel.Text = "Remote driver launch failed: $($_.Exception.Message)"
        $inventoryButton.Enabled = $true
        $driverShopButton.Enabled = $true
        $remoteDriverButton.Enabled = $true
    }
})

[void]$form.ShowDialog()
