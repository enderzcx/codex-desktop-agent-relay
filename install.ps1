[CmdletBinding()]
param(
    [string]$ProjectRoot = (Get-Location).Path,
    [string]$Repo = "enderzcx/codex-desktop-agent-relay",
    [string]$Ref = "main",
    [string]$BaseUrl = "",
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $ProjectRoot)) {
    $null = New-Item -ItemType Directory -Path $ProjectRoot -Force
}
$targetRoot = (Resolve-Path -LiteralPath $ProjectRoot).Path

$scriptPath = $MyInvocation.MyCommand.Path
$localPayload = $null
if ($scriptPath) {
    $scriptRoot = Split-Path -Parent $scriptPath
    $candidate = Join-Path $scriptRoot "agent-relay\payload"
    if (Test-Path -LiteralPath $candidate) {
        $localPayload = (Resolve-Path -LiteralPath $candidate).Path
    }
}

if (-not $BaseUrl -and -not $localPayload) {
    if (-not $Repo) {
        throw "Could not determine a GitHub repo. Pass -Repo owner/repo or -BaseUrl."
    }
    $BaseUrl = "https://raw.githubusercontent.com/$Repo/$Ref/agent-relay/payload"
}

$files = @(
    "await-agent-results.ps1",
    "build-agent-report.ps1",
    "cleanup-agent-worktrees.ps1",
    "MAIN_AGENT_RUNBOOK.md",
    "MULTI_AGENT_WORKFLOW.md",
    "spawn-agents.ps1",
    "START_HERE.md",
    "sync-agent-status.ps1",
    "update-agent-status.ps1",
    ".codex-agents/README.md",
    ".codex-agents/handoffs/HANDOFF_TEMPLATE.md",
    ".codex-agents/reports/README.md",
    ".codex-agents/status/README.md",
    ".codex-agents/tasks/TASK_TEMPLATE.md"
)

foreach ($relativePath in $files) {
    $destination = Join-Path $targetRoot $relativePath
    $parent = Split-Path -Parent $destination
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        $null = New-Item -ItemType Directory -Path $parent -Force
    }

    if ((Test-Path -LiteralPath $destination) -and -not $Force) {
        Write-Host "Skipped existing file: $destination" -ForegroundColor Yellow
        continue
    }

    if ($localPayload) {
        $source = Join-Path $localPayload $relativePath
        Copy-Item -LiteralPath $source -Destination $destination -Force
    } else {
        $url = ($BaseUrl.TrimEnd('/') + "/" + ($relativePath -replace '\\', '/'))
        Invoke-WebRequest -Uri $url -OutFile $destination
    }
    Write-Host "Installed: $destination" -ForegroundColor Green
}

Write-Host ""
Write-Host "Agent relay workflow installed into $targetRoot" -ForegroundColor Cyan
