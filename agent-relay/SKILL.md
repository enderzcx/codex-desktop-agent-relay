---
name: agent-relay
description: Run a stable main-agent and worker-agent workflow with shared board files, real Codex CLI worker windows, status sync, waiting, and controller reports. Use when one main thread should delegate to 2-5 narrow workers and make decisions only after workers finish or block.
---

# Agent Relay

Use this skill when a main Codex thread should coordinate a small worker batch without letting workers talk directly to each other.

This skill packages a conservative workflow:

- one main thread owns decomposition, routing, and decisions
- each worker gets one narrow brief
- workers write only to their own status and handoff files
- the main thread waits for workers to finish, then decides whether to continue any thread or summarize for the user

## When To Use It

Use this skill when:

- the task is too broad for one thread
- you want real Codex CLI worker windows
- you want shared state in the repo instead of hidden app internals
- you want the controller to wait for all workers before deciding what happens next

Do not use this skill when:

- the work is tiny enough for one thread
- workers must directly debate each other in real time
- the repo owner does not want `.codex-agents/` state files in the workspace

## Install Into A Repo

From the target workspace, run:

```powershell
powershell -ExecutionPolicy Bypass -File "G:\ICO\agent-relay\install-workflow.ps1" -ProjectRoot .
```

This copies the packaged workflow files into the current repo without touching an existing `AGENTS.md`.

If you want to overwrite an older installed copy of the toolkit files, add `-Force`.

## Core Flow

1. Read `START_HERE.md`.

2. Generate worker tasks:

```powershell
powershell -ExecutionPolicy Bypass -File .\spawn-agents.ps1 -Goal "Replace with the real goal" -NoOpenWindows
```

3. Replace placeholder task context with the real files, flows, interfaces, or questions.

4. Launch workers:

```powershell
powershell -ExecutionPolicy Bypass -File .\spawn-agents.ps1 -Goal "Replace with the real goal"
```

5. Let the controller wait for all workers to reach a handoff state:

```powershell
powershell -ExecutionPolicy Bypass -File .\await-agent-results.ps1
```

6. Read the generated report and decide:

- continue only the workers that need follow-up
- or summarize the completed handoffs for the user

## Worktree Mode

If workers will edit code in parallel and the repo already has a first commit:

```powershell
powershell -ExecutionPolicy Bypass -File .\spawn-agents.ps1 -Goal "Replace with the real goal" -UseWorktrees
```

When done:

```powershell
powershell -ExecutionPolicy Bypass -File .\cleanup-agent-worktrees.ps1
```

## Controller Rules

- Prefer 2-5 workers, not many tiny workers.
- Do not continue blocked workers until the missing context is provided.
- Treat worker handoffs as the source of truth for follow-up routing.
- If all workers finish cleanly, summarize for the user instead of reopening threads by default.
- If a reviewer has no implementation artifact, stop and ask the main agent to provide one before rerunning review.

## Files Installed By This Skill

- `spawn-agents.ps1`
- `update-agent-status.ps1`
- `sync-agent-status.ps1`
- `build-agent-report.ps1`
- `await-agent-results.ps1`
- `cleanup-agent-worktrees.ps1`
- `START_HERE.md`
- `.codex-agents/README.md`
- `.codex-agents/tasks/TASK_TEMPLATE.md`
- `.codex-agents/handoffs/HANDOFF_TEMPLATE.md`

## Notes

- The packaged files live under this skill's `workflow/` directory.
