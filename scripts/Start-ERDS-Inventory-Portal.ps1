[CmdletBinding()]
param(
    [string]$Urls = 'http://0.0.0.0:5042',
    [switch]$PreferProject
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$workspaceRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$outputsRoot = Split-Path -Parent $PSScriptRoot
$safeDeployOutputsRoot = Join-Path $env:ProgramData 'ERDSInventoryPortal\outputs'
$publishedRoots = @(
    (Join-Path $safeDeployOutputsRoot 'app\ERDS.InventoryPortal'),
    (Join-Path $outputsRoot 'app\ERDS.InventoryPortal')
) | Select-Object -Unique
$projectRoot = Join-Path $workspaceRoot 'work\ERDS.InventoryPortal'
$projectFile = Join-Path $projectRoot 'ERDS.InventoryPortal.csproj'

if (-not $PreferProject) {
    foreach ($publishedRoot in $publishedRoots) {
        $publishedExe = Join-Path $publishedRoot 'ERDS.InventoryPortal.exe'
        if (-not (Test-Path -LiteralPath $publishedExe)) {
            continue
        }

        $previousUrls = $env:ASPNETCORE_URLS
        Push-Location $publishedRoot
        try {
            $env:ASPNETCORE_URLS = $Urls
            & $publishedExe
            return
        } finally {
            $env:ASPNETCORE_URLS = $previousUrls
            Pop-Location
        }
    }
}

if (-not (Test-Path -LiteralPath $projectFile)) {
    foreach ($publishedRoot in $publishedRoots) {
        $publishedExe = Join-Path $publishedRoot 'ERDS.InventoryPortal.exe'
        if (Test-Path -LiteralPath $publishedExe) {
            throw "Published app exists but could not be started: $publishedExe"
        }
    }

    throw "Project file not found: $projectFile`nPublish the app for enclave use first with outputs\\scripts\\Publish-ERDS-Inventory-Portal.ps1."
}

Push-Location $projectRoot
try {
    dotnet run --project $projectFile --urls $Urls
} finally {
    Pop-Location
}
