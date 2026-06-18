#!/usr/bin/env bash
# Hook 7: Dependency governance — fires once per session

source "$HOME/roambee-claude/hooks/lib.sh"

told_this_session "hook-07-dep-governance" && exit 0

echo "📦 You are adding a dependency. Before proceeding:"
echo "  1. Check if an equivalent already exists in the monorepo (grep the packages/ directory)"
echo "  2. UI components must use @decklar/ui-library — do not add a separate component library"
echo "  3. Python LLM calls must go through OpenRouter — do not add @anthropic-ai/sdk or openai directly"

mark_told "hook-07-dep-governance"
exit 0
