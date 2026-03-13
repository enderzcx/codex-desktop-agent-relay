[CmdletBinding()]
param(
    [string]$ProjectRoot = (Get-Location).Path,
    [string]$OutputPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$root = (Resolve-Path -LiteralPath $ProjectRoot).Path
$boardPath = Join-Path $root ".codex-agents\board.json"

if (-not (Test-Path -LiteralPath $boardPath)) {
    throw "Could not find board file at $boardPath"
}

$board = Get-Content -LiteralPath $boardPath -Raw | ConvertFrom-Json
if (-not $OutputPath) {
    $OutputPath = Join-Path $root ".codex-agents\reports\controller-report.md"
}

$lines = @(
    "# Controller Report",
    "",
    "- Project: $($board.project.name)",
    "- Root: $($board.project.root)",
    "- Goal: $($board.goal)",
    "- Updated: $((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))",
    "",
    "## Board Summary",
    ""
)

foreach ($task in $board.tasks) {
    $currentState = $task.state
    $currentSummary = if ($task.PSObject.Properties.Name -contains "summary") { $task.summary } else { "" }
    $statusPath = Join-Path $root $task.status_file

    if (Test-Path -LiteralPath $statusPath) {
        $status = Get-Content -LiteralPath $statusPath -Raw | ConvertFrom-Json
        if ($status.PSObject.Properties.Name -contains "state" -and $status.state) {
            $currentState = $status.state
        }
        if ($status.PSObject.Properties.Name -contains "summary" -and $status.summary) {
            $currentSummary = $status.summary
        }
    }

    $summaryText = ""
    if ($currentSummary) {
        $summaryText = " - $currentSummary"
    }
    $lines += "- $($task.id) [$($task.role)] - $currentState$summaryText"
}

foreach ($task in $board.tasks) {
    $handoffPath = Join-Path $root $task.handoff_file
    $statusPath = Join-Path $root $task.status_file
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

    $lines += @(
        "",
        "## $($task.id)",
        "",
        "- Role: $($task.role)",
        "- State: $currentState",
        "- Task file: $($task.task_file)",
        "- Status file: $($task.status_file)",
        "- Handoff file: $($task.handoff_file)"
    )

    if ($currentUpdatedAt) {
        $lines += "- Last status update: $currentUpdatedAt"
    }
    if ($currentSummary) {
        $lines += "- Status summary: $currentSummary"
    }

    if (Test-Path -LiteralPath $handoffPath) {
        $lines += @(
            "",
            "### Handoff",
            ""
        )
        $handoffContent = Get-Content -LiteralPath $handoffPath
        if ($handoffContent.Count -eq 0) {
            $lines += "_No handoff content yet._"
        } else {
            $lines += $handoffContent
        }
    } else {
        $lines += @(
            "",
            "### Handoff",
            "",
            "_Handoff file is missing._"
        )
    }
}

$parent = Split-Path -Parent $OutputPath
if ($parent -and -not (Test-Path -LiteralPath $parent)) {
    $null = New-Item -ItemType Directory -Path $parent -Force
}

Set-Content -LiteralPath $OutputPath -Value ($lines -join [Environment]::NewLine) -Encoding utf8
Write-Host "Wrote controller report to $OutputPath" -ForegroundColor Green
