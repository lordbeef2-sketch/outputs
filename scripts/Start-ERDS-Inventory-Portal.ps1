[CmdletBinding()]
param(
    [string]$Urls = 'http://0.0.0.0:5042'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$workspaceRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$projectRoot = Join-Path $workspaceRoot 'work\ERDS.InventoryPortal'
$projectFile = Join-Path $projectRoot 'ERDS.InventoryPortal.csproj'

if (-not (Test-Path -LiteralPath $projectFile)) {
    throw "Project file not found: $projectFile"
}

Push-Location $projectRoot
try {
    dotnet run --project $projectFile --urls $Urls
} finally {
    Pop-Location
}
