#!/usr/bin/env bash
# Shared utilities for roambee-claude hooks

PLUGIN_DIR="$HOME/roambee-claude"
CONFIG_FILE="$HOME/.claude/roambee-config.json"

# Get git repo root or empty string if not in a git repo
git_root() {
  git rev-parse --show-toplevel 2>/dev/null || echo ""
}

# Read a value from roambee-config.json
# Usage: config_get "jira" "projectKey"
config_get() {
  python3 -c "
import json, os, sys
try:
    d = json.load(open('$CONFIG_FILE'))
    keys = sys.argv[1:]
    for k in keys:
        d = d[k]
    print(d)
except: print('')
" "$1" "$2" 2>/dev/null
}

# Exit codes
BLOCK=2      # Hard block — Claude stops and shows message
ALLOW=0      # Pass silently
INJECT=0     # Context injection — print message then exit 0 (Claude reads stdout)

# ── Session-scoped deduplication ─────────────────────────────────────────────
# Inject-only hooks (reminders, not safety checks) call told_this_session
# before outputting and mark_told after. Scoped to: git repo × calendar day.
# This prevents the same reminder from firing 20 times in one coding session.

_roambee_session_dir() {
  local repo_id date
  repo_id=$(git rev-parse --show-toplevel 2>/dev/null | cksum | cut -d' ' -f1 2>/dev/null || echo "global")
  date=$(date +%Y%m%d)
  echo "/tmp/roambee-${repo_id}-${date}"
}

# Returns 0 (true) if this key was already told in this session.
told_this_session() {
  local dir key
  dir=$(_roambee_session_dir)
  key=$(echo "$1" | tr '/: .' '____')
  [ -f "${dir}/${key}" ]
}

# Marks a key as told for this session.
mark_told() {
  local dir key
  dir=$(_roambee_session_dir)
  mkdir -p "$dir" 2>/dev/null
  key=$(echo "$1" | tr '/: .' '____')
  touch "${dir}/${key}"
}
