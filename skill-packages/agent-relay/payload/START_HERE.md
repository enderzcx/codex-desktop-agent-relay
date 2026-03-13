# Start Here

If you want to run the stable multi-agent workflow in this repo, use this order:

1. Read [MULTI_AGENT_WORKFLOW.md](/G:/ICO/MULTI_AGENT_WORKFLOW.md) for the architecture.
2. Read [MAIN_AGENT_RUNBOOK.md](/G:/ICO/MAIN_AGENT_RUNBOOK.md) for the controller loop.
3. Prepare worker files:

```powershell
powershell -ExecutionPolicy Bypass -File .\spawn-agents.ps1 -Goal "Replace with the real goal" -NoOpenWindows
```

4. Edit the generated task files under `.codex-agents/tasks/`.
5. Launch worker CLI windows:

```powershell
powershell -ExecutionPolicy Bypass -File .\spawn-agents.ps1 -Goal "Replace with the real goal"
```

If this is a git repo and the workers will edit code in parallel, use:

```powershell
powershell -ExecutionPolicy Bypass -File .\spawn-agents.ps1 -Goal "Replace with the real goal" -UseWorktrees
```

Worktree mode requires the repo to already have a first commit.

6. As workers progress:

```powershell
powershell -ExecutionPolicy Bypass -File .\sync-agent-status.ps1
powershell -ExecutionPolicy Bypass -File .\build-agent-report.ps1
```

If you want the main thread to simply wait and then decide after workers finish:

```powershell
powershell -ExecutionPolicy Bypass -File .\await-agent-results.ps1
```

7. Clean up worker worktrees after the task set is done:

```powershell
powershell -ExecutionPolicy Bypass -File .\cleanup-agent-worktrees.ps1
```

Helpful files:

- [AGENTS.md](/G:/ICO/AGENTS.md)
- [TASK_TEMPLATE.md](/G:/ICO/TASK_TEMPLATE.md)
- [README.md](/G:/ICO/.codex-agents/README.md)
