[CmdletBinding()]
param(
    [string]$ProjectRoot = (Get-Location).Path,
    [string]$Goal = "Replace this with the real task goal.",
    [string]$ContextNote = "Add the real files, flows, and constraints before launching workers.",
    [string[]]$Roles = @("implementer", "tester", "reviewer"),
    [switch]$OpenWindows,
    [switch]$NoOpenWindows,
    [switch]$UseWorktrees,
    [string]$CodexCommand = "codex"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
if (Get-Variable PSNativeCommandUseErrorActionPreference -ErrorAction SilentlyContinue) {
    $PSNativeCommandUseErrorActionPreference = $false
}

$shouldOpenWindows = $true
if ($PSBoundParameters.ContainsKey("NoOpenWindows")) {
    $shouldOpenWindows = $false
} elseif ($PSBoundParameters.ContainsKey("OpenWindows")) {
    $shouldOpenWindows = [bool]$OpenWindows
}

function Get-RoleProfile {
    param([string]$Role)

    switch ($Role) {
        "implementer" {
            return [pscustomobject]@{
                Title = "Implement the main slice"
                ResultLine = "Implementation status: replace with the current result."
                Guidance = @(
                    "- Focus on the narrow implementation slice assigned by the main agent.",
                    "- Prefer minimal code changes and clear validation."
                )
                DoneWhen = @(
                    "- The requested slice is implemented or clearly blocked.",
                    "- The handoff names changed files and the smallest validation run."
                )
            }
        }
        "tester" {
            return [pscustomobject]@{
                Title = "Check validation and edge cases"
                ResultLine = "Validation status: replace with the current result."
                Guidance = @(
                    "- Focus on edge cases, regression checks, and the smallest useful validation.",
                    "- Flag missing coverage before proposing broad test rewrites."
                )
                DoneWhen = @(
                    "- The handoff lists edge cases, checks run, and any uncovered risk.",
                    "- The worker states whether the main path appears safe."
                )
            }
        }
        "reviewer" {
            return [pscustomobject]@{
                Title = "Review for bugs and regressions"
                ResultLine = "Review status: replace with the current result."
                Guidance = @(
                    "- Review for bugs, regressions, and risky assumptions.",
                    "- Return findings first with file references when possible."
                )
                DoneWhen = @(
                    "- The handoff lists findings first or explicitly says no findings.",
                    "- File references are included for each concrete issue."
                )
            }
        }
        "ceo" {
            return [pscustomobject]@{
                Title = "Challenge the direction"
                ResultLine = "Strategic review status: replace with the current result."
                Guidance = @(
                    "- Focus on the real business or product outcome, not implementation details first.",
                    "- Pressure-test whether the problem is worth solving now and what should be deprioritized."
                )
                DoneWhen = @(
                    "- The handoff states the top strategic recommendation and the biggest unresolved question.",
                    "- The handoff names what should not be done yet."
                )
            }
        }
        "product-manager" {
            return [pscustomobject]@{
                Title = "Clarify the product shape"
                ResultLine = "Product framing status: replace with the current result."
                Guidance = @(
                    "- Focus on user problem, target flow, constraints, non-goals, and success criteria.",
                    "- Turn broad requests into a sharper product brief with explicit tradeoffs."
                )
                DoneWhen = @(
                    "- The handoff defines the user, the core job to be done, and the smallest coherent scope.",
                    "- The handoff highlights ambiguity that the main agent must resolve."
                )
            }
        }
        "risk-reviewer" {
            return [pscustomobject]@{
                Title = "Stress-test assumptions"
                ResultLine = "Risk review status: replace with the current result."
                Guidance = @(
                    "- Focus on hidden assumptions, adoption risk, operational risk, and incentive misalignment.",
                    "- Return findings first and separate verified risks from speculation."
                )
                DoneWhen = @(
                    "- The handoff lists the most dangerous assumption first.",
                    "- The handoff includes mitigation ideas for the top risks."
                )
            }
        }
        "architect" {
            return [pscustomobject]@{
                Title = "Shape the architecture"
                ResultLine = "Architecture status: replace with the current result."
                Guidance = @(
                    "- Focus on system boundaries, interface choices, failure isolation, and scalability tradeoffs.",
                    "- Prefer a small number of concrete architecture options over broad brainstorming."
                )
                DoneWhen = @(
                    "- The handoff recommends an architecture direction and explains why.",
                    "- The handoff names the key boundary or dependency that could break the design."
                )
            }
        }
        "staff-engineer" {
            return [pscustomobject]@{
                Title = "Find the implementation path"
                ResultLine = "Implementation path status: replace with the current result."
                Guidance = @(
                    "- Focus on pragmatic implementation sequence, migration risk, and technical tradeoffs.",
                    "- Name the smallest path to a working first version."
                )
                DoneWhen = @(
                    "- The handoff lays out a realistic implementation order.",
                    "- The handoff highlights the hardest technical step and how to de-risk it."
                )
            }
        }
        "incident-commander" {
            return [pscustomobject]@{
                Title = "Stabilize the incident"
                ResultLine = "Incident status: replace with the current result."
                Guidance = @(
                    "- Focus on blast radius, user impact, stop-the-bleeding actions, and decision points.",
                    "- Prefer clear triage and containment steps over deep theory."
                )
                DoneWhen = @(
                    "- The handoff states current impact, immediate containment, and next operational decision.",
                    "- The handoff distinguishes active incident actions from later cleanup."
                )
            }
        }
        "staff-debugger" {
            return [pscustomobject]@{
                Title = "Hunt the root cause"
                ResultLine = "Debugging status: replace with the current result."
                Guidance = @(
                    "- Focus on root cause, evidence, minimal repro, and the fastest path to confidence.",
                    "- Prefer concrete hypotheses and elimination steps."
                )
                DoneWhen = @(
                    "- The handoff states the most likely root cause and the evidence behind it.",
                    "- The handoff names the next highest-signal check if the cause is still uncertain."
                )
            }
        }
        "qa-hunter" {
            return [pscustomobject]@{
                Title = "Hunt user-visible failures"
                ResultLine = "QA hunt status: replace with the current result."
                Guidance = @(
                    "- Focus on user-visible bugs, weak flows, and obvious regressions before edge-case theory.",
                    "- Prioritize issues by severity and ease of reproduction."
                )
                DoneWhen = @(
                    "- The handoff lists the best bug candidates with repro notes.",
                    "- The handoff separates likely bugs from lower-confidence suspicions."
                )
            }
        }
        "repro-engineer" {
            return [pscustomobject]@{
                Title = "Turn failures into repro steps"
                ResultLine = "Repro status: replace with the current result."
                Guidance = @(
                    "- Focus on deterministic reproduction, logs, screenshots, and narrowing conditions.",
                    "- Convert vague symptoms into crisp repro recipes."
                )
                DoneWhen = @(
                    "- The handoff includes the clearest repro steps found.",
                    "- The handoff notes what evidence is still missing."
                )
            }
        }
        "triage-reviewer" {
            return [pscustomobject]@{
                Title = "Rank and frame the bugs"
                ResultLine = "Triage status: replace with the current result."
                Guidance = @(
                    "- Focus on severity, likely user impact, release risk, and what should be fixed first.",
                    "- Return findings first and keep them actionable."
                )
                DoneWhen = @(
                    "- The handoff ranks the top issues by priority.",
                    "- The handoff states which issue should block release, if any."
                )
            }
        }
        default {
            return [pscustomobject]@{
                Title = "Complete assigned work"
                ResultLine = "Replace with the current result."
                Guidance = @("- Stay within the assigned scope and return a concise handoff.")
                DoneWhen = @("- The handoff is complete and actionable for the main agent.")
            }
        }
    }
}

function New-AgentTaskContent {
    param(
        [string]$TaskId,
        [string]$Role,
        [string]$Workspace,
        [string]$ControllerRoot,
        [string]$TaskFile,
        [string]$StatusFile,
        [string]$HandoffFile,
        [string]$BoardFile,
        [string]$BranchName,
        [string]$GoalText,
        [string]$ContextText
    )

    $profile = Get-RoleProfile -Role $Role

    $constraints = @(
        "- Read relevant files before changing anything.",
        "- Stay within the assigned role.",
        "- Write updates to the matching status and handoff files.",
        "- Ask for cross-worker information through the main agent, not directly to another worker."
    ) + $profile.Guidance

    $lines = @(
        "# Worker Task",
        "",
        "- Task id: $TaskId",
        "- Role: $Role",
        "- Worker workspace: $Workspace",
        "- Controller root: $ControllerRoot",
        "- Branch: $BranchName",
        "- Task file: $TaskFile",
        "- Status file: $StatusFile",
        "- Handoff file: $HandoffFile",
        "",
        "## Goal",
        "",
        "- $GoalText",
        "",
        "## Context",
        "",
        "- Worker workspace: $Workspace",
        "- Controller root: $ControllerRoot",
        "- Shared board: $BoardFile",
        "- Controller note: $ContextText",
        "",
        "## Constraints",
        ""
    )

    foreach ($item in $constraints) {
        $lines += $item
    }

    $lines += @(
        "",
        "## Done when",
        ""
    )

    foreach ($item in $profile.DoneWhen) {
        $lines += $item
    }

    return ($lines -join [Environment]::NewLine) + [Environment]::NewLine
}

function New-HandoffContent {
    param([string]$Role)

    $profile = Get-RoleProfile -Role $Role
    $resultLine = $profile.ResultLine

    return @"
# Result

$resultLine

# What Changed

- Replace with files read or changed

# Evidence

- Replace with checks, commands, logs, or code references

# Risks

- Replace with remaining risks or say none

# Needs From Main Agent

- Replace with follow-up needs or say none
"@
}

function Get-TaskDefinitions {
    param([string[]]$RequestedRoles)

    $definitions = @()
    $index = 1
    foreach ($role in $RequestedRoles) {
        $taskId = "task-{0:D3}-{1}" -f $index, $role
        $title = (Get-RoleProfile -Role $role).Title

        $definitions += [pscustomobject]@{
            TaskId = $taskId
            Role = $role
            Title = $title
        }
        $index++
    }
    return $definitions
}

function Ensure-Directory {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        $null = New-Item -ItemType Directory -Path $Path -Force
    }
}

