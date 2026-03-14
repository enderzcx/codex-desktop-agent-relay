[CmdletBinding()]
param(
    [string]$ProjectRoot = (Get-Location).Path,
    [string]$Repo = "enderzcx/codex-desktop-agent-relay",
    [string]$Ref = "main",
    [string]$BaseUrl = "",
    [switch]$Force,
    [switch]$WorkflowOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $ProjectRoot)) {
    $null = New-Item -ItemType Directory -Path $ProjectRoot -Force
}
$targetRoot = (Resolve-Path -LiteralPath $ProjectRoot).Path

$scriptPath = $MyInvocation.MyCommand.Path
$localPayload = $null
$localContext = $null
if ($scriptPath) {
    $scriptRoot = Split-Path -Parent $scriptPath
    $candidate = Join-Path $scriptRoot "agent-relay\workflow"
    if (Test-Path -LiteralPath $candidate) {
        $localPayload = (Resolve-Path -LiteralPath $candidate).Path
    }
    $contextCandidate = Join-Path $scriptRoot "context-stack"
    if (Test-Path -LiteralPath $contextCandidate) {
        $localContext = (Resolve-Path -LiteralPath $contextCandidate).Path
    }
}

if (-not $BaseUrl -and -not $localPayload) {
    if (-not $Repo) {
        throw "Could not determine a GitHub repo. Pass -Repo owner/repo or -BaseUrl."
    }
    $BaseUrl = "https://raw.githubusercontent.com/$Repo/$Ref"
}

$workflowBaseUrl = $BaseUrl.TrimEnd('/') + "/agent-relay/workflow"
$contextBaseUrl = $BaseUrl.TrimEnd('/') + "/context-stack"

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
        $url = ($workflowBaseUrl + "/" + ($file.source -replace '\\', '/'))
        Invoke-WebRequest -Uri $url -OutFile $destination
    }
    Write-Host "Installed: $destination" -ForegroundColor Green
}

if (-not $WorkflowOnly) {
    $contextFiles = @(
        @{ source = "AGENTS.md.template"; destination = "AGENTS.md" },
        @{ source = "AGENT.md.template"; destination = "AGENT.md" },
        @{ source = "STATUS.md.template"; destination = "STATUS.md" },
        @{ source = "TASK.template.md"; destination = ".ai-context/TASK.template.md" },
        @{ source = "PR-REVIEW.template.md"; destination = ".ai-context/PR-REVIEW.template.md" }
    )

    foreach ($file in $contextFiles) {
        $destination = Join-Path $targetRoot $file.destination
        $parent = Split-Path -Parent $destination
        if ($parent -and -not (Test-Path -LiteralPath $parent)) {
            $null = New-Item -ItemType Directory -Path $parent -Force
        }

        if ((Test-Path -LiteralPath $destination) -and -not $Force) {
            Write-Host "Skipped existing file: $destination" -ForegroundColor Yellow
            continue
        }

        if ($localContext) {
            $source = Join-Path $localContext $file.source
            Copy-Item -LiteralPath $source -Destination $destination -Force
        } else {
            $url = ($contextBaseUrl + "/" + ($file.source -replace '\\', '/'))
            Invoke-WebRequest -Uri $url -OutFile $destination
        }
        Write-Host "Installed: $destination" -ForegroundColor Green
    }

    $gitignorePath = Join-Path $targetRoot ".gitignore"
    $gitignoreEntries = @("AGENT.md", "STATUS.md", ".ai-context/")
    $existing = @()
    if (Test-Path -LiteralPath $gitignorePath) {
        $existing = Get-Content -LiteralPath $gitignorePath
    }
    $missing = @($gitignoreEntries | Where-Object { $existing -notcontains $_ })
    if ($missing.Count -gt 0) {
        $lines = @($existing)
        if ($lines.Count -gt 0 -and [string]::IsNullOrWhiteSpace($lines[-1]) -eq $false) {
            $lines += ""
        }
        $lines += "# Local AI working files"
        $lines += $missing
        Set-Content -LiteralPath $gitignorePath -Value $lines -Encoding utf8
        Write-Host "Updated: $gitignorePath" -ForegroundColor Green
    } elseif (Test-Path -LiteralPath $gitignorePath) {
        Write-Host "Skipped existing file: $gitignorePath" -ForegroundColor Yellow
    }
}

Write-Host ""
if ($WorkflowOnly) {
    Write-Host "Agent relay workflow installed into $targetRoot" -ForegroundColor Cyan
} else {
    Write-Host "Agent relay stack installed into $targetRoot" -ForegroundColor Cyan
}
