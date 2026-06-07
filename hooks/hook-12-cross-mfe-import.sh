#!/usr/bin/env bash
# Hook 12: Cross-package MFE import guard

CONTENT="${ROAMBEE_FILE_CONTENT:-$(cat 2>/dev/null)}"
FILE_PATH="${ROAMBEE_FILE_PATH:-}"

# Only applies inside packages/client/
echo "$FILE_PATH" | grep -q "packages/client/" || exit 0

CURRENT_PKG=$(echo "$FILE_PATH" | sed 's|.*/packages/client/\([^/]*\)/.*|\1|')

# Detect imports from other packages/client/* packages
BAD_IMPORT=$(echo "$CONTENT" | grep -E "from ['\"](@roambee/|../../)[^'\"]*['\"]" | \
  python3 -c "
import sys, re
current = '$CURRENT_PKG'
for line in sys.stdin:
    m = re.search(r\"from ['\\\"]((@roambee/|../../)([^'\\\"]*))\", line)
    if m:
        target = m.group(1)
        # Skip allowed packages
        if any(x in target for x in ['client-utility', 'shared', 'decklar']):
            continue
        print(line.strip())
" | head -1)

if [ -n "$BAD_IMPORT" ]; then
  echo "BLOCK: Direct cross-MFE import detected:"
  echo "  $BAD_IMPORT"
  echo ""
  echo "Cross-MFE communication must use EventEmitter or packages/shared/. Direct imports break module federation at runtime."
  exit 2
fi
exit 0
