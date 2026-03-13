# Agent Relay

`agent-relay` is a workflow kit for **Codex Windows Desktop**.

It lets a **main thread** launch **child agents in Codex CLI windows** so work can run in parallel. The main thread can then read each child agent's **status**, **handoff**, and **result**, and decide whether to continue some threads or summarize everything for the user.

What it does:

- main thread delegates work to child agents
- child agents work in real CLI windows
- shared files track progress and results
- main thread reads those files and makes the next decision

## Install

Bash:

```bash
curl -fsSL https://raw.githubusercontent.com/enderzcx/codex-desktop-agent-relay/main/install.sh | bash
```

PowerShell:

```powershell
$script = irm https://raw.githubusercontent.com/enderzcx/codex-desktop-agent-relay/main/install.ps1; & ([scriptblock]::Create($script))
```

If you already cloned this repo locally:

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1 -ProjectRoot .
```

## What gets installed

- worker launcher scripts
- main-thread sync and report scripts
- optional worktree cleanup
- `.codex-agents/` shared state files
- workflow docs and templates

## Use this when

- one Codex Desktop thread is not enough
- you want child agents to run in parallel
- you want the main thread to collect their states and results
- you want the main thread to decide what happens next

## More

- Reusable skill package: [agent-relay/SKILL.md](/G:/ICO/agent-relay/SKILL.md)
- Packaged installer docs: [agent-relay/README.md](/G:/ICO/agent-relay/README.md)
