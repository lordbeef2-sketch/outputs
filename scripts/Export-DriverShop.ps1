[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Windows.Forms

function Assert-Elevated {
    $currentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentIdentity)
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw 'Run this script from an elevated PowerShell window.'
    }
}

function Invoke-DriverExport {
    param(
        [Parameter(Mandatory)]
        [string]$DestinationPath
    )

    $exportCmd = Get-Command -Name Export-WindowsDriver -ErrorAction SilentlyContinue
    if ($exportCmd) {
        Export-WindowsDriver -Online -Destination $DestinationPath | Out-Null
        return 'Export-WindowsDriver'
    }

    $arguments = @('/Online', "/Export-Driver", "/Destination:$DestinationPath")
    $process = Start-Process -FilePath dism.exe -ArgumentList $arguments -Wait -PassThru -WindowStyle Hidden
    if ($process.ExitCode -ne 0) {
        throw "DISM export failed with exit code $($process.ExitCode)."
    }

    return 'DISM'
}

Assert-Elevated

$outputRoot = Split-Path -Parent $PSScriptRoot
$driverShopRoot = Join-Path $outputRoot 'Data\DriverShop'
$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$sessionFolder = Join-Path $driverShopRoot ("{0}_{1}" -f $env:COMPUTERNAME, $timestamp)
$packageFolder = Join-Path $sessionFolder 'Packages'

New-Item -ItemType Directory -Path $packageFolder -Force | Out-Null

$inventoryPath = Join-Path $sessionFolder 'DriverInventory.txt'
$devicesPath = Join-Path $sessionFolder 'InstalledDevices.txt'
$summaryPath = Join-Path $sessionFolder 'ExportSummary.txt'

pnputil /enum-drivers | Out-File -FilePath $inventoryPath -Encoding utf8
pnputil /enum-devices /connected | Out-File -FilePath $devicesPath -Encoding utf8
$exportMethod = Invoke-DriverExport -DestinationPath $packageFolder

$summary = @(
    "ComputerName: $env:COMPUTERNAME"
    "ExportedAt: $((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))"
    "Destination: $sessionFolder"
    "PackageFolder: $packageFolder"
    "ExportMethod: $exportMethod"
    'InstallOnTarget: pnputil /add-driver ".\Packages\*.inf" /subdirs /install'
) -join [Environment]::NewLine

[IO.File]::WriteAllText($summaryPath, $summary, [Text.UTF8Encoding]::new($false))

[System.Windows.Forms.MessageBox]::Show(
    "Driver export complete.`r`n`r`nFolder:`r`n$sessionFolder",
    'DriverShop Export Complete',
    [System.Windows.Forms.MessageBoxButtons]::OK,
    [System.Windows.Forms.MessageBoxIcon]::Information
) | Out-Null

Write-Output $sessionFolder
