# Agent Relay

Install the workflow into the current project with the simplest available entrypoint.

## Local checkout

If you cloned this repo locally:

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1 -ProjectRoot .
```

Or on Bash:

```bash
bash ./install.sh --project-root .
```

## GitHub one-liner

If this repo is public on GitHub, the Bash path can be a single line:

```bash
curl -fsSL https://raw.githubusercontent.com/enderzcx/codex-desktop-agent-relay/main/install.sh | bash
```

PowerShell can do the same in one line:

```powershell
$script = irm https://raw.githubusercontent.com/enderzcx/codex-desktop-agent-relay/main/install.ps1; & ([scriptblock]::Create($script))
```

The installers still accept overrides if you ever want to test another branch or mirror.

## What gets installed

- `spawn-agents.ps1`
- `update-agent-status.ps1`
- `sync-agent-status.ps1`
- `build-agent-report.ps1`
- `await-agent-results.ps1`
- `cleanup-agent-worktrees.ps1`
- `START_HERE.md`
- `MULTI_AGENT_WORKFLOW.md`
- `MAIN_AGENT_RUNBOOK.md`
- `.codex-agents/README.md`
- `.codex-agents/tasks/TASK_TEMPLATE.md`
- `.codex-agents/handoffs/HANDOFF_TEMPLATE.md`
- `.codex-agents/status/README.md`
- `.codex-agents/reports/README.md`

## Advanced path

If users want the reusable Codex skill itself, the packaged skill lives at [skill-packages/agent-relay/SKILL.md](/G:/ICO/skill-packages/agent-relay/SKILL.md).
