#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="."
REPO="enderzcx/codex-desktop-agent-relay"
REF="main"
BASE_URL=""
FORCE="0"

usage() {
  cat <<'EOF'
Usage:
  bash ./install.sh [--project-root PATH] [--repo owner/repo] [--ref main] [--base-url URL] [--force]

Examples:
  bash ./install.sh --project-root .
  curl -fsSL https://raw.githubusercontent.com/enderzcx/codex-desktop-agent-relay/main/install.sh | bash
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project-root)
      PROJECT_ROOT="$2"
      shift 2
      ;;
    --repo)
      REPO="$2"
      shift 2
      ;;
    --ref)
      REF="$2"
      shift 2
      ;;
    --base-url)
      BASE_URL="$2"
      shift 2
      ;;
    --force)
      FORCE="1"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if ! command -v curl >/dev/null 2>&1; then
  echo "curl is required." >&2
  exit 1
fi

normalize_path() {
  local input="$1"

  if [[ "$input" =~ ^[A-Za-z]:[\\/].* ]]; then
    if command -v wslpath >/dev/null 2>&1; then
      wslpath -a "$input"
      return 0
    fi
    if command -v cygpath >/dev/null 2>&1; then
      cygpath -au "$input"
      return 0
    fi

    local drive rest
    drive="$(printf '%s' "${input:0:1}" | tr '[:upper:]' '[:lower:]')"
    rest="${input:2}"
    rest="${rest//\\//}"
    printf '/mnt/%s/%s\n' "$drive" "${rest#/}"
    return 0
  fi

  printf '%s\n' "$input"
}

PROJECT_ROOT="$(normalize_path "$PROJECT_ROOT")"
mkdir -p "$PROJECT_ROOT"
PROJECT_ROOT="$(cd "$PROJECT_ROOT" && pwd)"

SCRIPT_DIR=""
if [[ -n "${BASH_SOURCE[0]:-}" && -f "${BASH_SOURCE[0]}" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

LOCAL_PAYLOAD=""
if [[ -n "$SCRIPT_DIR" && -d "$SCRIPT_DIR/agent-relay/payload" ]]; then
  LOCAL_PAYLOAD="$SCRIPT_DIR/agent-relay/payload"
fi

if [[ -z "$BASE_URL" && -z "$LOCAL_PAYLOAD" ]]; then
  if [[ -z "$REPO" ]]; then
    echo "Could not determine a GitHub repo. Pass --repo owner/repo or --base-url." >&2
    exit 1
  fi
  BASE_URL="https://raw.githubusercontent.com/$REPO/$REF/agent-relay/payload"
fi

FILES=(
  "await-agent-results.ps1"
  "build-agent-report.ps1"
  "cleanup-agent-worktrees.ps1"
  "MAIN_AGENT_RUNBOOK.md"
  "MULTI_AGENT_WORKFLOW.md"
  "spawn-agents.ps1"
  "START_HERE.md"
  "sync-agent-status.ps1"
  "update-agent-status.ps1"
  ".codex-agents/README.md"
  ".codex-agents/handoffs/HANDOFF_TEMPLATE.md"
  ".codex-agents/reports/README.md"
  ".codex-agents/status/README.md"
  ".codex-agents/tasks/TASK_TEMPLATE.md"
)

for rel in "${FILES[@]}"; do
  dst="$PROJECT_ROOT/$rel"
  mkdir -p "$(dirname "$dst")"
  if [[ -f "$dst" && "$FORCE" != "1" ]]; then
    echo "Skipped existing file: $dst"
    continue
  fi

  if [[ -n "$LOCAL_PAYLOAD" ]]; then
    cp "$LOCAL_PAYLOAD/$rel" "$dst"
  else
    curl -fsSL "$BASE_URL/$rel" -o "$dst"
  fi
  echo "Installed: $dst"
done

echo
echo "Agent relay workflow installed into $PROJECT_ROOT"
