#!/usr/bin/env bash
# Hook 3: CI file warning — fires once per session

source "$HOME/decklar-claude/hooks/lib.sh"

told_this_session "hook-03-ci-warning" && exit 0

echo "⚠️  You are editing a CI/CD configuration file. This affects all developers. Be conservative, verify the change won't break the pipeline, and confirm the target environment before proceeding."

mark_told "hook-03-ci-warning"
exit 0
