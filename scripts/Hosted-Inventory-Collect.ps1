[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$IpAddresses,
    [Parameter(Mandatory)]
    [string]$SnapshotRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::UTF8

$ConnectTimeoutMs = 1200

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

function New-OptionalCredential {
    $userName = $env:ERDS_SCANNER_USERNAME
    $password = $env:ERDS_SCANNER_PASSWORD

    if ([string]::IsNullOrWhiteSpace($userName) -or [string]::IsNullOrWhiteSpace($password)) {
        return $null
    }

    Import-Module Microsoft.PowerShell.Security -ErrorAction Stop | Out-Null
    $securePassword = ConvertTo-SecureString -String $password -AsPlainText -Force
    return [pscredential]::new($userName, $securePassword)
}

function Get-LocalIPv4Addresses {
    $addresses = New-Object System.Collections.Generic.HashSet[string] ([System.StringComparer]::OrdinalIgnoreCase)

    try {
        foreach ($adapter in Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration -Filter 'IPEnabled = TRUE') {
            foreach ($address in @($adapter.IPAddress)) {
                if ($address -match '^\d{1,3}(\.\d{1,3}){3}$') {
                    [void]$addresses.Add($address)
                }
            }
        }
    } catch {
    }

    [void]$addresses.Add('127.0.0.1')
    return @($addresses)
}

function Test-IsLocalTarget {
    param(
        [Parameter(Mandatory)]
        [string]$IPAddress
    )

    return (Get-LocalIPv4Addresses) -contains $IPAddress
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
        [AllowEmptyString()]
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

    Invoke-CimMethod -CimSession $CimSession -Namespace root/cimv2 -ClassName StdRegProv -MethodName $MethodName -Arguments $arguments
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
        [AllowEmptyString()]
        [string]$SubKey
    )

    try {
        $response = Invoke-RegistryMethod -CimSession $CimSession -MethodName EnumKey -Hive $Hive -SubKey $SubKey
        return @($response.sNames)
    } catch {
        return @()
    }
}

function Get-LocalRegistryString {
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        [Parameter(Mandatory)]
        [string]$ValueName
    )

    try {
        $item = Get-ItemProperty -LiteralPath $Path -Name $ValueName -ErrorAction Stop
        return [string]$item.$ValueName
    } catch {
        return $null
    }
}

function Get-LocalRegistryDword {
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        [Parameter(Mandatory)]
        [string]$ValueName
    )

    try {
        $item = Get-ItemProperty -LiteralPath $Path -Name $ValueName -ErrorAction Stop
        return [uint32]$item.$ValueName
    } catch {
        return $null
    }
}

function Get-LocalRegistrySubKeys {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    try {
        return @(Get-ChildItem -LiteralPath $Path -ErrorAction Stop | Select-Object -ExpandProperty PSChildName)
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
                DisplayName     = $displayName
                DisplayVersion  = [string]$displayVersion
                Publisher       = [string]$publisher
                InstallDate     = [string]$installDate
                Scope           = $pathInfo.Scope
                UninstallString = [string]$uninstallString
            })
        }
    }

    return $entries
}

