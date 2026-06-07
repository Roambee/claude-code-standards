#!/usr/bin/env bash
# Hook 6: Secret scan

CONTENT="${ROAMBEE_FILE_CONTENT:-$(cat 2>/dev/null)}"
FILE_PATH="${ROAMBEE_FILE_PATH:-}"
MATCHES=()

# AWS Access Key
echo "$CONTENT" | grep -qE 'AKIA[A-Z0-9]{16}' && MATCHES+=("AWS Access Key pattern detected")

# Bearer token
echo "$CONTENT" | grep -qE 'Bearer [A-Za-z0-9\-_]{20,}' && MATCHES+=("Bearer token literal detected")

# Password assignment
echo "$CONTENT" | grep -qE "password\s*=\s*['\"][^'\"]{6,}" && MATCHES+=("Hardcoded password assignment detected")

# .env file being written (not .env.example)
if echo "$FILE_PATH" | grep -qE '\.env$' && ! echo "$FILE_PATH" | grep -q '\.env\.example'; then
  MATCHES+=(".env file being written — secrets must not be committed")
fi

if [ ${#MATCHES[@]} -gt 0 ]; then
  echo "BLOCK: Secret scan failed:"
  for m in "${MATCHES[@]}"; do
    echo "  🔴 $m"
  done
  echo "Remove secrets before writing this file. Use environment variables and .env.example with placeholders."
  exit 2
fi

exit 0
