[CmdletBinding()]
param(
    [string]$ProjectRoot = (Get-Location).Path,
    [int]$PollSeconds = 15,
    [int]$TimeoutMinutes = 90,
    [switch]$SkipReport,
    [string]$TriggerFile = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$root = (Resolve-Path -LiteralPath $ProjectRoot).Path
$boardPath = Join-Path $root ".codex-agents\board.json"

if (-not (Test-Path -LiteralPath $boardPath)) {
    throw "Could not find board file at $boardPath"
}

if (-not $TriggerFile) {
    $TriggerFile = Join-Path $root ".codex-agents\reports\controller-trigger.json"
}

function Get-BoardSnapshot {
    param([string]$Root)

    $board = Get-Content -LiteralPath (Join-Path $Root ".codex-agents\board.json") -Raw | ConvertFrom-Json
    $tasks = @()

    foreach ($task in $board.tasks) {
        $statusPath = Join-Path $Root $task.status_file
        $currentState = $task.state
        $currentSummary = if ($task.PSObject.Properties.Name -contains "summary") { $task.summary } else { "" }
        $currentUpdatedAt = if ($task.PSObject.Properties.Name -contains "updated_at") { $task.updated_at } else { "" }

        if (Test-Path -LiteralPath $statusPath) {
            $status = Get-Content -LiteralPath $statusPath -Raw | ConvertFrom-Json
            if ($status.PSObject.Properties.Name -contains "state" -and $status.state) {
                $currentState = $status.state
            }
            if ($status.PSObject.Properties.Name -contains "summary" -and $status.summary) {
                $currentSummary = $status.summary
            }
            if ($status.PSObject.Properties.Name -contains "updated_at" -and $status.updated_at) {
                $currentUpdatedAt = $status.updated_at
            }
        }

        $tasks += [pscustomobject]@{
            id = $task.id
            role = $task.role
            title = $task.title
            state = $currentState
            summary = $currentSummary
            updated_at = $currentUpdatedAt
            task_file = $task.task_file
            status_file = $task.status_file
            handoff_file = $task.handoff_file
        }
    }

    return [pscustomobject]@{
        project = $board.project
        goal = $board.goal
        tasks = $tasks
    }
}

function Write-SnapshotSummary {
    param([object]$Snapshot)

    Write-Host ""
    Write-Host ("Goal: {0}" -f $Snapshot.goal) -ForegroundColor Cyan
    foreach ($task in $Snapshot.tasks) {
        $line = "- {0} [{1}] -> {2}" -f $task.id, $task.role, $task.state
        if ($task.summary) {
            $line = "{0} | {1}" -f $line, $task.summary
        }
        Write-Host $line
    }
}

function Get-TriggerReason {
    param([object]$Snapshot)

    $blocked = @($Snapshot.tasks | Where-Object { $_.state -eq "blocked" })
    if ($blocked.Count -gt 0) {
        return "blocked"
    }

    $needsReview = @($Snapshot.tasks | Where-Object { $_.state -eq "needs_review" })
    if ($needsReview.Count -gt 0) {
        return "needs_review"
    }

    $active = @($Snapshot.tasks | Where-Object { $_.state -in @("planned", "in_progress") })
    if ($active.Count -eq 0) {
        return "all_terminal"
    }

    return ""
}

function Write-TriggerFile {
    param(
        [string]$Path,
        [string]$Reason,
        [object]$Snapshot,
        [string]$ReportPath
    )

    $parent = Split-Path -Parent $Path
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        $null = New-Item -ItemType Directory -Path $parent -Force
    }

    $payload = [ordered]@{
        reason = $Reason
        project = $Snapshot.project.name
        root = $Snapshot.project.root
        goal = $Snapshot.goal
        triggered_at = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
        report = $ReportPath
        tasks = @(
            foreach ($task in $Snapshot.tasks) {
                [ordered]@{
                    id = $task.id
                    role = $task.role
                    state = $task.state
                    summary = $task.summary
                    updated_at = $task.updated_at
                    handoff_file = $task.handoff_file
                }
            }
        )
    }

    ($payload | ConvertTo-Json -Depth 6) | Set-Content -LiteralPath $Path -Encoding utf8
}

$deadline = (Get-Date).AddMinutes($TimeoutMinutes)
$syncScript = Join-Path $root "sync-agent-status.ps1"
$reportScript = Join-Path $root "build-agent-report.ps1"
$reportPath = Join-Path $root ".codex-agents\reports\controller-report.md"

while ($true) {
    powershell -ExecutionPolicy Bypass -File $syncScript -ProjectRoot $root | Out-Null
    $snapshot = Get-BoardSnapshot -Root $root
    Write-SnapshotSummary -Snapshot $snapshot

    $reason = Get-TriggerReason -Snapshot $snapshot
    if ($reason) {
        if (-not $SkipReport) {
            powershell -ExecutionPolicy Bypass -File $reportScript -ProjectRoot $root | Out-Null
        }

        Write-TriggerFile -Path $TriggerFile -Reason $reason -Snapshot $snapshot -ReportPath $reportPath

        Write-Host ""
        Write-Host ("Controller trigger fired: {0}" -f $reason) -ForegroundColor Green
        Write-Host ("Trigger file: {0}" -f $TriggerFile) -ForegroundColor Green
        if (-not $SkipReport) {
            Write-Host ("Report: {0}" -f $reportPath) -ForegroundColor Green
        }

        switch ($reason) {
            "blocked" {
                Write-Host "Suggested next action: inspect blocked worker handoffs, add missing context, then continue only the affected threads." -ForegroundColor Yellow
            }
            "needs_review" {
                Write-Host "Suggested next action: read the report, review the flagged worker output, then continue only the threads that still need follow-up." -ForegroundColor Yellow
            }
            "all_terminal" {
                Write-Host "Suggested next action: summarize the finished worker outputs or relaunch only the threads that need another pass." -ForegroundColor Yellow
            }
        }

        exit 0
    }

    if ((Get-Date) -ge $deadline) {
        throw "Timed out waiting for a controller trigger. Workers are still active and no blocked or needs_review state was observed."
    }

    Start-Sleep -Seconds $PollSeconds
}
