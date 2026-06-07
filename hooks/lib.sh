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
