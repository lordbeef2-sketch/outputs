<#
.SYNOPSIS
Prepares the scanner workstation for WinRM connections to IP addresses when using local credentials.

.DESCRIPTION
For WinRM connections that use IP addresses and local accounts, Microsoft documents that the target
must be in the scanner's WSMan TrustedHosts list unless HTTPS is configured.

This helper merges only the supplied target IPs into TrustedHosts; it does not use wildcards.
#>

[CmdletBinding()]
param(
    [string[]]$TargetIPs,
    [string]$GuiScriptPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$IpEnvVarName = 'COMPUTER_SCAN_IPS'

function Assert-Elevated {
    $currentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentIdentity)
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw 'Run this script from an elevated PowerShell window.'
    }
}

function Get-NormalizedIPv4List {
    param(
        [AllowNull()]
        [string[]]$Values
    )

    $result = foreach ($value in @($Values)) {
        foreach ($item in ($value -split '[,;`r`n ]+')) {
            $trimmed = $item.Trim()
            if (-not $trimmed) {
                continue
            }

            $parsed = $null
            if ([Net.IPAddress]::TryParse($trimmed, [ref]$parsed) -and $parsed.AddressFamily -eq [Net.Sockets.AddressFamily]::InterNetwork) {
                $trimmed
            } else {
                throw "Invalid IPv4 address: $trimmed"
            }
        }
    }

    return @($result | Sort-Object -Unique)
}

function Get-PresetIPsFromGuiScript {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return @()
    }

    $content = Get-Content -LiteralPath $Path
    $startIndex = -1
    for ($i = 0; $i -lt $content.Count; $i++) {
        if ($content[$i] -match '^\$PresetIPs\s*=\s*@\(') {
            $startIndex = $i + 1
            break
        }
    }

    if ($startIndex -lt 0) {
        return @()
    }

    $items = New-Object System.Collections.Generic.List[string]
    for ($i = $startIndex; $i -lt $content.Count; $i++) {
        $line = $content[$i].Trim()
        if ($line -eq ')') {
            break
        }

        if ($line -match "^'([^']+)'\s*,?$") {
            $items.Add($matches[1])
        }
    }

    return @($items)
}

Assert-Elevated

if (-not $PSBoundParameters.ContainsKey('TargetIPs')) {
    $envValue = [Environment]::GetEnvironmentVariable($IpEnvVarName, 'Process')
    if ([string]::IsNullOrWhiteSpace($envValue)) {
        $envValue = [Environment]::GetEnvironmentVariable($IpEnvVarName, 'User')
    }
    if ([string]::IsNullOrWhiteSpace($envValue)) {
        $envValue = [Environment]::GetEnvironmentVariable($IpEnvVarName, 'Machine')
    }

    if (-not [string]::IsNullOrWhiteSpace($envValue)) {
        $TargetIPs = @($envValue)
    } elseif ($GuiScriptPath) {
        $guiPresetIPs = Get-PresetIPsFromGuiScript -Path $GuiScriptPath
        if ($guiPresetIPs.Count -gt 0) {
            $TargetIPs = $guiPresetIPs
        } else {
            $manual = Read-Host -Prompt "Enter target IPv4 addresses to add to TrustedHosts, or set $IpEnvVarName first"
            $TargetIPs = @($manual)
        }
    } else {
        $manual = Read-Host -Prompt "Enter target IPv4 addresses to add to TrustedHosts, or set $IpEnvVarName first"
        $TargetIPs = @($manual)
    }
}

$normalizedIPs = Get-NormalizedIPv4List -Values $TargetIPs
if ($normalizedIPs.Count -eq 0) {
    throw 'No valid target IP addresses were supplied.'
}

$existingRaw = ''
try {
    $existingRaw = (Get-Item -Path WSMan:\localhost\Client\TrustedHosts -ErrorAction Stop).Value
} catch {
    $existingRaw = ''
}

$existingHosts = @()
if (-not [string]::IsNullOrWhiteSpace($existingRaw)) {
    $existingHosts = $existingRaw -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ }
}

$mergedHosts = @($existingHosts + $normalizedIPs | Sort-Object -Unique)
Set-Item -Path WSMan:\localhost\Client\TrustedHosts -Value ($mergedHosts -join ',') -Force

[pscustomobject]@{
    UpdatedAt         = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    ComputerName      = $env:COMPUTERNAME
    AddedTargets      = $normalizedIPs -join ', '
    PreviousTrustedHosts = $existingRaw
    CurrentTrustedHosts  = (Get-Item -Path WSMan:\localhost\Client\TrustedHosts).Value
} | Format-List
