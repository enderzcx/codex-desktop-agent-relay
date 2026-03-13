# Start Here

Use this file as the only quick-start reference for the installed workflow.

1. Prepare worker files:

```powershell
powershell -ExecutionPolicy Bypass -File .\spawn-agents.ps1 -Goal "Replace with the real goal" -NoOpenWindows
```

2. Edit the generated task files under `.codex-agents/tasks/`.
3. Launch worker CLI windows:

```powershell
powershell -ExecutionPolicy Bypass -File .\spawn-agents.ps1 -Goal "Replace with the real goal"
```

If this is a git repo and the workers will edit code in parallel, use:

```powershell
powershell -ExecutionPolicy Bypass -File .\spawn-agents.ps1 -Goal "Replace with the real goal" -UseWorktrees
```

Worktree mode requires the repo to already have a first commit.

4. As workers progress:

```powershell
powershell -ExecutionPolicy Bypass -File .\sync-agent-status.ps1
powershell -ExecutionPolicy Bypass -File .\build-agent-report.ps1
```

If you want the main thread to simply wait and then decide after workers finish:

```powershell
powershell -ExecutionPolicy Bypass -File .\await-agent-results.ps1
```

5. Clean up worker worktrees after the task set is done:

```powershell
powershell -ExecutionPolicy Bypass -File .\cleanup-agent-worktrees.ps1
```

Status values used by workers are: `planned`, `in_progress`, `needs_review`, `blocked`, `done`.
