# Stable Multi-Agent Workflow

This repository uses a stable relay model for multi-agent work:

- one main agent controls scope, routing, and decisions
- worker agents do not talk directly to each other
- all information exchange happens through the main agent or shared handoff files

This avoids relying on experimental agent-to-agent chat features while still letting each worker run in a real Codex CLI window.

## Layout

- `.codex-agents/board.json`: global task and status registry
- `.codex-agents/tasks/`: worker briefs
- `.codex-agents/status/`: machine-readable worker state
- `.codex-agents/handoffs/`: worker outputs for the main agent
- `.codex-agents/reports/`: final synthesized summaries
- `.codex-agents/worktrees.json`: optional task-to-worktree mapping when worktree mode is enabled
- `spawn-agents.ps1`: prepares worker files and opens real Codex CLI terminals by default
- `update-agent-status.ps1`: lets a worker or controller update one status file safely
- `sync-agent-status.ps1`: copies worker status back into the board
- `build-agent-report.ps1`: creates a controller-readable synthesis report from the current board and handoffs
- `await-agent-results.ps1`: waits until workers reach a controller handoff state, then builds the report and suggests the next action
- `cleanup-agent-worktrees.ps1`: removes worker worktrees when the task set is finished

## Roles

Use these default roles unless the task needs something more specific:

- `implementer`: ships the narrow feature or fix
- `tester`: checks validation, edge cases, and regression risk
- `reviewer`: reviews the change with findings first

## Operating Rules

- The main agent is the only source of cross-worker coordination.
- Each worker reads only its own task file unless the main agent explicitly shares another worker's output.
- Each worker writes only to its own status file and handoff file.
- If multiple workers will edit code, prefer separate git worktrees.
- Keep worker scopes narrow enough to finish in one thread.

## Quick Start

Prepare the board and worker files:

```powershell
powershell -ExecutionPolicy Bypass -File .\spawn-agents.ps1 -Goal "Replace this with the real goal" -NoOpenWindows
```

By default, the same command without `-NoOpenWindows` will open real Codex CLI windows for each worker:

```powershell
powershell -ExecutionPolicy Bypass -File .\spawn-agents.ps1 -Goal "Replace this with the real goal"
```

If the repository is a git repo and you want worker isolation, add `-UseWorktrees`.

```powershell
powershell -ExecutionPolicy Bypass -File .\spawn-agents.ps1 -Goal "Replace this with the real goal" -UseWorktrees
```

When worktree mode is enabled:

- the repo must already have at least one commit
- each worker gets its own git worktree under `.worktrees/`
- each worker gets a dedicated branch using the `enderzcx/OnchainClaw/` prefix
- task files point to absolute shared paths under the controller root so workers can still update shared status and handoffs

After workers update their `status/*.json` files, sync those summaries back into the board:

```powershell
powershell -ExecutionPolicy Bypass -File .\sync-agent-status.ps1
```

Create a synthesis report for the main agent:

```powershell
powershell -ExecutionPolicy Bypass -File .\build-agent-report.ps1
```

If you want the main thread to wait for workers and only intervene after they reach a handoff state:

```powershell
powershell -ExecutionPolicy Bypass -File .\await-agent-results.ps1
```

Clean up worker worktrees after the task set is finished:

```powershell
powershell -ExecutionPolicy Bypass -File .\cleanup-agent-worktrees.ps1
```

## Main Agent Loop

1. Fill in each worker brief under `.codex-agents/tasks/`.
2. Launch workers.
3. Wait for worker handoffs under `.codex-agents/handoffs/`.
4. Read all handoffs and route follow-up work.
5. Write the final decision or report under `.codex-agents/reports/`.

## Recommended Worker Prompt

When a worker window opens, give it a short instruction like:

```text
Read .codex-agents/tasks/task-001-implementer.md, follow the scope exactly, and write your output to the matching handoff file.
```
