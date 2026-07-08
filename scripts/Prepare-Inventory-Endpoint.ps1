<#
.SYNOPSIS
Prepares one Windows device for the portable inventory scanner.

.DESCRIPTION
This script is meant to be run locally on a single approved endpoint in an elevated
64-bit Windows PowerShell session. It:
  - Creates or updates one approved local account (defaults to ERDS-Admin)
  - Ensures the account is enabled
  - Adds the account to the local Administrators group
  - Changes active Public network profiles to Private
  - Enables PowerShell remoting / WinRM
  - Optionally restricts WinRM firewall rules to specific scanner IP addresses

It intentionally does not:
  - disable the firewall
  - turn on Basic auth
  - allow unencrypted WinRM
  - modify UAC token-filtering behavior
#>

[CmdletBinding()]
param(
    [string]$UserName = 'ERDS-Admin',
    [securestring]$Password,
    [string[]]$AllowedScannerIPs,
    [string]$Description = 'Approved local admin account for inventory scanning'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Assert-Elevated {
    $currentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentIdentity)
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw 'Run this script from an elevated PowerShell window.'
    }
}

function Assert-64BitPowerShell {
    if (-not [Environment]::Is64BitProcess) {
        throw 'Run this script in 64-bit Windows PowerShell so the LocalAccounts module is available.'
    }
}

function Read-NonEmptyValue {
    param(
        [Parameter(Mandatory)]
        [string]$Prompt
    )

    while ($true) {
        $value = Read-Host -Prompt $Prompt
        if (-not [string]::IsNullOrWhiteSpace($value)) {
            return $value.Trim()
        }
    }
}

function Read-ConfirmedPassword {
    while ($true) {
        $first = Read-Host -Prompt 'Enter the local account password' -AsSecureString
        $second = Read-Host -Prompt 'Re-enter the local account password' -AsSecureString

        $bstrOne = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($first)
        $bstrTwo = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($second)
        try {
            $plainOne = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstrOne)
            $plainTwo = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstrTwo)
        } finally {
            if ($bstrOne -ne [IntPtr]::Zero) { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstrOne) }
            if ($bstrTwo -ne [IntPtr]::Zero) { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstrTwo) }
        }

        if ($plainOne -eq $plainTwo -and -not [string]::IsNullOrWhiteSpace($plainOne)) {
            return $first
        }

        Write-Warning 'Passwords did not match. Try again.'
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

function Ensure-LocalUser {
    param(
        [Parameter(Mandatory)]
        [string]$Name,
        [Parameter(Mandatory)]
        [securestring]$SecurePassword,
        [Parameter(Mandatory)]
        [string]$AccountDescription
    )

    $existing = Get-LocalUser -Name $Name -ErrorAction SilentlyContinue
    if ($existing) {
        Set-LocalUser -Name $Name -Password $SecurePassword -Description $AccountDescription
        if (-not $existing.Enabled) {
            Enable-LocalUser -Name $Name
        }
        return 'Updated'
    }

    New-LocalUser -Name $Name -Password $SecurePassword -Description $AccountDescription | Out-Null
    Enable-LocalUser -Name $Name
    return 'Created'
}

function Ensure-AdministratorsMembership {
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    $members = @(Get-LocalGroupMember -Group 'Administrators' -ErrorAction Stop)
    $alreadyMember = $members | Where-Object {
        $_.Name -eq $Name -or $_.Name -eq "$env:COMPUTERNAME\$Name"
    }

    if (-not $alreadyMember) {
        Add-LocalGroupMember -Group 'Administrators' -Member $Name
        return $true
    }

    return $false
}

function Enable-InventoryRemoting {
    param(
        [string[]]$ScannerIPs
    )

    Enable-PSRemoting -Force -SkipNetworkProfileCheck
    Set-Service -Name WinRM -StartupType Automatic
    if ((Get-Service -Name WinRM).Status -ne 'Running') {
        Start-Service -Name WinRM
    }

    $rules = @(Get-NetFirewallRule -DisplayGroup 'Windows Remote Management' -Direction Inbound -ErrorAction Stop)
    foreach ($rule in $rules) {
        Enable-NetFirewallRule -Name $rule.Name | Out-Null
    }

    if ($ScannerIPs.Count -gt 0) {
        foreach ($rule in $rules) {
            Set-NetFirewallRule -Name $rule.Name -RemoteAddress $ScannerIPs | Out-Null
        }
        return "Restricted WinRM firewall rules to: $($ScannerIPs -join ', ')"
    }

    return 'WinRM firewall rules left at their existing profile scope because no scanner IP list was supplied.'
}

function Set-ActiveNetworkProfilesPrivate {
    $profiles = @(Get-NetConnectionProfile -ErrorAction Stop)
    $updatedProfiles = New-Object System.Collections.Generic.List[string]

    foreach ($profile in $profiles) {
        if ($profile.IPv4Connectivity -eq 'Disconnected' -and $profile.IPv6Connectivity -eq 'Disconnected') {
            continue
        }

        if ($profile.NetworkCategory -eq 'Public') {
            Set-NetConnectionProfile -InterfaceIndex $profile.InterfaceIndex -NetworkCategory Private -ErrorAction Stop
            $updatedProfiles.Add($profile.Name)
        }
    }

    if ($updatedProfiles.Count -eq 0) {
        return 'No active Public network profiles needed changing.'
    }

    return "Changed active network profile(s) to Private: $($updatedProfiles -join ', ')"
}

Assert-Elevated
Assert-64BitPowerShell

if (-not $Password) {
    $Password = Read-ConfirmedPassword
}

if (-not $PSBoundParameters.ContainsKey('AllowedScannerIPs')) {
    $scannerInput = Read-Host -Prompt 'Optional: enter allowed scanner IPv4 addresses separated by comma, or press Enter to skip'
    if (-not [string]::IsNullOrWhiteSpace($scannerInput)) {
        $AllowedScannerIPs = @($scannerInput)
    } else {
        $AllowedScannerIPs = @()
    }
}

$normalizedScannerIPs = Get-NormalizedIPv4List -Values $AllowedScannerIPs
$accountAction = Ensure-LocalUser -Name $UserName -SecurePassword $Password -AccountDescription $Description
$addedToAdmins = Ensure-AdministratorsMembership -Name $UserName
$networkProfileMessage = Set-ActiveNetworkProfilesPrivate
$firewallMessage = Enable-InventoryRemoting -ScannerIPs $normalizedScannerIPs
$wsmanCheck = Test-WSMan -ComputerName localhost

[pscustomobject]@{
    ScanPrepDate          = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    ComputerName          = $env:COMPUTERNAME
    AccountName           = $UserName
    AccountAction         = $accountAction
    AddedToAdministrators = $addedToAdmins
    NetworkProfileAction  = $networkProfileMessage
    WinRMServiceStatus    = (Get-Service -Name WinRM).Status
    WinRMStartupType      = (Get-CimInstance -ClassName Win32_Service -Filter "Name='WinRM'").StartMode
    AllowedScannerIPs     = if ($normalizedScannerIPs.Count -gt 0) { $normalizedScannerIPs -join ', ' } else { '' }
    FirewallScope         = $firewallMessage
    WSManProtocolVersion  = $wsmanCheck.ProductVersion
} | Format-List
