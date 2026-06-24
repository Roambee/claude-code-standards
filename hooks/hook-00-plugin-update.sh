#!/usr/bin/env bash
# Hook 0: Plugin update notifier — fires once per day per repo

source "$HOME/decklar-claude/hooks/lib.sh"

told_this_session "hook-00-update-check" && exit 0

BEHIND=$(git -C "$HOME/decklar-claude" fetch --quiet 2>/dev/null && \
         git -C "$HOME/decklar-claude" rev-list HEAD..origin/main --count 2>/dev/null || echo "0")

if [ "${BEHIND:-0}" -gt 0 ]; then
  echo "⚠️  decklar-claude plugin has $BEHIND new commit(s). Run \`git pull\` in ~/decklar-claude/ or run /doctor to apply updates."
fi

mark_told "hook-00-update-check"
exit 0