function Test-GitRepository {
    param([string]$Path)

    try {
        $null = git -C $Path rev-parse --show-toplevel 2>$null
        return ($LASTEXITCODE -eq 0)
    } catch {
        return $false
    }
}

function Test-GitHeadCommit {
    param([string]$Path)

    try {
        $null = git -C $Path rev-parse --verify HEAD 2>$null
        return ($LASTEXITCODE -eq 0)
    } catch {
        return $false
    }
}

function Invoke-GitCommand {
    param(
        [string]$RepoRoot,
        [string[]]$Arguments
    )

    $quotedArgs = @("-C", $RepoRoot) + $Arguments | ForEach-Object {
        if ($_ -match '[\s"]') {
            '"' + ($_ -replace '"', '\"') + '"'
        } else {
            $_
        }
    }
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "git"
    $psi.Arguments = ($quotedArgs -join " ")
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true

    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $psi
    $null = $process.Start()
    $stdout = $process.StandardOutput.ReadToEnd()
    $stderr = $process.StandardError.ReadToEnd()
    $process.WaitForExit()

    return [pscustomobject]@{
        ExitCode = $process.ExitCode
        StdOut = $stdout.Trim()
        StdErr = $stderr.Trim()
    }
}

function New-WorkerWorktree {
    param(
        [string]$RepoRoot,
        [string]$TaskId
    )

    $worktreeRoot = Join-Path $RepoRoot ".worktrees"
    Ensure-Directory -Path $worktreeRoot
    $worktreePath = Join-Path $worktreeRoot $TaskId
    $branchName = "enderzcx/OnchainClaw/$TaskId"

    if (Test-Path -LiteralPath $worktreePath) {
        return [pscustomobject]@{
            Path = $worktreePath
            Branch = $branchName
        }
    }

    $result = Invoke-GitCommand -RepoRoot $RepoRoot -Arguments @("worktree", "add", $worktreePath, "-b", $branchName, "HEAD")
    if ($result.ExitCode -ne 0) {
        $message = $result.StdErr
        if (-not $message) {
            $message = $result.StdOut
        }
        if (-not $message) {
            $message = "git worktree add failed"
        }
        throw "Failed to create worktree for ${TaskId}: $message"
    }
    return [pscustomobject]@{
        Path = $worktreePath
        Branch = $branchName
    }
}

