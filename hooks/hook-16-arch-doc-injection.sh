#!/usr/bin/env bash
# Injects a reminder to read the relevant architecture deep file when editing
# in a known module directory. Only fires if docs/architecture/<module>/ exists.
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

ARCH_FILES=$(find "$MODULE_ARCH" -name "*.md" 2>/dev/null | sed "s|$GIT_ROOT/||")
[ -z "$ARCH_FILES" ] && exit "$ALLOW"

echo "[roambee] Architecture docs for '$MODULE':"
echo "$ARCH_FILES" | while read -r f; do echo "  $f"; done
echo "Read the relevant doc before making structural changes to this module."

exit "$ALLOW"
