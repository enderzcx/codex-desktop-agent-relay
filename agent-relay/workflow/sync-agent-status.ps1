[CmdletBinding()]
param(
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
$boardPath = Join-Path $root ".codex-agents\board.json"

if (-not (Test-Path -LiteralPath $boardPath)) {
    throw "Could not find board file at $boardPath"
}

$board = Get-Content -LiteralPath $boardPath -Raw | ConvertFrom-Json
$updatedTasks = @()

foreach ($task in $board.tasks) {
    $updatedTask = [pscustomobject]@{
        id = $task.id
        role = $task.role
        title = $task.title
        state = $task.state
        workspace = $task.workspace
        task_file = $task.task_file
        status_file = $task.status_file
        handoff_file = $task.handoff_file
    }

    foreach ($optionalProperty in @("branch", "controller_root", "task_file_abs", "status_file_abs", "handoff_file_abs", "board_file_abs")) {
        if ($task.PSObject.Properties.Name -contains $optionalProperty) {
            $updatedTask | Add-Member -NotePropertyName $optionalProperty -NotePropertyValue $task.$optionalProperty -Force
        }
    }

    $statusPath = Join-Path $root $task.status_file
    if (Test-Path -LiteralPath $statusPath) {
        $status = Get-Content -LiteralPath $statusPath -Raw | ConvertFrom-Json
        if ($status.PSObject.Properties.Name -contains "state") {
            $updatedTask.state = $status.state
        }
        if ($status.PSObject.Properties.Name -contains "summary") {
            $updatedTask | Add-Member -NotePropertyName summary -NotePropertyValue $status.summary -Force
        }
        if ($status.PSObject.Properties.Name -contains "updated_at") {
            $updatedTask | Add-Member -NotePropertyName updated_at -NotePropertyValue $status.updated_at -Force
        }
    }

    $updatedTasks += $updatedTask
}

$boardOutput = [ordered]@{
    version = $board.version
    project = [ordered]@{
        name = $board.project.name
        root = $board.project.root
    }
    workflow = [ordered]@{
        mode = $board.workflow.mode
        communication = $board.workflow.communication
        last_updated = (Get-Date).ToString("yyyy-MM-dd")
    }
    main_agent = [ordered]@{
        role = $board.main_agent.role
        responsibilities = @($board.main_agent.responsibilities)
    }
    goal = $board.goal
    tasks = @($updatedTasks)
}

$boardJson = $boardOutput | ConvertTo-Json -Depth 6
Set-FileContentWithRetry -Path $boardPath -Value $boardJson

Write-Host "Synced $($updatedTasks.Count) task(s) into $boardPath" -ForegroundColor Green
foreach ($task in $updatedTasks) {
    Write-Host ("- {0}: {1}" -f $task.id, $task.state)
}
