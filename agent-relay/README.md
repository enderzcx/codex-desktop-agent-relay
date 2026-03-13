# Agent Relay Skill Package

This package turns the workflow into a reusable Codex skill for **Codex Windows Desktop**.

It is for the pattern where:

- a main thread launches child agents in Codex CLI windows
- child agents work in parallel
- the main thread reads their status files and handoffs
- the main thread decides whether to continue threads or summarize results

## Install into another repo

```powershell
powershell -ExecutionPolicy Bypass -File "G:\ICO\agent-relay\scripts\install-workflow.ps1" -ProjectRoot "D:\path\to\repo"
```

Add `-Force` to overwrite previously installed toolkit files.

## Contents

- `SKILL.md`: skill instructions
- `AGENTS_SNIPPET.md`: text to merge into a target repo `AGENTS.md`
- `payload/`: files copied into the target repo
- `scripts/install-workflow.ps1`: installer
