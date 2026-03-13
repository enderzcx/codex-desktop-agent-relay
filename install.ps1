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
    $candidate = Join-Path $scriptRoot "agent-relay\workflow"
    if (Test-Path -LiteralPath $candidate) {
        $localPayload = (Resolve-Path -LiteralPath $candidate).Path
    }
}

if (-not $BaseUrl -and -not $localPayload) {
    if (-not $Repo) {
        throw "Could not determine a GitHub repo. Pass -Repo owner/repo or -BaseUrl."
    }
    $BaseUrl = "https://raw.githubusercontent.com/$Repo/$Ref/agent-relay/workflow"
}

$files = @(
    @{ source = "await-agent-results.ps1"; destination = "await-agent-results.ps1" },
    @{ source = "build-agent-report.ps1"; destination = "build-agent-report.ps1" },
    @{ source = "cleanup-agent-worktrees.ps1"; destination = "cleanup-agent-worktrees.ps1" },
    @{ source = "spawn-agents.ps1"; destination = "spawn-agents.ps1" },
    @{ source = "start-agent-relay.ps1"; destination = "start-agent-relay.ps1" },
    @{ source = "START_HERE.md"; destination = "START_HERE.md" },
    @{ source = "sync-agent-status.ps1"; destination = "sync-agent-status.ps1" },
    @{ source = "update-agent-status.ps1"; destination = "update-agent-status.ps1" },
    @{ source = "watch-agent-results.ps1"; destination = "watch-agent-results.ps1" },
    @{ source = "HANDOFF_TEMPLATE.md"; destination = ".codex-agents/handoffs/HANDOFF_TEMPLATE.md" },
    @{ source = "TASK_TEMPLATE.md"; destination = ".codex-agents/tasks/TASK_TEMPLATE.md" }
)

foreach ($file in $files) {
    $destination = Join-Path $targetRoot $file.destination
    $parent = Split-Path -Parent $destination
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        $null = New-Item -ItemType Directory -Path $parent -Force
    }

    if ((Test-Path -LiteralPath $destination) -and -not $Force) {
        Write-Host "Skipped existing file: $destination" -ForegroundColor Yellow
        continue
    }

    if ($localPayload) {
        $source = Join-Path $localPayload $file.source
        Copy-Item -LiteralPath $source -Destination $destination -Force
    } else {
        $url = ($BaseUrl.TrimEnd('/') + "/" + ($file.source -replace '\\', '/'))
        Invoke-WebRequest -Uri $url -OutFile $destination
    }
    Write-Host "Installed: $destination" -ForegroundColor Green
}

Write-Host ""
Write-Host "Agent relay workflow installed into $targetRoot" -ForegroundColor Cyan
