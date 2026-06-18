#!/usr/bin/env bash
# Hook 16: Architecture doc injection — fires once per module per session.
# On first edit in a module, surfaces the path to its architecture overview.
source "$HOME/roambee-claude/hooks/lib.sh"

FILEPATH="${ROAMBEE_FILE_PATH:-}"
[ -z "$FILEPATH" ] && exit "$ALLOW"

GIT_ROOT=$(git_root 2>/dev/null) || exit "$ALLOW"
ARCH_DIR="$GIT_ROOT/docs/architecture"
[ ! -d "$ARCH_DIR" ] && exit "$ALLOW"

# Extract module name from path: packages/<module>/... or apps/<module>/...
MODULE=$(echo "$FILEPATH" | grep -oE '(packages|apps)/[^/]+' | head -1 | cut -d/ -f2)
[ -z "$MODULE" ] && exit "$ALLOW"

MODULE_ARCH="$ARCH_DIR/$MODULE"
[ ! -d "$MODULE_ARCH" ] && exit "$ALLOW"

# Dedup per module: surface the reminder only once per session per module
told_this_session "hook-16-$MODULE" && exit "$ALLOW"

OVERVIEW="$MODULE_ARCH/overview.md"
if [ -f "$OVERVIEW" ]; then
  REL_PATH=$(echo "$OVERVIEW" | sed "s|$GIT_ROOT/||")
  echo "[roambee] Module '$MODULE' → $REL_PATH — read before making structural changes."
else
  # No overview yet — just name the module dir
  REL_DIR=$(echo "$MODULE_ARCH" | sed "s|$GIT_ROOT/||")
  echo "[roambee] Module '$MODULE' has architecture docs in $REL_DIR — read before making structural changes."
fi

mark_told "hook-16-$MODULE"
exit "$ALLOW"