function Get-LocalInstalledSoftware {
    $entries = New-Object System.Collections.Generic.List[object]

    $paths = @(
        [pscustomobject]@{ Path = 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall'; Scope = 'Machine64' },
        [pscustomobject]@{ Path = 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall'; Scope = 'Machine32' }
    )

    foreach ($sid in Get-LocalRegistrySubKeys -Path 'Registry::HKEY_USERS') {
        if ($sid -notmatch '^S-\d-\d+-.+') {
            continue
        }

        $paths += [pscustomobject]@{
            Path  = "Registry::HKEY_USERS\\$sid\\Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall"
            Scope = "User:$sid"
        }
    }

    foreach ($pathInfo in $paths) {
        foreach ($subKey in Get-LocalRegistrySubKeys -Path $pathInfo.Path) {
            $fullKey = '{0}\{1}' -f $pathInfo.Path, $subKey
            $displayName = Get-LocalRegistryString -Path $fullKey -ValueName 'DisplayName'
            if ([string]::IsNullOrWhiteSpace($displayName)) {
                continue
            }

            $systemComponent = Get-LocalRegistryDword -Path $fullKey -ValueName 'SystemComponent'
            if ($systemComponent -eq 1) {
                continue
            }

            $releaseType = Get-LocalRegistryString -Path $fullKey -ValueName 'ReleaseType'
            if ($releaseType -match 'Update|Hotfix|Security') {
                continue
            }

            $publisher = Get-LocalRegistryString -Path $fullKey -ValueName 'Publisher'
            $displayVersion = Get-LocalRegistryString -Path $fullKey -ValueName 'DisplayVersion'
            $installDate = Get-LocalRegistryString -Path $fullKey -ValueName 'InstallDate'
            $uninstallString = Get-LocalRegistryString -Path $fullKey -ValueName 'UninstallString'

            if (Test-IsLikelyStandardSoftware -DisplayName $displayName -Publisher $publisher) {
                continue
            }

            $entries.Add([pscustomobject]@{
                DisplayName     = $displayName
                DisplayVersion  = [string]$displayVersion
                Publisher       = [string]$publisher
                InstallDate     = [string]$installDate
                Scope           = $pathInfo.Scope
                UninstallString = [string]$uninstallString
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

function Get-LocalMacAddress {
    param(
        [Parameter(Mandatory)]
        [string]$IPAddress
    )

    try {
        $adapters = Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration -Filter 'IPEnabled = TRUE'
        foreach ($adapter in $adapters) {
            foreach ($ip in @($adapter.IPAddress)) {
                if ($ip -eq $IPAddress) {
                    return $adapter.MACAddress
                }
            }
        }
    } catch {
    }

    return $null
}

function Get-RemoteInventoryResult {
    param(
        [Parameter(Mandatory)]
        [string]$IPAddress,
        [pscredential]$Credential,
        [Parameter(Mandatory)]
        [string]$DiscoveryMethod,
        [Parameter(Mandatory)]
        [string]$SnapshotRootPath
    )

    $scanDate = Get-Date
    $session = $null
    $notes = New-Object System.Collections.Generic.List[string]
    $software = @()
    $drivers = @()
    $problemDrivers = @()
    $isLocalTarget = Test-IsLocalTarget -IPAddress $IPAddress

    try {
        if ($isLocalTarget) {
            $computerSystem = Get-CimInstance -ClassName Win32_ComputerSystem
            $bios = Get-CimInstance -ClassName Win32_BIOS
            $os = Get-CimInstance -ClassName Win32_OperatingSystem
            $mac = Get-LocalMacAddress -IPAddress $IPAddress

            try {
                $software = @(Get-LocalInstalledSoftware)
            } catch {
                $notes.Add("Software inventory unavailable: $($_.Exception.Message)")
            }

            try {
                $drivers = @(Get-CimInstance -ClassName Win32_PnPSignedDriver |
                    Where-Object { -not [string]::IsNullOrWhiteSpace($_.DeviceName) } |
                    Sort-Object DeviceName |
                    ForEach-Object {
                    [pscustomobject]@{
                        DeviceName         = [string]$_.DeviceName
                        DriverVersion      = [string]$_.DriverVersion
                        DriverProviderName = [string]$_.DriverProviderName
                        Manufacturer       = [string]$_.Manufacturer
                        DriverDate         = Convert-ToDisplayDate -Value $_.DriverDate
                        InfName            = [string]$_.InfName
                        IsSigned           = [bool]$_.IsSigned
                    }
                })
            } catch {
                $notes.Add("Installed drivers unavailable: $($_.Exception.Message)")
            }

            try {
                $problemDrivers = @(Get-CimInstance -ClassName Win32_PnPEntity |
                    Where-Object { $_.ConfigManagerErrorCode -ne 0 -or ($_.Status -and $_.Status -ne 'OK') } |
                    Sort-Object Name |
                ForEach-Object {
                    [pscustomobject]@{
                        DeviceName             = [string]$_.Name
                        PnpDeviceId            = [string]$_.PNPDeviceID
                        PnpClass               = [string]$_.PNPClass
                        Manufacturer           = [string]$_.Manufacturer
                        Service                = [string]$_.Service
                        Status                 = [string]$_.Status
                        ConfigManagerErrorCode = [int]$_.ConfigManagerErrorCode
                        HardwareIds            = @($_.HardwareID | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | ForEach-Object { [string]$_ })
                        CompatibleIds          = @($_.CompatibleID | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | ForEach-Object { [string]$_ })
                    }
                })
            } catch {
                $notes.Add("Problem driver scan unavailable: $($_.Exception.Message)")
            }
        } else {
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
                $drivers = @(Get-CimInstance -CimSession $session -ClassName Win32_PnPSignedDriver |
                    Where-Object { -not [string]::IsNullOrWhiteSpace($_.DeviceName) } |
                    Sort-Object DeviceName |
                    ForEach-Object {
                    [pscustomobject]@{
                        DeviceName         = [string]$_.DeviceName
                        DriverVersion      = [string]$_.DriverVersion
                        DriverProviderName = [string]$_.DriverProviderName
                        Manufacturer       = [string]$_.Manufacturer
                        DriverDate         = Convert-ToDisplayDate -Value $_.DriverDate
                        InfName            = [string]$_.InfName
                        IsSigned           = [bool]$_.IsSigned
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
                            DeviceName             = [string]$_.Name
                            PnpDeviceId            = [string]$_.PNPDeviceID
                            PnpClass               = [string]$_.PNPClass
                            Manufacturer           = [string]$_.Manufacturer
                            Service                = [string]$_.Service
                            Status                 = [string]$_.Status
                            ConfigManagerErrorCode = [int]$_.ConfigManagerErrorCode
                            HardwareIds            = @($_.HardwareID | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | ForEach-Object { [string]$_ })
                            CompatibleIds          = @($_.CompatibleID | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | ForEach-Object { [string]$_ })
                        }
                    })
            } catch {
                $notes.Add("Problem driver scan unavailable: $($_.Exception.Message)")
            }
        }

        $snapshotFolderName = $scanDate.ToString('yyyyMMdd_HHmmss')
        $safeComputerName = if ([string]::IsNullOrWhiteSpace($computerSystem.Name)) { 'unknown' } else { $computerSystem.Name }
        $safeDeviceRoot = ($safeComputerName + '_' + $IPAddress) -replace '[\\/:*?""<>| ]', '_'
        $snapshotFolderPath = Join-Path (Join-Path $SnapshotRootPath $safeDeviceRoot) $snapshotFolderName
        New-Item -ItemType Directory -Path $snapshotFolderPath -Force | Out-Null

        $inventoryResult = [pscustomobject]@{
            ScanDate               = $scanDate.ToString('yyyy-MM-dd HH:mm:ss')
            IpAddress              = $IPAddress
            ComputerName           = [string]$computerSystem.Name
            DnsHostName            = [string]$computerSystem.DNSHostName
            MacAddress             = ([string]$mac).Trim()
            LastLoggedInUser       = [string]$computerSystem.UserName
            WorkgroupName          = if ($computerSystem.PartOfDomain) { '' } else { [string]$computerSystem.Domain }
            DomainName             = if ($computerSystem.PartOfDomain) { [string]$computerSystem.Domain } else { '' }
            Manufacturer           = [string]$computerSystem.Manufacturer
            Model                  = [string]$computerSystem.Model
            SerialNumber           = [string]$bios.SerialNumber
            OperatingSystemCaption = [string]$os.Caption
            OperatingSystemVersion = [string]$os.Version
            LastBootLocal          = Convert-ToDisplayDate -Value $os.LastBootUpTime
            DiscoveryMethod        = $DiscoveryMethod
            Notes                  = ($notes -join ' | ')
            SnapshotFolderName     = $snapshotFolderName
            SnapshotFolderPath     = $snapshotFolderPath
            InstalledSoftware      = @($software)
            InstalledDrivers       = @($drivers)
            ProblemDrivers         = @($problemDrivers)
        }

        $inventoryJsonPath = Join-Path $snapshotFolderPath 'inventory.json'
        $inventoryResult | ConvertTo-Json -Depth 8 | Set-Content -Path $inventoryJsonPath -Encoding utf8

        return $inventoryResult
    } finally {
        if ($session) {
            $session | Remove-CimSession -ErrorAction SilentlyContinue
        }
    }
}

New-Item -ItemType Directory -Path $SnapshotRoot -Force | Out-Null

$results = New-Object System.Collections.Generic.List[object]
$cachedCredential = $null
$credentialLoaded = $false
foreach ($ipAddress in ($IpAddresses -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })) {
    $reachable = Test-HostReachable -IPAddress $ipAddress
    if (-not $reachable.Found) {
        continue
    }

    try {
        $credential = $null
        if (-not (Test-IsLocalTarget -IPAddress $ipAddress)) {
            if (-not $credentialLoaded) {
                $cachedCredential = New-OptionalCredential
                $credentialLoaded = $true
            }

            $credential = $cachedCredential
        }

        $results.Add((Get-RemoteInventoryResult -IPAddress $ipAddress -Credential $credential -DiscoveryMethod $reachable.DiscoveryMethod -SnapshotRootPath $SnapshotRoot))
    } catch {
        $failedResult = [pscustomobject]@{
            ScanDate               = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
            IpAddress              = $ipAddress
            ComputerName           = 'unknown'
            DnsHostName            = ''
            MacAddress             = ''
            LastLoggedInUser       = ''
            WorkgroupName          = ''
            DomainName             = ''
            Manufacturer           = ''
            Model                  = ''
            SerialNumber           = ''
            OperatingSystemCaption = ''
            OperatingSystemVersion = ''
            LastBootLocal          = ''
            DiscoveryMethod        = $reachable.DiscoveryMethod
            Notes                  = $_.Exception.Message
            SnapshotFolderName     = ''
            SnapshotFolderPath     = ''
            InstalledSoftware      = @()
            InstalledDrivers       = @()
            ProblemDrivers         = @()
        }
        $results.Add($failedResult)
    }
}

ConvertTo-Json -InputObject @($results.ToArray()) -Depth 8
