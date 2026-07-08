<#
.SYNOPSIS
Publishes the ERDS Inventory Portal as a self-contained Windows app drop.

.DESCRIPTION
Builds a normal enclave-friendly app folder under outputs\app\ERDS.InventoryPortal
so the launcher can run the published EXE without requiring the source project
or a .NET SDK on the target host.
#>

[CmdletBinding()]
param(
    [string]$RuntimeIdentifier = 'win-x64',
    [string]$Configuration = 'Release',
    [switch]$ForceFrameworkDependent
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$workspaceRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$outputsRoot = Split-Path -Parent $PSScriptRoot
$projectRoot = Join-Path $workspaceRoot 'work\ERDS.InventoryPortal'
$projectFile = Join-Path $projectRoot 'ERDS.InventoryPortal.csproj'
$publishRoot = Join-Path $outputsRoot 'app\ERDS.InventoryPortal'

function Invoke-DotnetPublish {
    param(
        [Parameter(Mandatory)]
        [string[]]$Arguments
    )

    & dotnet @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "dotnet publish failed with exit code $LASTEXITCODE."
    }
}

if (-not (Test-Path -LiteralPath $projectFile)) {
    throw "Project file not found: $projectFile"
}

New-Item -ItemType Directory -Path $publishRoot -Force | Out-Null

Push-Location $projectRoot
try {
    $publishMode = 'FrameworkDependent'
    $publishErrors = @()

    if (-not $ForceFrameworkDependent) {
        try {
            Invoke-DotnetPublish -Arguments @(
                'publish', $projectFile,
                '-c', $Configuration,
                '-r', $RuntimeIdentifier,
                '--self-contained', 'true',
                '/p:PublishSingleFile=false',
                '/p:IncludeNativeLibrariesForSelfExtract=false',
                '-o', $publishRoot
            )
            $publishMode = 'SelfContained'
        } catch {
            $publishErrors += $_.Exception.Message
            if (Test-Path -LiteralPath $publishRoot) {
                Get-ChildItem -LiteralPath $publishRoot -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    if ($publishMode -ne 'SelfContained') {
        Invoke-DotnetPublish -Arguments @(
            'publish', $projectFile,
            '-c', $Configuration,
            '--self-contained', 'false',
            '/p:UseAppHost=true',
            '-o', $publishRoot
        )
    }
} finally {
    Pop-Location
}

$exePath = Join-Path $publishRoot 'ERDS.InventoryPortal.exe'
if (-not (Test-Path -LiteralPath $exePath)) {
    throw "Published EXE not found: $exePath"
}

[pscustomobject]@{
    PublishedAt        = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    RuntimeIdentifier  = $RuntimeIdentifier
    Configuration      = $Configuration
    PublishMode        = $publishMode
    PublishRoot        = $publishRoot
    Executable         = $exePath
    FileCount          = (Get-ChildItem -LiteralPath $publishRoot -File -Recurse | Measure-Object).Count
    Notes              = if ($publishMode -eq 'SelfContained') { 'No separate .NET runtime should be required on the host.' } else { '.NET runtime is still required on the host, but the source project and SDK are not.' }
    SelfContainedError = if ($publishErrors.Count -gt 0) { ($publishErrors -join ' | ') } else { '' }
} | Format-List
