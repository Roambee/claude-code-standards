#!/usr/bin/env bash
# Hook 0: Plugin update notifier — fires on first tool call of session
# Uses a session flag file to run only once per session

SESSION_FLAG="/tmp/roambee-hook0-$$-checked"
[ -f "$SESSION_FLAG" ] && exit 0
touch "$SESSION_FLAG"

BEHIND=$(git -C "$HOME/roambee-claude" fetch --quiet 2>/dev/null && \
         git -C "$HOME/roambee-claude" rev-list HEAD..origin/main --count 2>/dev/null || echo "0")

if [ "${BEHIND:-0}" -gt 0 ]; then
  echo "⚠️  roambee-claude plugin has $BEHIND new commit(s). Run \`git pull\` in ~/roambee-claude/ or run /doctor to apply updates."
fi
exit 0
