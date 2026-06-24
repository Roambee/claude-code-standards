#!/usr/bin/env bash
# Hook 1: Architecture check — hard block if architecture.md missing
# Runs on first Write/Edit per session in a git repo

SESSION_FLAG="/tmp/decklar-hook1-$$-checked"
[ -f "$SESSION_FLAG" ] && exit 0

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
[ -z "$REPO_ROOT" ] && touch "$SESSION_FLAG" && exit 0

# Check for opt-out flag
[ -f "$REPO_ROOT/.no-architecture-check" ] && touch "$SESSION_FLAG" && exit 0

if [ ! -f "$REPO_ROOT/architecture.md" ]; then
  echo "BLOCK: This repository is missing \`architecture.md\`. Run \`/new-repo\` to generate it before writing any code. This ensures Claude has full context about the service architecture."
  exit 2
fi

touch "$SESSION_FLAG"
exit 0
