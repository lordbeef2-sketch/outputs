<#
.SYNOPSIS
Publishes the ERDS Inventory Portal as a self-contained Windows app drop.

.DESCRIPTION
Builds a normal enclave-friendly app folder under a deployment outputs root
so the launcher can run the published EXE without requiring the source project
or a .NET SDK on the target host. By default the deployment root lives in
ProgramData to avoid ransomware-protection hits against Documents.
#>

[CmdletBinding()]
param(
    [string]$RuntimeIdentifier = 'win-x64',
    [string]$Configuration = 'Release',
    [switch]$ForceFrameworkDependent,
    [string]$DeployOutputsRoot = (Join-Path $env:ProgramData 'ERDSInventoryPortal\outputs'),
    [switch]$UseWorkspaceOutputs
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$workspaceRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$outputsRoot = Split-Path -Parent $PSScriptRoot
$projectRoot = Join-Path $workspaceRoot 'work\ERDS.InventoryPortal'
$projectFile = Join-Path $projectRoot 'ERDS.InventoryPortal.csproj'

if ($UseWorkspaceOutputs) {
    $DeployOutputsRoot = $outputsRoot
}

$publishRoot = Join-Path $DeployOutputsRoot 'app\ERDS.InventoryPortal'
$deployScriptsRoot = Join-Path $DeployOutputsRoot 'scripts'
$deployDataRoot = Join-Path $DeployOutputsRoot 'Data'

function Sync-Directory {
    param(
        [Parameter(Mandatory)]
        [string]$Source,
        [Parameter(Mandatory)]
        [string]$Destination
    )

    if (-not (Test-Path -LiteralPath $Source)) {
        return
    }

    New-Item -ItemType Directory -Path $Destination -Force | Out-Null
    Get-ChildItem -LiteralPath $Source -Force | ForEach-Object {
        Copy-Item -LiteralPath $_.FullName -Destination $Destination -Recurse -Force
    }
}

function Seed-Directory {
    param(
        [Parameter(Mandatory)]
        [string]$Source,
        [Parameter(Mandatory)]
        [string]$Destination
    )

    if (-not (Test-Path -LiteralPath $Source)) {
        return
    }

    New-Item -ItemType Directory -Path $Destination -Force | Out-Null
    Get-ChildItem -LiteralPath $Source -Force | ForEach-Object {
        $destinationPath = Join-Path $Destination $_.Name
        if (-not (Test-Path -LiteralPath $destinationPath)) {
            Copy-Item -LiteralPath $_.FullName -Destination $Destination -Recurse -Force
        }
    }
}

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

New-Item -ItemType Directory -Path $DeployOutputsRoot -Force | Out-Null
New-Item -ItemType Directory -Path $publishRoot -Force | Out-Null
Sync-Directory -Source (Join-Path $outputsRoot 'scripts') -Destination $deployScriptsRoot
Seed-Directory -Source (Join-Path $outputsRoot 'Data') -Destination $deployDataRoot

Push-Location $projectRoot
try {
    $publishMode = 'FrameworkDependent'
    $publishErrors = @()
    $stagingRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('ERDS.InventoryPortal.Publish.' + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $stagingRoot -Force | Out-Null

    if (-not $ForceFrameworkDependent) {
        try {
            Invoke-DotnetPublish -Arguments @(
                'publish', $projectFile,
                '-c', $Configuration,
                '-r', $RuntimeIdentifier,
                '--self-contained', 'true',
                '/p:PublishSingleFile=false',
                '/p:IncludeNativeLibrariesForSelfExtract=false',
                '-o', $stagingRoot
            )
            $publishMode = 'SelfContained'
            Sync-Directory -Source $stagingRoot -Destination $publishRoot
        } catch {
            $publishErrors += $_.Exception.Message
        }
    }

    if ($publishMode -ne 'SelfContained') {
        Invoke-DotnetPublish -Arguments @(
            'publish', $projectFile,
            '-c', $Configuration,
            '--self-contained', 'false',
            '/p:UseAppHost=true',
            '-o', $stagingRoot
        )
        Sync-Directory -Source $stagingRoot -Destination $publishRoot
    }
} finally {
    if ($stagingRoot -and (Test-Path -LiteralPath $stagingRoot)) {
        Remove-Item -LiteralPath $stagingRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
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
    DeployOutputsRoot  = $DeployOutputsRoot
    PublishRoot        = $publishRoot
    Executable         = $exePath
    FileCount          = (Get-ChildItem -LiteralPath $publishRoot -File -Recurse | Measure-Object).Count
    Notes              = if ($publishMode -eq 'SelfContained') { 'No separate .NET runtime should be required on the host.' } else { '.NET runtime is still required on the host, but the source project and SDK are not.' }
    SelfContainedError = if ($publishErrors.Count -gt 0) { ($publishErrors -join ' | ') } else { '' }
} | Format-List
