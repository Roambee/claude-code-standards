#!/usr/bin/env bash
# Hook 8: Prompt-as-code reminder

CONTENT="${ROAMBEE_FILE_CONTENT:-$(cat 2>/dev/null)}"

# Check for string literals > 300 chars (rough proxy for embedded prompts)
if echo "$CONTENT" | python3 -c "
import sys, re
content = sys.stdin.read()
# Find quoted strings longer than 300 chars
matches = re.findall(r'[\"\']{1,3}.{300,}[\"\']{1,3}', content, re.DOTALL)
sys.exit(0 if matches else 1)
" 2>/dev/null; then
  echo "💡 This looks like a long string literal that may be a prompt. Consider extracting it to \`prompts/<feature-name>.md\` so it can be versioned, reviewed, and reused independently."
fi
exit 0
