Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Assert-Elevated {
    $currentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($currentIdentity)
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw 'Run Apply-FullRepo-Drivers.ps1 from an elevated PowerShell window.'
    }
}

Assert-Elevated

$bundleRoot = Split-Path -Parent $PSCommandPath
$driverRoot = Join-Path $bundleRoot 'Drivers'
if (-not (Test-Path -LiteralPath $driverRoot)) {
    throw "Drivers folder not found: $driverRoot"
}

$infFiles = Get-ChildItem -LiteralPath $driverRoot -Filter '*.inf' -File -Recurse
if (-not $infFiles) {
    throw "No INF files were found under $driverRoot"
}

Write-Host "Applying ERDS full repo LatestMatch bundle for MAINBOX (192.168.10.110)..." -ForegroundColor Cyan
$arguments = @('/add-driver', "`"$driverRoot\*.inf`"", '/subdirs', '/install')
$process = Start-Process -FilePath pnputil.exe -ArgumentList $arguments -Wait -PassThru -WindowStyle Hidden
if ($process.ExitCode -ne 0) {
    throw "pnputil failed with exit code $($process.ExitCode)."
}

Write-Host 'Curated repo driver installation pass completed. Reboot if Windows asks for it.' -ForegroundColor Green