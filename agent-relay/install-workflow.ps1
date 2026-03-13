[CmdletBinding()]
param(
    [string]$ProjectRoot = (Get-Location).Path,
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$packageRoot = $scriptRoot
$payloadRoot = Join-Path $packageRoot "workflow"
if (-not (Test-Path -LiteralPath $ProjectRoot)) {
    $null = New-Item -ItemType Directory -Path $ProjectRoot -Force
}
$targetRoot = (Resolve-Path -LiteralPath $ProjectRoot).Path

if (-not (Test-Path -LiteralPath $payloadRoot)) {
    throw "Could not find payload directory at $payloadRoot"
}

function Copy-PayloadFile {
    param(
        [string]$SourcePath,
        [string]$DestinationPath,
        [switch]$Overwrite
    )

    $parent = Split-Path -Parent $DestinationPath
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        $null = New-Item -ItemType Directory -Path $parent -Force
    }

    if ((Test-Path -LiteralPath $DestinationPath) -and -not $Overwrite) {
        Write-Host "Skipped existing file: $DestinationPath" -ForegroundColor Yellow
        return
    }

    Copy-Item -LiteralPath $SourcePath -Destination $DestinationPath -Force
    Write-Host "Installed: $DestinationPath" -ForegroundColor Green
}

$files = @(
    @{ source = "await-agent-results.ps1"; destination = "await-agent-results.ps1" },
    @{ source = "build-agent-report.ps1"; destination = "build-agent-report.ps1" },
    @{ source = "cleanup-agent-worktrees.ps1"; destination = "cleanup-agent-worktrees.ps1" },
    @{ source = "spawn-agents.ps1"; destination = "spawn-agents.ps1" },
    @{ source = "START_HERE.md"; destination = "START_HERE.md" },
    @{ source = "sync-agent-status.ps1"; destination = "sync-agent-status.ps1" },
    @{ source = "update-agent-status.ps1"; destination = "update-agent-status.ps1" },
    @{ source = "watch-agent-results.ps1"; destination = "watch-agent-results.ps1" },
    @{ source = "HANDOFF_TEMPLATE.md"; destination = ".codex-agents/handoffs/HANDOFF_TEMPLATE.md" },
    @{ source = "TASK_TEMPLATE.md"; destination = ".codex-agents/tasks/TASK_TEMPLATE.md" }
)

foreach ($file in $files) {
    $source = Join-Path $payloadRoot $file.source
    $destination = Join-Path $targetRoot $file.destination
    Copy-PayloadFile -SourcePath $source -DestinationPath $destination -Overwrite:$Force
}

Write-Host ""
Write-Host "Agent relay workflow installed into $targetRoot" -ForegroundColor Cyan
