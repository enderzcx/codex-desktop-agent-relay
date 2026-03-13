## Agent Relay

- Use the `agent-relay` skill when one main Codex thread should coordinate 2-5 narrow worker threads.
- Keep shared state under `.codex-agents/`.
- Let the main thread wait until workers reach a handoff state before deciding whether to continue any thread or summarize for the user.
- If workers will edit code in parallel, use `spawn-agents.ps1 -UseWorktrees`.
- Do not let workers talk directly to each other; route follow-up through the main agent.
