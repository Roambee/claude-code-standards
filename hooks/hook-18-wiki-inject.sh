#!/usr/bin/env bash
# Hook 18: Wiki inject — fetches top-5 wiki entries and injects at session start.
# Fires once per session via told_this_session dedup.
source "$HOME/roambee-claude/hooks/lib.sh"

told_this_session "hook-18-wiki-inject" && exit "$ALLOW"

ENDPOINT=$(config_get "wiki" "endpoint")
[ -z "$ENDPOINT" ] && exit "$ALLOW"

API_KEY_VAR=$(config_get "wiki" "apiKeyEnvVar")
ACCOUNT_ID_VAR=$(config_get "wiki" "accountIdEnvVar")
WORLD_NAME=$(config_get "wiki" "worldName")

API_KEY="${!API_KEY_VAR}"
ACCOUNT_ID="${!ACCOUNT_ID_VAR}"

[ -z "$API_KEY" ] && exit "$ALLOW"
[ -z "$ACCOUNT_ID" ] && exit "$ALLOW"
[ -z "$WORLD_NAME" ] && exit "$ALLOW"

PAYLOAD=$(python3 -c "
import json
print(json.dumps({
    'account_id': '$ACCOUNT_ID',
    'world_name': '$WORLD_NAME',
    'query': 'Decklar company products teams people processes decisions',
    'top_k': 5
}))
")

RESPONSE=$(curl -s --max-time 8 -X POST "$ENDPOINT/v1/recall" \
  -H "apikey: $API_KEY" \
  -H "x-account-id: $ACCOUNT_ID" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD" 2>/dev/null)

CONTEXT=$(echo "$RESPONSE" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    # Handle both list and dict response shapes
    if isinstance(data, list):
        items = data
    elif isinstance(data, dict):
        items = data.get('data', data.get('results', data.get('items', data.get('memories', []))))
    else:
        sys.exit(0)
    if not items:
        sys.exit(0)
    lines = ['[decklar-wiki] Company context:']
    for item in items[:5]:
        text = item.get('content', item.get('text', item.get('summary', '')))
        if text:
            lines.append('- ' + str(text)[:300].replace('\n', ' '))
    print('\n'.join(lines))
except Exception:
    pass
" 2>/dev/null)

[ -z "$CONTEXT" ] && exit "$ALLOW"

mark_told "hook-18-wiki-inject"
echo "$CONTEXT"
exit "$ALLOW"
