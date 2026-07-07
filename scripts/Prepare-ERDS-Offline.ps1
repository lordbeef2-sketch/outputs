<#
.SYNOPSIS
Single offline prep entrypoint for ERDS scanner and endpoint setup.

.DESCRIPTION
Wraps the existing ERDS prep scripts into one PowerShell-only launcher so an
offline enclave operator can prep:
  - the scanner workstation
  - one target endpoint
  - or both on the same machine

No packages are downloaded. This script just orchestrates the existing local
prep helpers already shipped with the ERDS output set.
#>

[CmdletBinding()]
param(
    [ValidateSet('Scanner', 'Endpoint', 'Both')]
    [string]$Role,
    [string]$UserName = 'ERDS-Admin',
    [securestring]$Password,
    [string[]]$AllowedScannerIPs,
    [string[]]$TargetIPs,
    [string]$GuiScriptPath = (Join-Path $PSScriptRoot 'Portable-Network-Inventory-GUI.ps1')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scannerScriptPath = Join-Path $PSScriptRoot 'Prepare-Inventory-Scanner.ps1'
$endpointScriptPath = Join-Path $PSScriptRoot 'Prepare-Inventory-Endpoint.ps1'

function Assert-DependencyScript {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Required helper script not found: $Path"
    }
}

function Read-PrepRole {
    while ($true) {
        Write-Host ''
        Write-Host 'ERDS Offline Prep' -ForegroundColor Cyan
        Write-Host '1. Scanner workstation only'
        Write-Host '2. Endpoint device only'
        Write-Host '3. Both on this machine'

        $choice = Read-Host -Prompt 'Pick 1, 2, or 3'
        switch ($choice.Trim()) {
            '1' { return 'Scanner' }
            '2' { return 'Endpoint' }
            '3' { return 'Both' }
            default { Write-Warning 'Enter 1, 2, or 3.' }
        }
    }
}

function Invoke-ScannerPrep {
    Assert-DependencyScript -Path $scannerScriptPath

    $params = @{
        GuiScriptPath = $GuiScriptPath
    }

    if ($PSBoundParameters.ContainsKey('TargetIPs') -and $TargetIPs.Count -gt 0) {
        $params.TargetIPs = $TargetIPs
    }

    & $scannerScriptPath @params
}

function Invoke-EndpointPrep {
    Assert-DependencyScript -Path $endpointScriptPath

    $params = @{
        UserName = $UserName
    }

    if ($PSBoundParameters.ContainsKey('Password')) {
        $params.Password = $Password
    }

    if ($PSBoundParameters.ContainsKey('AllowedScannerIPs') -and $AllowedScannerIPs.Count -gt 0) {
        $params.AllowedScannerIPs = $AllowedScannerIPs
    }

    & $endpointScriptPath @params
}

if (-not $PSBoundParameters.ContainsKey('Role') -or [string]::IsNullOrWhiteSpace($Role)) {
    $Role = Read-PrepRole
}

Write-Host ''
Write-Host "Running ERDS offline prep for role: $Role" -ForegroundColor Cyan

switch ($Role) {
    'Scanner' {
        Invoke-ScannerPrep
    }
    'Endpoint' {
        Invoke-EndpointPrep
    }
    'Both' {
        Invoke-EndpointPrep
        Write-Host ''
        Write-Host 'Endpoint prep complete. Starting scanner prep...' -ForegroundColor DarkCyan
        Invoke-ScannerPrep
    }
    default {
        throw "Unsupported role: $Role"
    }
}
