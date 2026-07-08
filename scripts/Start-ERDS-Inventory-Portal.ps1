[CmdletBinding()]
param(
    [string]$Urls = 'http://0.0.0.0:5042',
    [switch]$PreferProject
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$workspaceRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$outputsRoot = Split-Path -Parent $PSScriptRoot
$publishedRoot = Join-Path $outputsRoot 'app\ERDS.InventoryPortal'
$publishedExe = Join-Path $publishedRoot 'ERDS.InventoryPortal.exe'
$projectRoot = Join-Path $workspaceRoot 'work\ERDS.InventoryPortal'
$projectFile = Join-Path $projectRoot 'ERDS.InventoryPortal.csproj'

if (-not $PreferProject -and (Test-Path -LiteralPath $publishedExe)) {
    $previousUrls = $env:ASPNETCORE_URLS
    try {
        $env:ASPNETCORE_URLS = $Urls
        & $publishedExe
        return
    } finally {
        $env:ASPNETCORE_URLS = $previousUrls
    }
}

if (-not (Test-Path -LiteralPath $projectFile)) {
    if (Test-Path -LiteralPath $publishedExe) {
        throw "Published app exists but could not be started: $publishedExe"
    }

    throw "Project file not found: $projectFile`nPublish the app for enclave use first with outputs\\scripts\\Publish-ERDS-Inventory-Portal.ps1."
}

Push-Location $projectRoot
try {
    dotnet run --project $projectFile --urls $Urls
} finally {
    Pop-Location
}
