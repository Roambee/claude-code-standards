# /wiki — Decklar Company Knowledge Base

Query, save, and reason over shared Decklar knowledge stored in the Memory Service.

**Announce at start:** "Using /wiki."

---

## Config Check

Before any operation, read wiki config and assign shell variables:

```bash
read -r ENDPOINT AGENT_NAME WORLD_NAME API_KEY_VAR ACCOUNT_ID_VAR <<< "$(python3 -c "
import json, os
p = os.path.expanduser('~/.claude/roambee-config.json')
try:
    d = json.load(open(p))
    w = d.get('wiki', {})
    print(w.get('endpoint',''), w.get('agentName',''), w.get('worldName',''), w.get('apiKeyEnvVar',''), w.get('accountIdEnvVar',''))
except:
    print('', '', '', '', '')
")"
```

If `ENDPOINT` is empty: tell the user **"Wiki not configured — run `/init` to set up."** and stop.

Resolve API key and account ID from the env var names:

```bash
API_KEY=$(eval echo "\$$API_KEY_VAR")
ACCOUNT_ID=$(eval echo "\$$ACCOUNT_ID_VAR")
[ -z "$API_KEY" ] && { echo "Wiki credentials not set — check WIKI_API_KEY is exported in your shell."; exit 1; }
[ -z "$ACCOUNT_ID" ] && { echo "Wiki credentials not set — check WIKI_ACCOUNT_ID is exported in your shell."; exit 1; }
```

---

## Subcommands

### /wiki \<query\>

Search the wiki for `<query>`. If no query given, ask: "What are you looking for?"

```bash
PAYLOAD=$(python3 -c "
import json, sys
query = sys.stdin.read().strip()
print(json.dumps({
    'account_id': '$ACCOUNT_ID',
    'world_name': '$WORLD_NAME',
    'query': query,
    'top_k': 10
}))
" <<< "$QUERY")
curl -s -X POST "$ENDPOINT/v1/recall" \
  -H "apikey: $API_KEY" \
  -H "x-account-id: $ACCOUNT_ID" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD"
```

Parse the response — items may be in a top-level array or under a `data`/`results`/`items`/`memories` key. For each result, show:
- The content (truncated to 400 chars if long)
- Agent name (who contributed it) if available in the response
- Score/relevance if available

If no results: **"Nothing found for '\<query\>' yet. Someone needs to save it with `/wiki save`."**

---

### /wiki save

Guided deliberate capture flow. Sets `agent_name` to the configured name.

Ask in sequence:
1. **"What's the entity or topic?"** (e.g. "Radar product", "Priya Mehta", "on-call escalation process")
2. **"What do you want to save about it? (be specific — the more concrete, the better)"**
3. **"Any tags? (comma-separated, optional)"**

Build content string:
```
## <entity>
<facts>
tags: <tags>
```

POST to digest:

```bash
PAYLOAD=$(python3 -c "
import json, sys
content = sys.stdin.read().strip()
print(json.dumps({
    'account_id': '$ACCOUNT_ID',
    'world_name': '$WORLD_NAME',
    'agent_name': '$AGENT_NAME',
    'content': content
}))
" <<< "$CONTENT")
curl -s -X POST "$ENDPOINT/v1/digest?wait=false" \
  -H "apikey: $API_KEY" \
  -H "x-account-id: $ACCOUNT_ID" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD"
```

Confirm: **"Saved to $WORLD_NAME. Others can find it with `/wiki <entity name or tag>`."**

---

### /wiki decide \<question\>

Use the Memory Service's reasoning endpoint to answer a question using recalled wiki knowledge.

If no question given, ask: "What do you need to decide or understand?"

```bash
PAYLOAD=$(python3 -c "
import json, sys
question = sys.stdin.read().strip()
print(json.dumps({
    'account_id': '$ACCOUNT_ID',
    'world_name': '$WORLD_NAME',
    'agent_name': '$AGENT_NAME',
    'query': question,
    'objective': question,
    'top_k': 10
}))
" <<< "$QUESTION")
curl -s -X POST "$ENDPOINT/v1/decide" \
  -H "apikey: $API_KEY" \
  -H "x-account-id: $ACCOUNT_ID" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD"
```

Present the response directly. If empty or error: fall back to `/wiki <question>` recall and reason over it yourself.

---

## Examples

- `/wiki Radar` — what is the Radar product?
- `/wiki who owns the Logistics service` — team/person lookup
- `/wiki save` — guided capture of something just discussed
- `/wiki decide should we use graphiti or hindsight adapter` — reasoned answer from wiki knowledge
