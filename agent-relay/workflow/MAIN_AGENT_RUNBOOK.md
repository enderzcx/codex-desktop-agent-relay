# Main Agent Runbook

Use this file when acting as the controller in the stable multi-agent workflow.

## Goal

Drive parallel worker threads without relying on direct worker-to-worker chat.

## Controller Loop

1. Prepare the worker tasks.

```powershell
powershell -ExecutionPolicy Bypass -File .\spawn-agents.ps1 -Goal "Replace with the real goal" -NoOpenWindows
```

2. Edit the generated task files under `.codex-agents/tasks/` so each worker has concrete scope.

3. Launch worker windows when ready.

```powershell
powershell -ExecutionPolicy Bypass -File .\spawn-agents.ps1 -Goal "Replace with the real goal"
```

If the repo is a git repo and workers will edit code in parallel, prefer:

```powershell
powershell -ExecutionPolicy Bypass -File .\spawn-agents.ps1 -Goal "Replace with the real goal" -UseWorktrees
```

Worktree mode requires the repository to already have an initial commit.

4. Periodically sync worker status into the board.

```powershell
powershell -ExecutionPolicy Bypass -File .\sync-agent-status.ps1
```

5. Generate a controller report from handoffs.

```powershell
powershell -ExecutionPolicy Bypass -File .\build-agent-report.ps1
```

6. If you want the controller to wait until workers finish or block before deciding what to do next:

```powershell
powershell -ExecutionPolicy Bypass -File .\await-agent-results.ps1
```

7. Route follow-up work by editing the task files or opening a worker window and giving it a new prompt.
8. Clean up worktrees after the task set is complete.

```powershell
powershell -ExecutionPolicy Bypass -File .\cleanup-agent-worktrees.ps1
```

## Decision Rules

- If two workers disagree, the main agent decides which result is more credible and asks for targeted follow-up if needed.
- If a worker needs another worker's result, the main agent copies only the necessary excerpt into that worker's task file.
- If a worker finishes early, do not broaden its scope casually. Either close it or assign one new narrow task.

## Handoff Rules

- `planned`: task is prepared but not yet active
- `in_progress`: worker is actively working
- `needs_review`: worker has delivered something that should be checked
- `blocked`: worker cannot continue without a decision or missing input
- `done`: worker is finished

## Suggested Prompts

When opening a worker window:

```text
Read .codex-agents/tasks/task-001-implementer.md, stay within that scope, update the matching status file as you work, and write your final result to the matching handoff file.
```

When routing follow-up:

```text
Re-read your task file and the latest handoff. Continue only the missing work. Do not expand scope without explicit instruction.
```
