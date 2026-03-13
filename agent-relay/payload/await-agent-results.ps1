[CmdletBinding()]
param(
    [string]$ProjectRoot = (Get-Location).Path,
    [int]$PollSeconds = 15,
    [int]$TimeoutMinutes = 90
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$root = (Resolve-Path -LiteralPath $ProjectRoot).Path
$boardPath = Join-Path $root ".codex-agents\board.json"

if (-not (Test-Path -LiteralPath $boardPath)) {
    throw "Could not find board file at $boardPath"
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
            handoff_file = $task.handoff_file
        }
    }

    return [pscustomobject]@{
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

$deadline = (Get-Date).AddMinutes($TimeoutMinutes)

while ($true) {
    powershell -ExecutionPolicy Bypass -File (Join-Path $root "sync-agent-status.ps1") -ProjectRoot $root | Out-Null
    $snapshot = Get-BoardSnapshot -Root $root
    Write-SnapshotSummary -Snapshot $snapshot

    $activeTasks = @($snapshot.tasks | Where-Object { $_.state -in @("planned", "in_progress") })
    if ($activeTasks.Count -eq 0) {
        break
    }

    if ((Get-Date) -ge $deadline) {
        throw "Timed out waiting for workers to finish. Inspect the current status summaries and decide whether to continue specific threads."
    }

    Start-Sleep -Seconds $PollSeconds
}

powershell -ExecutionPolicy Bypass -File (Join-Path $root "build-agent-report.ps1") -ProjectRoot $root | Out-Null
$reportPath = Join-Path $root ".codex-agents\reports\controller-report.md"

$blocked = @($snapshot.tasks | Where-Object { $_.state -eq "blocked" })
$needsReview = @($snapshot.tasks | Where-Object { $_.state -eq "needs_review" })
$done = @($snapshot.tasks | Where-Object { $_.state -eq "done" })

Write-Host ""
Write-Host "All workers reached a controller handoff state." -ForegroundColor Green
Write-Host ("Report: {0}" -f $reportPath) -ForegroundColor Green

if ($blocked.Count -gt 0) {
    Write-Host "Suggested next action: inspect blocked tasks first, then continue only the threads that need missing input." -ForegroundColor Yellow
} elseif ($needsReview.Count -gt 0) {
    Write-Host "Suggested next action: review the report, then continue only the threads that still need follow-up." -ForegroundColor Yellow
} elseif ($done.Count -eq $snapshot.tasks.Count) {
    Write-Host "Suggested next action: summarize the completed worker outputs for the user." -ForegroundColor Yellow
} else {
    Write-Host "Suggested next action: inspect the report and decide whether any worker needs another pass." -ForegroundColor Yellow
}
