#!/usr/bin/env bash
# Hook 9: AI observability reminder — fires once per session

source "$HOME/roambee-claude/hooks/lib.sh"

told_this_session "hook-09-ai-observability" && exit 0

echo "🤖 You are editing an AI service. Before writing LLM calls, ensure:"
echo "  1. Every call logs: model name, token counts (in + out), latency, request_id"
echo "  2. No raw user input or PII is logged"
echo "  3. All LLM calls go through OpenRouter (not direct Anthropic/OpenAI SDK)"

mark_told "hook-09-ai-observability"
exit 0
