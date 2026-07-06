<#
.SYNOPSIS
Sample Teamwork Cloud inventory collector scaffold.

.DESCRIPTION
This is a teaching scaffold showing how to think about repository inventory collection.
It does not hard-code real endpoints or credentials.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$BaseUrl,
    [string]$Token,
    [string]$OutputPath = ".\twc_inventory_sample_output.json"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Invoke-TwcGet {
    param(
        [Parameter(Mandatory)]
        [string]$Uri,
        [string]$BearerToken
    )

    $headers = @{}
    if ($BearerToken) {
        $headers.Authorization = "Bearer $BearerToken"
    }

    Invoke-RestMethod -Method Get -Uri $Uri -Headers $headers
}

$result = [ordered]@{
    snapshot_date = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    environment   = $BaseUrl
    projects      = @()
    notes         = @(
        'Teaching scaffold only',
        'Replace endpoint paths with the correct TWC REST inventory endpoints for your environment'
    )
}

# Example pseudo-endpoint pattern:
# $projectsResponse = Invoke-TwcGet -Uri "$BaseUrl/api/projects" -BearerToken $Token
# foreach ($project in $projectsResponse.items) {
#     $result.projects += [ordered]@{
#         project_id      = $project.id
#         project_name    = $project.name
#         branch_count    = $project.branchCount
#         resource_count  = $project.resourceCount
#         last_activity   = $project.lastModified
#         owner_or_group  = $project.owner
#         notes           = ''
#     }
# }

$json = $result | ConvertTo-Json -Depth 8
$resolvedOutput = [IO.Path]::GetFullPath($OutputPath)
[IO.File]::WriteAllText($resolvedOutput, $json)
Write-Output "Wrote sample inventory scaffold output to $OutputPath"
