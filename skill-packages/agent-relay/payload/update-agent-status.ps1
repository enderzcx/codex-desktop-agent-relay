[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$TaskId,
    [Parameter(Mandatory = $true)]
    [ValidateSet("planned", "in_progress", "needs_review", "blocked", "done")]
    [string]$State,
    [string]$Summary = "",
    [string]$ProjectRoot = (Get-Location).Path
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Set-FileContentWithRetry {
    param(
        [string]$Path,
        [string]$Value,
        [int]$MaxAttempts = 5,
        [int]$DelayMilliseconds = 250
    )

    for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
        try {
            Set-Content -LiteralPath $Path -Value $Value -Encoding utf8
            return
        } catch {
            if ($attempt -eq $MaxAttempts) {
                throw
            }
            Start-Sleep -Milliseconds $DelayMilliseconds
        }
    }
}

$root = (Resolve-Path -LiteralPath $ProjectRoot).Path
$statusPath = Join-Path $root ".codex-agents\status\$TaskId.json"

if (-not (Test-Path -LiteralPath $statusPath)) {
    throw "Could not find status file at $statusPath"
}

$status = Get-Content -LiteralPath $statusPath -Raw | ConvertFrom-Json
$updated = [ordered]@{
    task_id = $status.task_id
    role = $status.role
    state = $State
    summary = if ([string]::IsNullOrWhiteSpace($Summary)) { $status.summary } else { $Summary }
    workspace = $status.workspace
    updated_at = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
}

$updatedJson = $updated | ConvertTo-Json -Depth 5
Set-FileContentWithRetry -Path $statusPath -Value $updatedJson

Write-Host "Updated $TaskId to $State" -ForegroundColor Green
if ($updated.summary) {
    Write-Host $updated.summary
}
