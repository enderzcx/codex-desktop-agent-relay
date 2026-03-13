# Agent Relay Skill Package

This folder packages the repo-level multi-agent workflow into a reusable skill kit.

## Install into another repo

```powershell
powershell -ExecutionPolicy Bypass -File "G:\ICO\skill-packages\agent-relay\scripts\install-workflow.ps1" -ProjectRoot "D:\path\to\repo"
```

Add `-Force` to overwrite previously installed toolkit files.

## Contents

- `SKILL.md`: skill instructions
- `AGENTS_SNIPPET.md`: text to merge into a target repo `AGENTS.md`
- `payload/`: files copied into the target repo
- `scripts/install-workflow.ps1`: installer
