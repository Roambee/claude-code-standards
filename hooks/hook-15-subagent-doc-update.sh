#!/usr/bin/env bash
# Hook 15: Subagent doc update reminder (PostToolUse — fires after Write/Edit)

FILE_PATH="${ROAMBEE_FILE_PATH:-}"

# Check if the file is architecture-impacting
IMPACTING=$(echo "$FILE_PATH" | grep -E '(controllers?|services?|modules?|routers?)/[^/]+\.(ts|py)$|main\.(ts|py)$|App\.tsx$|package\.json$|pyproject\.toml$')
[ -z "$IMPACTING" ] && exit 0

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
[ -z "$REPO_ROOT" ] && exit 0

echo "📝 Before marking this task Done — check if architecture.md or README.md needs updating."
echo "   If you added a service, changed local setup, added env vars, or changed the tech stack, update those files and include them in the commit."
exit 0
