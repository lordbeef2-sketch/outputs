[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$IpAddress,
    [Parameter(Mandatory)]
    [string]$DestinationRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::UTF8

function New-OptionalCredential {
    $userName = $env:ERDS_SCANNER_USERNAME
    $password = $env:ERDS_SCANNER_PASSWORD

    if ([string]::IsNullOrWhiteSpace($userName) -or [string]::IsNullOrWhiteSpace($password)) {
        return $null
    }

    $securePassword = ConvertTo-SecureString -String $password -AsPlainText -Force
    return [pscredential]::new($userName, $securePassword)
}

function New-RemoteDriverStoreFolder {
    param(
        [Parameter(Mandatory)]
        [string]$Root,
        [Parameter(Mandatory)]
        [string]$ComputerName
    )

    $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $safeComputerName = ($ComputerName -replace '[\\/:*?""<>| ]', '_')
    $folder = Join-Path $Root ("{0}_{1}" -f $safeComputerName, $timestamp)
    New-Item -ItemType Directory -Path $folder -Force | Out-Null
    return $folder
}

function Invoke-RemoteDriverExport {
    param(
        [Parameter(Mandatory)]
        [string]$IPAddress,
        [pscredential]$Credential,
        [Parameter(Mandatory)]
        [string]$Root
    )

    $sessionArgs = @{
        ComputerName = $IPAddress
    }
    if ($Credential) {
        $sessionArgs.Credential = $Credential
        $sessionArgs.Authentication = 'Negotiate'
    }

    $session = $null
    try {
        $session = New-PSSession @sessionArgs
        $exportResult = Invoke-Command -Session $session -ScriptBlock {
            $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
            $remoteRoot = Join-Path $env:TEMP ("ERDS_DriverStore_{0}" -f $timestamp)
            $packageFolder = Join-Path $remoteRoot 'Packages'

            New-Item -ItemType Directory -Path $packageFolder -Force | Out-Null

            $inventoryPath = Join-Path $remoteRoot 'DriverInventory.txt'
            $devicesPath = Join-Path $remoteRoot 'InstalledDevices.txt'
            $summaryPath = Join-Path $remoteRoot 'ExportSummary.txt'

            pnputil /enum-drivers | Out-File -FilePath $inventoryPath -Encoding utf8
            pnputil /enum-devices /connected | Out-File -FilePath $devicesPath -Encoding utf8

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

            $zipPath = Join-Path $env:TEMP ("ERDS_DriverStore_{0}_{1}.zip" -f $env:COMPUTERNAME, $timestamp)
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

        $outputFolder = New-RemoteDriverStoreFolder -Root $Root -ComputerName $exportResult.ComputerName
        $localZip = Join-Path $outputFolder ("{0}.zip" -f $exportResult.ComputerName)
        Copy-Item -FromSession $session -Path $exportResult.ZipPath -Destination $localZip -Force
        Expand-Archive -Path $localZip -DestinationPath $outputFolder -Force
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
            IpAddress      = $IPAddress
            ComputerName   = $exportResult.ComputerName
            OutputFolder   = $outputFolder
            ExportMethod   = $exportResult.ExportMethod
            CollectedLocal = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
        }
    } finally {
        if ($session) {
            Remove-PSSession -Session $session -ErrorAction SilentlyContinue
        }
    }
}

New-Item -ItemType Directory -Path $DestinationRoot -Force | Out-Null
$credential = New-OptionalCredential

Invoke-RemoteDriverExport -IPAddress $IpAddress -Credential $credential -Root $DestinationRoot | ConvertTo-Json -Depth 6
