Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Portable single-file Windows inventory scanner.
# Usage:
#   1. Edit $PresetIPs below, or set COMPUTER_SCAN_IPS to a comma/semicolon/newline separated IPv4 list.
#   2. Run with: powershell -ExecutionPolicy Bypass -File .\scripts\Portable-Network-Inventory-GUI.ps1
#   3. The script prompts for authorized admin credentials at startup; cancel to use the current Windows logon.
# Notes:
#   - Only configured IPs are checked.
#   - Logged-in user, software, and driver details rely on standard Windows remote management access.

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

# Preset fallback list. You can also set COMPUTER_SCAN_IPS to a comma/semicolon/newline separated list.
$PresetIPs = @(
    '192.168.1.10',
    '192.168.1.11',
    '192.168.1.12'
)

$IpEnvVarName = 'COMPUTER_SCAN_IPS'
$ConnectTimeoutMs = 1200
$OutputRoot = Split-Path -Parent $PSScriptRoot
$ExportFolder = Join-Path $OutputRoot 'Data'

# Filters used to identify likely built-in Windows 11 items so the software list stays focused on non-standard apps.
$StandardSoftwareNamePatterns = @(
    '^Update for ',
    '^Security Update ',
    '^Hotfix ',
    '^Microsoft Edge',
    '^Microsoft OneDrive',
    '^Microsoft Visual C\+\+',
    '^Microsoft Windows Desktop Runtime',
    '^Microsoft ASP\.NET',
    '^Microsoft \.NET',
    '^WebView2 Runtime',
    '^Windows ',
    '^Xbox ',
    '^Teams Machine-Wide Installer'
)

$StandardSoftwarePublisherPatterns = @(
    '^Microsoft',
    '^Microsoft Corporation$',
    '^Microsoft Windows$'
)

