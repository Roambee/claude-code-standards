#!/usr/bin/env bash
# Hook 13: Environment variable governance

CONTENT="${DECKLAR_FILE_CONTENT:-$(cat 2>/dev/null)}"
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
ENV_EXAMPLE="$REPO_ROOT/.env.example"

[ ! -f "$ENV_EXAMPLE" ] && exit 0

# Extract env var names from content being written
NEW_VARS=$(echo "$CONTENT" | grep -oE 'process\.env\.[A-Z_]+|os\.environ\["[A-Z_]+"\]|os\.environ\.get\("[A-Z_]+' | \
  sed "s/process\.env\.//;s/os\.environ\[\"//;s/os\.environ\.get(\"//;s/\".*//;s/\[\"//;s/\"\]//" | sort -u)

[ -z "$NEW_VARS" ] && exit 0

MISSING=()
for VAR in $NEW_VARS; do
  grep -q "^${VAR}=" "$ENV_EXAMPLE" || MISSING+=("$VAR")
done

if [ ${#MISSING[@]} -gt 0 ]; then
  echo "BLOCK: Environment variable(s) used in code but missing from .env.example:"
  for v in "${MISSING[@]}"; do
    echo "  ❌ $v"
  done
  echo ""
  echo "Add each missing variable to .env.example with a placeholder value and a comment describing what it does. Then re-attempt."
  exit 2
fi
exit 0
