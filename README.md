# Agent Relay

`agent-relay` is a workflow kit for **Codex Windows Desktop**.

It lets a **main thread** launch **child agents in Codex CLI windows** so work can run in parallel. The main thread can then read each child agent's **status**, **handoff**, and **result**, and decide whether to continue some threads or summarize everything for the user.

This repo now bundles two layers:

- `agent-relay`: worker orchestration, watcher, and controller reports
- `context-stack`: `AGENTS.md`, `AGENT.md`, `STATUS.md`, and `.ai-context/` templates for project context and long-task memory

What it does:

- main thread delegates work to child agents
- child agents work in real CLI windows
- shared files track progress and results
- a lightweight watcher can wait for a decision point without burning main-thread tokens
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

By default this installs the full stack into the target project:

- relay workflow scripts
- `AGENTS.md`
- local `AGENT.md`
- local `STATUS.md`
- `.ai-context/TASK.template.md`
- `.ai-context/PR-REVIEW.template.md`

If you only want the workflow scripts:

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1 -ProjectRoot . -WorkflowOnly
```

If you only want the context layer:

```powershell
powershell -ExecutionPolicy Bypass -File .\context-stack\install-context.ps1 -ProjectRoot .
```

## Quick Start

After installation, the simplest entrypoint is:

```powershell
powershell -ExecutionPolicy Bypass -File .\start-agent-relay.ps1 -Goal "Replace with the real goal"
```

This prepares worker files, opens child agent CLI windows by default, and runs the low-token watcher until the controller should wake up.

You can also start with a preset role stack:

```powershell
powershell -ExecutionPolicy Bypass -File .\start-agent-relay.ps1 -Mode ceo-review -Goal "Challenge this product direction"
```

Available modes:

- `general`
- `ceo-review`
- `eng-review`
- `staff-debug`
- `qa-bug-hunt`

## What gets installed

- one-command starter script
- worker launcher scripts
- main-thread sync and report scripts
- low-token controller watcher script
- project context templates
- optional worktree cleanup
- `.codex-agents/` shared state files
- `.ai-context/` task and review templates

## Use this when

- one Codex Desktop thread is not enough
- you want child agents to run in parallel
- you want the main thread to collect their states and results
- you want the main thread to decide what happens next

## More

- Reusable skill package: [agent-relay/SKILL.md](/G:/ICO/agent-relay/SKILL.md)
