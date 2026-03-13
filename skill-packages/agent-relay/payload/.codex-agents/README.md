# .codex-agents

This folder is the shared contract for stable multi-agent collaboration.

## Files

- `board.json`: project-level registry for the controller
- `tasks/`: one markdown brief per worker
- `status/`: one JSON status file per worker
- `handoffs/`: one markdown output per worker
- `reports/`: controller summaries and final synthesis

## Status Values

Use these values in `status/*.json`:

- `planned`
- `in_progress`
- `needs_review`
- `blocked`
- `done`

## Communication Model

- Workers do not talk directly to each other.
- Workers ask for missing information by writing it into their handoff or status notes.
- The main agent reads those notes and decides what to share back out.

## Naming

Use stable ids like:

- `task-001-implementer`
- `task-002-tester`
- `task-003-reviewer`
