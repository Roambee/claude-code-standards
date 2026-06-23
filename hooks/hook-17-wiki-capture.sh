#!/usr/bin/env bash
# Hook 17: Wiki capture — digests last assistant turn to decklar-wiki on every Stop.
source "$HOME/roambee-claude/hooks/lib.sh"

ENDPOINT=$(config_get "wiki" "endpoint")
[ -z "$ENDPOINT" ] && exit "$ALLOW"

API_KEY_VAR=$(config_get "wiki" "apiKeyEnvVar")
ACCOUNT_ID_VAR=$(config_get "wiki" "accountIdEnvVar")
AGENT_NAME=$(config_get "wiki" "agentName")
WORLD_NAME=$(config_get "wiki" "worldName")

API_KEY="${!API_KEY_VAR}"
ACCOUNT_ID="${!ACCOUNT_ID_VAR}"

[ -z "$API_KEY" ] && exit "$ALLOW"
[ -z "$ACCOUNT_ID" ] && exit "$ALLOW"
[ -z "$AGENT_NAME" ] && exit "$ALLOW"
[ -z "$WORLD_NAME" ] && exit "$ALLOW"

# Read Stop event JSON from stdin — Claude Code provides transcript array
INPUT=$(cat)

# Extract last assistant message from transcript
MESSAGE=$(echo "$INPUT" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    transcript = data.get('transcript', [])
    # Walk backwards to find last assistant turn
    for turn in reversed(transcript):
        if turn.get('role') == 'assistant':
            content = turn.get('content', '')
            if isinstance(content, list):
                # Content block array format
                text = ' '.join(
                    b.get('text', '') for b in content
                    if isinstance(b, dict) and b.get('type') == 'text'
                )
            else:
                text = str(content)
            print(text.strip())
            break
except Exception:
    pass
" 2>/dev/null)

# Skip trivial or empty responses
[ -z "$MESSAGE" ] && exit "$ALLOW"
[ "${#MESSAGE}" -lt 80 ] && exit "$ALLOW"

# Background: POST to /v1/digest (non-blocking, no output)
(
  PAYLOAD=$(python3 -c "
import json, sys
content = sys.stdin.read().strip()
print(json.dumps({
    'account_id': '$ACCOUNT_ID',
    'world_name': '$WORLD_NAME',
    'agent_name': '$AGENT_NAME',
    'content': content
}))
" <<< "$MESSAGE" 2>/dev/null)

  [ -z "$PAYLOAD" ] && exit 0

  curl -s -X POST "$ENDPOINT/v1/digest?wait=false" \
    -H "apikey: $API_KEY" \
    -H "x-account-id: $ACCOUNT_ID" \
    -H "Content-Type: application/json" \
    -d "$PAYLOAD" > /dev/null 2>&1
) &

exit "$ALLOW"