function Get-ConfiguredIPs {
    $sourceValue = [Environment]::GetEnvironmentVariable($IpEnvVarName, 'Process')
    if ([string]::IsNullOrWhiteSpace($sourceValue)) {
        $sourceValue = [Environment]::GetEnvironmentVariable($IpEnvVarName, 'User')
    }
    if ([string]::IsNullOrWhiteSpace($sourceValue)) {
        $sourceValue = [Environment]::GetEnvironmentVariable($IpEnvVarName, 'Machine')
    }

    $rawItems = if ([string]::IsNullOrWhiteSpace($sourceValue)) {
        $PresetIPs
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

    $distinct = $ipList | Sort-Object -Unique
    if (-not $distinct) {
        throw "No valid IPv4 addresses were found. Edit `$PresetIPs or set the $IpEnvVarName environment variable."
    }

    return $distinct
}

function Convert-ToDisplayDate {
    param(
        [AllowNull()]
        [object]$Value
    )

    if ($null -eq $Value) {
        return ''
    }

    if ($Value -is [datetime]) {
        return $Value.ToString('yyyy-MM-dd HH:mm:ss')
    }

    try {
        return ([Management.ManagementDateTimeConverter]::ToDateTime([string]$Value)).ToString('yyyy-MM-dd HH:mm:ss')
    } catch {
        return [string]$Value
    }
}

function Test-HostReachable {
    param(
        [Parameter(Mandatory)]
        [string]$IPAddress
    )

    $result = [ordered]@{
        Found           = $false
        DiscoveryMethod = ''
    }

    $ping = [Net.NetworkInformation.Ping]::new()
    try {
        $reply = $ping.Send($IPAddress, $ConnectTimeoutMs)
        if ($reply.Status -eq [Net.NetworkInformation.IPStatus]::Success) {
            $result.Found = $true
            $result.DiscoveryMethod = 'ICMP'
            return [pscustomobject]$result
        }
    } catch {
    } finally {
        $ping.Dispose()
    }

    foreach ($port in 135, 445) {
        $client = [Net.Sockets.TcpClient]::new()
        try {
            $async = $client.BeginConnect($IPAddress, $port, $null, $null)
            if ($async.AsyncWaitHandle.WaitOne($ConnectTimeoutMs) -and $client.Connected) {
                $client.EndConnect($async) | Out-Null
                $result.Found = $true
                $result.DiscoveryMethod = "TCP:$port"
                return [pscustomobject]$result
            }
        } catch {
        } finally {
            $client.Dispose()
        }
    }

    return [pscustomobject]$result
}

function New-RemoteCimSession {
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

    $attemptErrors = New-Object System.Collections.Generic.List[string]

    try {
        return New-CimSession @sessionArgs
    } catch {
        $attemptErrors.Add("WSMan failed: $($_.Exception.Message)")
    }

    try {
        $dcomArgs = @{
            ComputerName  = $IPAddress
            SessionOption = (New-CimSessionOption -Protocol Dcom)
        }
        if ($Credential) {
            $dcomArgs.Credential = $Credential
        }
        return New-CimSession @dcomArgs
    } catch {
        $attemptErrors.Add("DCOM failed: $($_.Exception.Message)")
    }

    throw ($attemptErrors -join ' | ')
}

function Invoke-RegistryMethod {
    param(
        [Parameter(Mandatory)]
        [Microsoft.Management.Infrastructure.CimSession]$CimSession,
        [Parameter(Mandatory)]
        [string]$MethodName,
        [Parameter(Mandatory)]
        [uint32]$Hive,
        [Parameter(Mandatory)]
        [string]$SubKey,
        [string]$ValueName
    )

    $arguments = @{
        hDefKey     = $Hive
        sSubKeyName = $SubKey
    }
    if ($PSBoundParameters.ContainsKey('ValueName')) {
        $arguments.sValueName = $ValueName
    }

    return Invoke-CimMethod -CimSession $CimSession -Namespace root/cimv2 -ClassName StdRegProv -MethodName $MethodName -Arguments $arguments
}

function Get-RemoteRegistryString {
    param(
        [Parameter(Mandatory)]
        [Microsoft.Management.Infrastructure.CimSession]$CimSession,
        [Parameter(Mandatory)]
        [uint32]$Hive,
        [Parameter(Mandatory)]
        [string]$SubKey,
        [Parameter(Mandatory)]
        [string]$ValueName
    )

    try {
        $response = Invoke-RegistryMethod -CimSession $CimSession -MethodName GetStringValue -Hive $Hive -SubKey $SubKey -ValueName $ValueName
        return $response.sValue
    } catch {
        return $null
    }
}

function Get-RemoteRegistryDword {
    param(
        [Parameter(Mandatory)]
        [Microsoft.Management.Infrastructure.CimSession]$CimSession,
        [Parameter(Mandatory)]
        [uint32]$Hive,
        [Parameter(Mandatory)]
        [string]$SubKey,
        [Parameter(Mandatory)]
        [string]$ValueName
    )

    try {
        $response = Invoke-RegistryMethod -CimSession $CimSession -MethodName GetDWORDValue -Hive $Hive -SubKey $SubKey -ValueName $ValueName
        return $response.uValue
    } catch {
        return $null
    }
}

function Get-RemoteRegistrySubKeys {
    param(
        [Parameter(Mandatory)]
        [Microsoft.Management.Infrastructure.CimSession]$CimSession,
        [Parameter(Mandatory)]
        [uint32]$Hive,
        [Parameter(Mandatory)]
        [string]$SubKey
    )

    try {
        $response = Invoke-RegistryMethod -CimSession $CimSession -MethodName EnumKey -Hive $Hive -SubKey $SubKey
        return @($response.sNames)
    } catch {
        return @()
    }
}

function Test-IsLikelyStandardSoftware {
    param(
        [string]$DisplayName,
        [string]$Publisher
    )

    if ([string]::IsNullOrWhiteSpace($DisplayName)) {
        return $true
    }

    foreach ($pattern in $StandardSoftwareNamePatterns) {
        if ($DisplayName -match $pattern) {
            return $true
        }
    }

    foreach ($pattern in $StandardSoftwarePublisherPatterns) {
        if ($Publisher -match $pattern) {
            return $true
        }
    }

    return $false
}

function Get-RemoteInstalledSoftware {
    param(
        [Parameter(Mandatory)]
        [Microsoft.Management.Infrastructure.CimSession]$CimSession,
        [Parameter(Mandatory)]
        [string]$IPAddress,
        [Parameter(Mandatory)]
        [string]$ComputerName,
        [Parameter(Mandatory)]
        [datetime]$ScanDate
    )

    $hklm = [uint32]2147483650
    $hku = [uint32]2147483651
    $entries = New-Object System.Collections.Generic.List[object]

    $paths = @(
        [pscustomobject]@{ Hive = $hklm; Path = 'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall'; Scope = 'Machine64' },
        [pscustomobject]@{ Hive = $hklm; Path = 'SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall'; Scope = 'Machine32' }
    )

    foreach ($sid in Get-RemoteRegistrySubKeys -CimSession $CimSession -Hive $hku -SubKey '') {
        if ($sid -notmatch '^S-\d-\d+-.+') {
            continue
        }
        $paths += [pscustomobject]@{
            Hive  = $hku
            Path  = "$sid\Software\Microsoft\Windows\CurrentVersion\Uninstall"
            Scope = "User:$sid"
        }
    }

    foreach ($pathInfo in $paths) {
        foreach ($subKey in Get-RemoteRegistrySubKeys -CimSession $CimSession -Hive $pathInfo.Hive -SubKey $pathInfo.Path) {
            $fullKey = '{0}\{1}' -f $pathInfo.Path, $subKey
            $displayName = Get-RemoteRegistryString -CimSession $CimSession -Hive $pathInfo.Hive -SubKey $fullKey -ValueName 'DisplayName'
            if ([string]::IsNullOrWhiteSpace($displayName)) {
                continue
            }

            $systemComponent = Get-RemoteRegistryDword -CimSession $CimSession -Hive $pathInfo.Hive -SubKey $fullKey -ValueName 'SystemComponent'
            if ($systemComponent -eq 1) {
                continue
            }

            $releaseType = Get-RemoteRegistryString -CimSession $CimSession -Hive $pathInfo.Hive -SubKey $fullKey -ValueName 'ReleaseType'
            if ($releaseType -match 'Update|Hotfix|Security') {
                continue
            }

            $publisher = Get-RemoteRegistryString -CimSession $CimSession -Hive $pathInfo.Hive -SubKey $fullKey -ValueName 'Publisher'
            $displayVersion = Get-RemoteRegistryString -CimSession $CimSession -Hive $pathInfo.Hive -SubKey $fullKey -ValueName 'DisplayVersion'
            $installDate = Get-RemoteRegistryString -CimSession $CimSession -Hive $pathInfo.Hive -SubKey $fullKey -ValueName 'InstallDate'
            $uninstallString = Get-RemoteRegistryString -CimSession $CimSession -Hive $pathInfo.Hive -SubKey $fullKey -ValueName 'UninstallString'

            if (Test-IsLikelyStandardSoftware -DisplayName $displayName -Publisher $publisher) {
                continue
            }

            $entries.Add([pscustomobject]@{
                ScanDate        = $ScanDate.ToString('yyyy-MM-dd HH:mm:ss')
                IPAddress       = $IPAddress
                ComputerName    = $ComputerName
                DisplayName     = $displayName
                DisplayVersion  = $displayVersion
                Publisher       = $publisher
                InstallDate     = $installDate
                Scope           = $pathInfo.Scope
                UninstallString = $uninstallString
            })
        }
    }

    return $entries
}

function Get-RemoteMacAddress {
    param(
        [Parameter(Mandatory)]
        [Microsoft.Management.Infrastructure.CimSession]$CimSession,
        [Parameter(Mandatory)]
        [string]$IPAddress
    )

    try {
        $adapters = Get-CimInstance -CimSession $CimSession -ClassName Win32_NetworkAdapterConfiguration -Filter 'IPEnabled = TRUE'
        foreach ($adapter in $adapters) {
            foreach ($ip in @($adapter.IPAddress)) {
                if ($ip -eq $IPAddress) {
                    return $adapter.MACAddress
                }
            }
        }
    } catch {
    }

    try {
        $neighbor = Get-NetNeighbor -IPAddress $IPAddress -ErrorAction Stop
        if ($neighbor.LinkLayerAddress) {
            return $neighbor.LinkLayerAddress
        }
    } catch {
    }

    return $null
}

function Get-RemoteInventory {
    param(
        [Parameter(Mandatory)]
        [string]$IPAddress,
        [pscredential]$Credential
    )

    $scanDate = Get-Date
    $session = $null
    $notes = New-Object System.Collections.Generic.List[string]
    $software = @()
    $drivers = @()
    $problemDrivers = @()

    try {
        $session = New-RemoteCimSession -IPAddress $IPAddress -Credential $Credential

        $computerSystem = Get-CimInstance -CimSession $session -ClassName Win32_ComputerSystem
        $bios = Get-CimInstance -CimSession $session -ClassName Win32_BIOS
        $os = Get-CimInstance -CimSession $session -ClassName Win32_OperatingSystem
        $mac = Get-RemoteMacAddress -CimSession $session -IPAddress $IPAddress

        try {
            $software = @(Get-RemoteInstalledSoftware -CimSession $session -IPAddress $IPAddress -ComputerName $computerSystem.Name -ScanDate $scanDate)
        } catch {
            $notes.Add("Software inventory unavailable: $($_.Exception.Message)")
        }

        try {
            $drivers = @(Get-CimInstance -CimSession $session -ClassName Win32_PnPSignedDriver | Sort-Object DeviceName | ForEach-Object {
                [pscustomobject]@{
                    ScanDate           = $scanDate.ToString('yyyy-MM-dd HH:mm:ss')
                    IPAddress          = $IPAddress
                    ComputerName       = $computerSystem.Name
                    DeviceName         = $_.DeviceName
                    DriverVersion      = $_.DriverVersion
                    DriverProviderName = $_.DriverProviderName
                    Manufacturer       = $_.Manufacturer
                    DriverDate         = Convert-ToDisplayDate -Value $_.DriverDate
                    InfName            = $_.InfName
                    IsSigned           = $_.IsSigned
                }
            })
        } catch {
            $notes.Add("Installed drivers unavailable: $($_.Exception.Message)")
        }

        try {
            $problemDrivers = @(Get-CimInstance -CimSession $session -ClassName Win32_PnPEntity |
                Where-Object { $_.ConfigManagerErrorCode -ne 0 -or ($_.Status -and $_.Status -ne 'OK') } |
                Sort-Object Name |
                ForEach-Object {
                    [pscustomobject]@{
                        ScanDate               = $scanDate.ToString('yyyy-MM-dd HH:mm:ss')
                        IPAddress              = $IPAddress
                        ComputerName           = $computerSystem.Name
                        DeviceName             = $_.Name
                        PNPClass               = $_.PNPClass
                        Manufacturer           = $_.Manufacturer
                        Service                = $_.Service
                        Status                 = $_.Status
                        ConfigManagerErrorCode = $_.ConfigManagerErrorCode
                    }
                })
        } catch {
            $notes.Add("Problem driver scan unavailable: $($_.Exception.Message)")
        }

        $summary = [pscustomobject]@{
            ScanDate              = $scanDate.ToString('yyyy-MM-dd HH:mm:ss')
            IPAddress             = $IPAddress
            ComputerName          = $computerSystem.Name
            DNSHostName           = $computerSystem.DNSHostName
            MACAddress            = $mac
            LoggedInUser          = $computerSystem.UserName
            Domain                = if ($computerSystem.PartOfDomain) { $computerSystem.Domain } else { '' }
            Manufacturer          = $computerSystem.Manufacturer
            Model                 = $computerSystem.Model
            SerialNumber          = $bios.SerialNumber
            OSCaption             = $os.Caption
            OSVersion             = $os.Version
            LastBoot              = Convert-ToDisplayDate -Value $os.LastBootUpTime
            NonStandardAppCount   = $software.Count
            InstalledDriverCount  = $drivers.Count
            ProblemDriverCount    = $problemDrivers.Count
            Notes                 = ($notes -join ' | ')
            NonStandardSoftware   = $software
            InstalledDrivers      = $drivers
            ProblemDrivers        = $problemDrivers
        }

        return $summary
    } finally {
        if ($session) {
            $session | Remove-CimSession -ErrorAction SilentlyContinue
        }
    }
}

function Format-DeviceDetails {
    param(
        [Parameter(Mandatory)]
        $Device
    )

    $softwarePreview = if ($Device.NonStandardSoftware.Count) {
        ($Device.NonStandardSoftware | Select-Object -ExpandProperty DisplayName | Sort-Object -Unique | Select-Object -First 25) -join [Environment]::NewLine
    } else {
        '(none found)'
    }

    $problemDriverPreview = if ($Device.ProblemDrivers.Count) {
        ($Device.ProblemDrivers | ForEach-Object {
            '{0} | Code {1} | {2}' -f $_.DeviceName, $_.ConfigManagerErrorCode, $_.Status
        } | Select-Object -First 25) -join [Environment]::NewLine
    } else {
        '(none reported)'
    }

    return @"
Scan Date: $($Device.ScanDate)
IP Address: $($Device.IPAddress)
Computer Name: $($Device.ComputerName)
DNS Host Name: $($Device.DNSHostName)
MAC Address: $($Device.MACAddress)
Logged In User: $($Device.LoggedInUser)
Domain: $($Device.Domain)
Manufacturer: $($Device.Manufacturer)
Model: $($Device.Model)
Serial Number: $($Device.SerialNumber)
OS: $($Device.OSCaption)
OS Version: $($Device.OSVersion)
Last Boot: $($Device.LastBoot)
Likely Non-Standard Apps: $($Device.NonStandardAppCount)
Installed Drivers: $($Device.InstalledDriverCount)
Problem/Missing Drivers: $($Device.ProblemDriverCount)
Notes: $($Device.Notes)

Likely Non-Standard Software Preview
$softwarePreview

Problem/Missing Driver Preview
$problemDriverPreview
"@
}

function ConvertTo-ExcelXmlSafeText {
    param(
        [AllowNull()]
        [object]$Value
    )

    $text = if ($null -eq $Value) { '' } else { [string]$Value }
    return [Security.SecurityElement]::Escape($text)
}

function New-ExcelXmlWorksheet {
    param(
        [Parameter(Mandatory)]
        [string]$Name,
        [Parameter(Mandatory)]
        [object[]]$Rows
    )

    $sheetBuilder = New-Object System.Text.StringBuilder
    [void]$sheetBuilder.AppendLine("<Worksheet ss:Name=""$(ConvertTo-ExcelXmlSafeText $Name)"">")
    [void]$sheetBuilder.AppendLine('<Table>')

    $properties = @()
    if ($Rows.Count -gt 0) {
        $properties = @($Rows[0].PSObject.Properties.Name)
        [void]$sheetBuilder.AppendLine('<Row ss:StyleID="Header">')
        foreach ($property in $properties) {
            [void]$sheetBuilder.AppendLine('<Cell><Data ss:Type="String">{0}</Data></Cell>' -f (ConvertTo-ExcelXmlSafeText $property))
        }
        [void]$sheetBuilder.AppendLine('</Row>')

        foreach ($row in $Rows) {
            [void]$sheetBuilder.AppendLine('<Row>')
            foreach ($property in $properties) {
                $value = $row.$property
                $type = if ($value -is [int] -or $value -is [long] -or $value -is [decimal] -or $value -is [double]) { 'Number' } else { 'String' }
                [void]$sheetBuilder.AppendLine('<Cell><Data ss:Type="{0}">{1}</Data></Cell>' -f $type, (ConvertTo-ExcelXmlSafeText $value))
            }
            [void]$sheetBuilder.AppendLine('</Row>')
        }
    } else {
        [void]$sheetBuilder.AppendLine('<Row><Cell><Data ss:Type="String">No data</Data></Cell></Row>')
    }

    [void]$sheetBuilder.AppendLine('</Table>')
    [void]$sheetBuilder.AppendLine('</Worksheet>')
    return $sheetBuilder.ToString()
}

function Export-InventoryToExcelXml {
    param(
        [Parameter(Mandatory)]
        [object[]]$Devices,
        [Parameter(Mandatory)]
        [string]$OutputPath
    )

    $summaryRows = @($Devices | ForEach-Object {
        [pscustomobject]@{
            ScanDate            = $_.ScanDate
            IPAddress           = $_.IPAddress
            ComputerName        = $_.ComputerName
            DNSHostName         = $_.DNSHostName
            MACAddress          = $_.MACAddress
            LoggedInUser        = $_.LoggedInUser
            Domain              = $_.Domain
            Manufacturer        = $_.Manufacturer
            Model               = $_.Model
            SerialNumber        = $_.SerialNumber
            OSCaption           = $_.OSCaption
            OSVersion           = $_.OSVersion
            LastBoot            = $_.LastBoot
            NonStandardAppCount = $_.NonStandardAppCount
            InstalledDriverCount = $_.InstalledDriverCount
            ProblemDriverCount  = $_.ProblemDriverCount
            Notes               = $_.Notes
        }
    })

    $softwareRows = @($Devices | ForEach-Object { $_.NonStandardSoftware })
    $driverRows = @($Devices | ForEach-Object { $_.InstalledDrivers })
    $problemDriverRows = @($Devices | ForEach-Object { $_.ProblemDrivers })

    $xmlBuilder = New-Object System.Text.StringBuilder
    [void]$xmlBuilder.AppendLine('<?xml version="1.0"?>')
    [void]$xmlBuilder.AppendLine('<?mso-application progid="Excel.Sheet"?>')
    [void]$xmlBuilder.AppendLine('<Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet"')
    [void]$xmlBuilder.AppendLine(' xmlns:o="urn:schemas-microsoft-com:office:office"')
    [void]$xmlBuilder.AppendLine(' xmlns:x="urn:schemas-microsoft-com:office:excel"')
    [void]$xmlBuilder.AppendLine(' xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet">')
    [void]$xmlBuilder.AppendLine('<Styles>')
    [void]$xmlBuilder.AppendLine('<Style ss:ID="Header"><Font ss:Bold="1"/></Style>')
    [void]$xmlBuilder.AppendLine('</Styles>')
    [void]$xmlBuilder.AppendLine((New-ExcelXmlWorksheet -Name 'Devices' -Rows $summaryRows))
    [void]$xmlBuilder.AppendLine((New-ExcelXmlWorksheet -Name 'Software' -Rows $softwareRows))
    [void]$xmlBuilder.AppendLine((New-ExcelXmlWorksheet -Name 'InstalledDrivers' -Rows $driverRows))
    [void]$xmlBuilder.AppendLine((New-ExcelXmlWorksheet -Name 'ProblemDrivers' -Rows $problemDriverRows))
    [void]$xmlBuilder.AppendLine('</Workbook>')

    if (-not (Test-Path -LiteralPath (Split-Path -Parent $OutputPath))) {
        New-Item -ItemType Directory -Path (Split-Path -Parent $OutputPath) -Force | Out-Null
    }

    [IO.File]::WriteAllText($OutputPath, $xmlBuilder.ToString(), [Text.UTF8Encoding]::new($false))
    return $OutputPath
}

function New-UiLabel {
    param(
        [string]$Text,
        [int]$X,
        [int]$Y,
        [int]$Width,
        [int]$Height = 20
    )

    $label = New-Object System.Windows.Forms.Label
    $label.Text = $Text
    $label.Location = New-Object System.Drawing.Point($X, $Y)
    $label.Size = New-Object System.Drawing.Size($Width, $Height)
    return $label
}

$script:ScanResults = New-Object System.Collections.Generic.List[object]
$script:ConfiguredIPs = Get-ConfiguredIPs
$script:SelectedCredential = $null

if (-not (Test-Path -LiteralPath $ExportFolder)) {
    New-Item -ItemType Directory -Path $ExportFolder -Force | Out-Null
}

$form = New-Object System.Windows.Forms.Form
$form.Text = 'Portable Network Inventory'
$form.StartPosition = 'CenterScreen'
$form.Size = New-Object System.Drawing.Size(1320, 780)
$form.MinimumSize = New-Object System.Drawing.Size(1200, 720)

$lblIPs = New-UiLabel -Text ("Configured IPs from ${0} or fallback list:" -f ('$' + $IpEnvVarName)) -X 12 -Y 12 -Width 420
$form.Controls.Add($lblIPs)

$txtIPs = New-Object System.Windows.Forms.TextBox
$txtIPs.Location = New-Object System.Drawing.Point(12, 34)
$txtIPs.Size = New-Object System.Drawing.Size(250, 110)
$txtIPs.Multiline = $true
$txtIPs.ReadOnly = $true
$txtIPs.ScrollBars = 'Vertical'
$txtIPs.Text = ($script:ConfiguredIPs -join [Environment]::NewLine)
$form.Controls.Add($txtIPs)

$btnCredential = New-Object System.Windows.Forms.Button
$btnCredential.Text = 'Set Credential'
$btnCredential.Location = New-Object System.Drawing.Point(280, 34)
$btnCredential.Size = New-Object System.Drawing.Size(120, 30)
$form.Controls.Add($btnCredential)

$btnScan = New-Object System.Windows.Forms.Button
$btnScan.Text = 'Start Scan'
$btnScan.Location = New-Object System.Drawing.Point(280, 74)
$btnScan.Size = New-Object System.Drawing.Size(120, 30)
$form.Controls.Add($btnScan)

$btnExport = New-Object System.Windows.Forms.Button
$btnExport.Text = 'Export to Excel'
$btnExport.Location = New-Object System.Drawing.Point(280, 114)
$btnExport.Size = New-Object System.Drawing.Size(120, 30)
$btnExport.Enabled = $false
$form.Controls.Add($btnExport)

$lblCredential = New-UiLabel -Text 'Credential: current Windows logon' -X 420 -Y 40 -Width 340
$form.Controls.Add($lblCredential)

$lblStatus = New-UiLabel -Text 'Ready.' -X 420 -Y 80 -Width 720
$form.Controls.Add($lblStatus)

$lblSummary = New-UiLabel -Text 'Detected computers only:' -X 12 -Y 160 -Width 260
$form.Controls.Add($lblSummary)

$grid = New-Object System.Windows.Forms.DataGridView
$grid.Location = New-Object System.Drawing.Point(12, 184)
$grid.Size = New-Object System.Drawing.Size(860, 545)
$grid.ReadOnly = $true
$grid.AllowUserToAddRows = $false
$grid.AllowUserToDeleteRows = $false
$grid.SelectionMode = 'FullRowSelect'
$grid.MultiSelect = $false
$grid.AutoSizeColumnsMode = 'DisplayedCells'
$grid.DataSource = $null
$form.Controls.Add($grid)

$lblDetails = New-UiLabel -Text 'Selected device details:' -X 888 -Y 160 -Width 240
$form.Controls.Add($lblDetails)

$txtDetails = New-Object System.Windows.Forms.TextBox
$txtDetails.Location = New-Object System.Drawing.Point(888, 184)
$txtDetails.Size = New-Object System.Drawing.Size(404, 545)
$txtDetails.Multiline = $true
$txtDetails.ReadOnly = $true
$txtDetails.ScrollBars = 'Vertical'
$txtDetails.Font = New-Object System.Drawing.Font('Consolas', 9)
$form.Controls.Add($txtDetails)

$btnCredential.Add_Click({
    try {
        $script:SelectedCredential = Get-Credential -Message 'Enter authorized credentials for remote inventory, or cancel to keep using your current Windows logon.'
        if ($script:SelectedCredential) {
            $lblCredential.Text = "Credential: $($script:SelectedCredential.UserName)"
        } else {
            $lblCredential.Text = 'Credential: current Windows logon'
        }
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Credential prompt failed: $($_.Exception.Message)", 'Credential Error', 'OK', 'Error') | Out-Null
    }
})

try {
    $script:SelectedCredential = Get-Credential -Message 'Enter authorized admin credentials for remote inventory, or cancel to use your current Windows logon.'
    if ($script:SelectedCredential) {
        $lblCredential.Text = "Credential: $($script:SelectedCredential.UserName)"
    } else {
        $lblCredential.Text = 'Credential: current Windows logon'
    }
} catch {
    $lblCredential.Text = 'Credential: current Windows logon'
}

$grid.Add_SelectionChanged({
    if ($grid.SelectedRows.Count -gt 0) {
        $selected = $grid.SelectedRows[0].DataBoundItem
        if ($selected) {
            $txtDetails.Text = Format-DeviceDetails -Device $selected
        }
    }
})

$btnScan.Add_Click({
    $btnScan.Enabled = $false
    $btnExport.Enabled = $false
    $txtDetails.Clear()
    $script:ScanResults.Clear()

    $discovered = New-Object System.Collections.Generic.List[object]
    $total = $script:ConfiguredIPs.Count
    $current = 0

    foreach ($ip in $script:ConfiguredIPs) {
        $current++
        $lblStatus.Text = "Checking $ip ($current of $total)..."
        [System.Windows.Forms.Application]::DoEvents()

        $reachability = Test-HostReachable -IPAddress $ip
        if (-not $reachability.Found) {
            continue
        }

        try {
            $lblStatus.Text = "Collecting inventory from $ip via $($reachability.DiscoveryMethod)..."
            [System.Windows.Forms.Application]::DoEvents()
            $device = Get-RemoteInventory -IPAddress $ip -Credential $script:SelectedCredential
            $device | Add-Member -NotePropertyName DiscoveryMethod -NotePropertyValue $reachability.DiscoveryMethod -Force
            $discovered.Add($device)
        } catch {
            $partial = [pscustomobject]@{
                ScanDate             = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
                IPAddress            = $ip
                ComputerName         = '(reachable, inventory failed)'
                DNSHostName          = ''
                MACAddress           = ''
                LoggedInUser         = ''
                Domain               = ''
                Manufacturer         = ''
                Model                = ''
                SerialNumber         = ''
                OSCaption            = ''
                OSVersion            = ''
                LastBoot             = ''
                NonStandardAppCount  = 0
                InstalledDriverCount = 0
                ProblemDriverCount   = 0
                Notes                = $_.Exception.Message
                NonStandardSoftware  = @()
                InstalledDrivers     = @()
                ProblemDrivers       = @()
                DiscoveryMethod      = $reachability.DiscoveryMethod
            }
            $discovered.Add($partial)
        }
    }

    foreach ($item in $discovered) {
        $script:ScanResults.Add($item)
    }

    $displayRows = @($script:ScanResults | ForEach-Object {
        [pscustomobject]@{
            ScanDate             = $_.ScanDate
            IPAddress            = $_.IPAddress
            ComputerName         = $_.ComputerName
            MACAddress           = $_.MACAddress
            LoggedInUser         = $_.LoggedInUser
            Domain               = $_.Domain
            OS                   = $_.OSCaption
            DiscoveryMethod      = $_.DiscoveryMethod
            NonStandardAppCount  = $_.NonStandardAppCount
            InstalledDriverCount = $_.InstalledDriverCount
            ProblemDriverCount   = $_.ProblemDriverCount
            Notes                = $_.Notes
            FullResult           = $_
        }
    })

    $bindingRows = foreach ($row in $displayRows) {
        $result = $row.FullResult
        [pscustomobject]@{
            ScanDate             = $row.ScanDate
            IPAddress            = $row.IPAddress
            ComputerName         = $row.ComputerName
            MACAddress           = $row.MACAddress
            LoggedInUser         = $row.LoggedInUser
            Domain               = $row.Domain
            OS                   = $row.OS
            DiscoveryMethod      = $row.DiscoveryMethod
            NonStandardAppCount  = $row.NonStandardAppCount
            InstalledDriverCount = $row.InstalledDriverCount
            ProblemDriverCount   = $row.ProblemDriverCount
            Notes                = $row.Notes
            NonStandardSoftware  = $result.NonStandardSoftware
            InstalledDrivers     = $result.InstalledDrivers
            ProblemDrivers       = $result.ProblemDrivers
            DNSHostName          = $result.DNSHostName
            Manufacturer         = $result.Manufacturer
            Model                = $result.Model
            SerialNumber         = $result.SerialNumber
            OSCaption            = $result.OSCaption
            OSVersion            = $result.OSVersion
            LastBoot             = $result.LastBoot
        }
    }

    $grid.DataSource = $bindingRows
    foreach ($columnName in 'NonStandardSoftware', 'InstalledDrivers', 'ProblemDrivers', 'DNSHostName', 'Manufacturer', 'Model', 'SerialNumber', 'OSCaption', 'OSVersion', 'LastBoot') {
        if ($grid.Columns[$columnName]) {
            $grid.Columns[$columnName].Visible = $false
        }
    }

    if ($bindingRows.Count -gt 0) {
        $grid.Rows[0].Selected = $true
        $txtDetails.Text = Format-DeviceDetails -Device $bindingRows[0]
        $btnExport.Enabled = $true
    } else {
        $txtDetails.Text = 'No configured IP addresses responded to the scan checks.'
    }

    $lblStatus.Text = "Scan complete. Found $($bindingRows.Count) computer(s) out of $total configured IP(s)."
    $btnScan.Enabled = $true
})

$btnExport.Add_Click({
    try {
        $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
        $defaultName = "NetworkInventory_$timestamp.xml"
        $dialog = New-Object System.Windows.Forms.SaveFileDialog
        $dialog.InitialDirectory = $ExportFolder
        $dialog.FileName = $defaultName
        $dialog.Filter = 'Excel XML Workbook (*.xml)|*.xml|Excel Workbook (*.xls)|*.xls'
        $dialog.OverwritePrompt = $true

        if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $exportedPath = Export-InventoryToExcelXml -Devices @($script:ScanResults) -OutputPath $dialog.FileName
            $lblStatus.Text = "Exported scan to $exportedPath"
            [System.Windows.Forms.MessageBox]::Show("Export complete:`r`n$exportedPath", 'Export Complete', 'OK', 'Information') | Out-Null
        }
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Export failed: $($_.Exception.Message)", 'Export Error', 'OK', 'Error') | Out-Null
    }
})

[void]$form.ShowDialog()