function Open-AgentWindow {
    param(
        [string]$Workspace,
        [string]$TaskId,
        [string]$Role,
        [string]$TaskFile,
        [string]$StatusFile,
        [string]$HandoffFile,
        [string]$BranchName,
        [string]$CodexCli
    )

    $terminalShell = Get-Command pwsh -ErrorAction SilentlyContinue
    if (-not $terminalShell) {
        $terminalShell = Get-Command powershell -ErrorAction SilentlyContinue
    }
    if (-not $terminalShell) {
        throw "Could not find pwsh.exe or powershell.exe to open worker windows."
    }

    $launcherPath = Join-Path ([System.IO.Path]::GetTempPath()) ("codex-worker-{0}.ps1" -f ([System.Guid]::NewGuid().ToString("N")))
    $initialPrompt = "Read $TaskFile, follow the scope exactly, update the matching status file as you work, and write your result to the matching handoff file."
    $launcherScript = @"
Set-Location -LiteralPath '$Workspace'
Write-Host 'Worker: $TaskId ($Role)' -ForegroundColor Cyan
Write-Host 'Branch: $BranchName' -ForegroundColor Cyan
Write-Host 'Task file: $TaskFile' -ForegroundColor Yellow
Write-Host 'Status file: $StatusFile' -ForegroundColor Yellow
Write-Host 'Handoff file: $HandoffFile' -ForegroundColor Yellow
Write-Host 'Launching Codex with the worker prompt...' -ForegroundColor Green
& '$CodexCli' '$initialPrompt'
"@
    Set-Content -LiteralPath $launcherPath -Value $launcherScript -Encoding utf8

    $wt = Get-Command wt -ErrorAction SilentlyContinue
    if ($wt) {
        & $wt.Source new-tab --title $TaskId $terminalShell.Source -ExecutionPolicy Bypass -NoExit -File $launcherPath | Out-Null
        return
    }

    Start-Process -FilePath $terminalShell.Source -ArgumentList @("-ExecutionPolicy", "Bypass", "-NoExit", "-File", $launcherPath) -WorkingDirectory $Workspace | Out-Null
}

