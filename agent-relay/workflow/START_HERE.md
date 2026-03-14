# Start Here

Use this file as the only quick-start reference for the installed workflow.

1. Fastest path: one command to launch workers and wait for a controller decision point:

```powershell
powershell -ExecutionPolicy Bypass -File .\start-agent-relay.ps1 -Goal "Replace with the real goal"
```

This will:

- generate worker task files
- open worker CLI windows by default
- run the low-token watcher
- stop when a worker blocks, asks for review, or all workers finish

Preset modes are available when you want specialized worker roles:

- `general`
- `ceo-review`
- `eng-review`
- `staff-debug`
- `qa-bug-hunt`

Example:

```powershell
powershell -ExecutionPolicy Bypass -File .\start-agent-relay.ps1 -Mode qa-bug-hunt -Goal "Find the most likely release blockers in this flow"
```

2. If you want to prepare worker files first:

```powershell
powershell -ExecutionPolicy Bypass -File .\start-agent-relay.ps1 -Goal "Replace with the real goal" -PrepareOnly
```

3. Edit the generated task files under `.codex-agents/tasks/`.
4. Launch worker CLI windows:

```powershell
powershell -ExecutionPolicy Bypass -File .\spawn-agents.ps1 -Goal "Replace with the real goal"
```

If this is a git repo and the workers will edit code in parallel, use:

```powershell
powershell -ExecutionPolicy Bypass -File .\spawn-agents.ps1 -Goal "Replace with the real goal" -UseWorktrees
```

Worktree mode requires the repo to already have a first commit.

5. For the lowest-token controller flow, let a local watcher wait for a decision point:

```powershell
powershell -ExecutionPolicy Bypass -File .\watch-agent-results.ps1
```

This waits until any worker is `blocked`, any worker is `needs_review`, or all workers have reached terminal states. It then syncs status, builds the report, and writes `.codex-agents/reports/controller-trigger.json`.

If you prefer manual polling as workers progress:

```powershell
powershell -ExecutionPolicy Bypass -File .\sync-agent-status.ps1
powershell -ExecutionPolicy Bypass -File .\build-agent-report.ps1
```

If you want the main thread to simply wait and then decide after workers finish:

```powershell
powershell -ExecutionPolicy Bypass -File .\await-agent-results.ps1
```

6. Clean up worker worktrees after the task set is done:

```powershell
powershell -ExecutionPolicy Bypass -File .\cleanup-agent-worktrees.ps1
```

Status values used by workers are: `planned`, `in_progress`, `needs_review`, `blocked`, `done`.
