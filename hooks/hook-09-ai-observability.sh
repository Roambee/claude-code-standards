#!/usr/bin/env bash
# Hook 9: AI observability reminder

echo "🤖 You are editing an AI service. Before writing LLM calls, ensure:"
echo "  1. Every call logs: model name, token counts (in + out), latency, request_id"
echo "  2. No raw user input or PII is logged"
echo "  3. All LLM calls go through OpenRouter (not direct Anthropic/OpenAI SDK)"
exit 0