$root = (Resolve-Path -LiteralPath $ProjectRoot).Path
$agentsRoot = Join-Path $root ".codex-agents"
$tasksRoot = Join-Path $agentsRoot "tasks"
$statusRoot = Join-Path $agentsRoot "status"
$handoffsRoot = Join-Path $agentsRoot "handoffs"
$reportsRoot = Join-Path $agentsRoot "reports"
$boardPath = Join-Path $agentsRoot "board.json"
$worktreeMapPath = Join-Path $agentsRoot "worktrees.json"

Ensure-Directory -Path $agentsRoot
Ensure-Directory -Path $tasksRoot
Ensure-Directory -Path $statusRoot
Ensure-Directory -Path $handoffsRoot
Ensure-Directory -Path $reportsRoot

$taskDefinitions = Get-TaskDefinitions -RequestedRoles $Roles
$board = if (Test-Path -LiteralPath $boardPath) {
    Get-Content -LiteralPath $boardPath -Raw | ConvertFrom-Json
} else {
    [pscustomobject]@{
        version = 1
        project = [pscustomobject]@{
            name = (Split-Path -Leaf $root)
            root = $root
        }
        workflow = [pscustomobject]@{
            mode = "stable-relay"
            communication = "main-agent-relay"
            last_updated = (Get-Date).ToString("yyyy-MM-dd")
        }
        main_agent = [pscustomobject]@{
            role = "controller"
            responsibilities = @(
                "decompose work",
                "route follow-up instructions",
                "merge worker outputs",
                "resolve conflicts"
            )
        }
        tasks = @()
    }
}

$gitRepo = Test-GitRepository -Path $root
if ($UseWorktrees -and -not $gitRepo) {
    throw "UseWorktrees was requested, but $root is not a git repository."
}
if ($UseWorktrees -and -not (Test-GitHeadCommit -Path $root)) {
    throw "UseWorktrees requires at least one commit. Create an initial commit first, then rerun spawn-agents.ps1 with -UseWorktrees."
}

$tasks = @()
$worktreeMap = @()
foreach ($definition in $taskDefinitions) {
    $workspace = $root
    $branchName = "main"
    if ($UseWorktrees) {
        $worktree = New-WorkerWorktree -RepoRoot $root -TaskId $definition.TaskId
        $workspace = $worktree.Path
        $branchName = $worktree.Branch
    }

    $taskFilePath = Join-Path $tasksRoot "$($definition.TaskId).md"
    $statusFilePath = Join-Path $statusRoot "$($definition.TaskId).json"
    $handoffFilePath = Join-Path $handoffsRoot "$($definition.TaskId).md"

    $taskContent = New-AgentTaskContent `
        -TaskId $definition.TaskId `
        -Role $definition.Role `
        -Workspace $workspace `
        -ControllerRoot $root `
        -TaskFile $taskFilePath `
        -StatusFile $statusFilePath `
        -HandoffFile $handoffFilePath `
        -BoardFile $boardPath `
        -BranchName $branchName `
        -GoalText $Goal `
        -ContextText $ContextNote
    Set-Content -LiteralPath $taskFilePath -Value $taskContent -Encoding utf8

    $statusPayload = [ordered]@{
        task_id = $definition.TaskId
        role = $definition.Role
        state = "planned"
        summary = "Prepared by spawn-agents.ps1"
        workspace = $workspace
        updated_at = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    }
    ($statusPayload | ConvertTo-Json -Depth 5) | Set-Content -LiteralPath $statusFilePath -Encoding utf8

    Set-Content -LiteralPath $handoffFilePath -Value (New-HandoffContent -Role $definition.Role) -Encoding utf8

    $tasks += [ordered]@{
        id = $definition.TaskId
        role = $definition.Role
        title = $definition.Title
        state = "planned"
        workspace = $workspace
        branch = $branchName
        controller_root = $root
        task_file = ".codex-agents/tasks/$($definition.TaskId).md"
        status_file = ".codex-agents/status/$($definition.TaskId).json"
        handoff_file = ".codex-agents/handoffs/$($definition.TaskId).md"
        task_file_abs = $taskFilePath
        status_file_abs = $statusFilePath
        handoff_file_abs = $handoffFilePath
        board_file_abs = $boardPath
    }

    if ($UseWorktrees) {
        $worktreeMap += [ordered]@{
            id = $definition.TaskId
            role = $definition.Role
            branch = $branchName
            workspace = $workspace
        }
    }
}

$projectName = if ($board.project -and $board.project.name) { $board.project.name } else { Split-Path -Leaf $root }
$boardOutput = [ordered]@{
    version = 1
    project = [ordered]@{
        name = $projectName
        root = $root
    }
    workflow = [ordered]@{
        mode = "stable-relay"
        communication = "main-agent-relay"
        last_updated = (Get-Date).ToString("yyyy-MM-dd")
    }
    main_agent = [ordered]@{
        role = "controller"
        responsibilities = @(
            "decompose work",
            "route follow-up instructions",
            "merge worker outputs",
            "resolve conflicts"
        )
    }
    goal = $Goal
    tasks = @($tasks)
}
($boardOutput | ConvertTo-Json -Depth 6) | Set-Content -LiteralPath $boardPath -Encoding utf8
if ($UseWorktrees) {
    ($worktreeMap | ConvertTo-Json -Depth 5) | Set-Content -LiteralPath $worktreeMapPath -Encoding utf8
}

Write-Host "Prepared $($taskDefinitions.Count) worker task(s) under $agentsRoot" -ForegroundColor Green
Write-Host "Board: $boardPath" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Edit the task files under .codex-agents\\tasks\\ to add the real scope."
Write-Host "2. Open workers with:" -ForegroundColor Cyan
Write-Host "   powershell -ExecutionPolicy Bypass -File .\\spawn-agents.ps1 -Goal `"$Goal`""
Write-Host "3. Sync status with:" -ForegroundColor Cyan
Write-Host "   powershell -ExecutionPolicy Bypass -File .\\sync-agent-status.ps1"
Write-Host "4. Build a controller report with:" -ForegroundColor Cyan
Write-Host "   powershell -ExecutionPolicy Bypass -File .\\build-agent-report.ps1"
if ($UseWorktrees) {
    Write-Host "5. Clean up worktrees when finished with:" -ForegroundColor Cyan
    Write-Host "   powershell -ExecutionPolicy Bypass -File .\\cleanup-agent-worktrees.ps1"
    Write-Host "6. Skip opening windows when needed with:" -ForegroundColor Cyan
    Write-Host "   powershell -ExecutionPolicy Bypass -File .\\spawn-agents.ps1 -Goal `"$Goal`" -UseWorktrees -NoOpenWindows"
} else {
    Write-Host "5. Skip opening windows when needed with:" -ForegroundColor Cyan
    Write-Host "   powershell -ExecutionPolicy Bypass -File .\\spawn-agents.ps1 -Goal `"$Goal`" -NoOpenWindows"
}

if (-not $shouldOpenWindows) {
    Write-Host "Worker windows were not opened. Re-run without -NoOpenWindows when you are ready." -ForegroundColor Yellow
    exit 0
}

$codex = Get-Command $CodexCommand -ErrorAction SilentlyContinue
if (-not $codex) {
    throw "Could not find '$CodexCommand' on PATH."
}

foreach ($task in $tasks) {
    Open-AgentWindow `
        -Workspace $task.workspace `
        -TaskId $task.id `
        -Role $task.role `
        -TaskFile $task.task_file_abs `
        -StatusFile $task.status_file_abs `
        -HandoffFile $task.handoff_file_abs `
        -BranchName $task.branch `
        -CodexCli $codex.Source
}

Write-Host "Opened $($tasks.Count) worker window(s)." -ForegroundColor Green
