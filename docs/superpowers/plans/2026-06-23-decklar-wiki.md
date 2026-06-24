# Decklar Wiki Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Wire the Decklar Memory Service into the decklar-claude plugin as a company-wide knowledge wiki — auto-capturing from every Claude Code session and queryable by anyone via `/wiki`.

**Architecture:** A Stop event hook digests the last assistant turn on every response. A PreToolUse hook injects top-5 relevant wiki entries once at session start. The `/wiki` skill exposes recall, save, and decide. The `/init` skill provisions the world and saves user identity. No custom backend — the Memory Service at `https://memory-staging.decklar.com` is the store.

**Tech Stack:** Decklar Memory Service REST API (`/v1/digest`, `/v1/recall`, `/v1/decide`, `/v1/worlds`), bash hooks, Python 3 for JSON, curl for HTTP.

## Global Constraints

- Memory Service base URL: `https://memory-staging.decklar.com`
- World name: `decklar-wiki` (hardcoded — one shared company namespace)
- Auth header: `apikey: <value>` (not `Authorization: Bearer`)
- Account ID header: `x-account-id: <value>`
- `polish` field: **never set** — omit from all payloads
- `wait=false` on all `POST /v1/digest` calls (non-blocking ingest)
- `top_k: 5` in hook-18 recall (session-start latency budget)
- `top_k: 10` in `/wiki` skill recall (user-facing, afford more results)
- Sensitive values stored as **env var names** in `decklar-config.json` (e.g. `"apiKeyEnvVar": "WIKI_API_KEY"`); hooks resolve at runtime via bash indirect expansion `${!VAR_NAME}`
- Config file: `~/.claude/decklar-config.json`
- All hooks source `$HOME/decklar-claude/hooks/lib.sh`
- Use `python3` for JSON (not `jq`) — matches existing hook convention
- hook-17 fires on **every** Stop turn — digests last assistant turn only, never the full transcript, no `told_this_session` dedup
- hook-18 fires on **first** PreToolUse per session only — `told_this_session` dedup

---

## File Map

| File | Action | Responsibility |
|---|---|---|
| `docs/decklar-config-schema.json` | Modify | Add `wiki` config block |
| `docs/hooks-settings-patch.json` | Modify | Register hook-17 (Stop) and hook-18 (PreToolUse) |
| `hooks/hook-17-wiki-capture.sh` | Create | Digest last assistant turn to decklar-wiki on every Stop |
| `hooks/hook-18-wiki-inject.sh` | Create | Recall top-5 wiki entries and inject at session start |
| `skills/wiki/wiki.md` | Create | `/wiki` skill — recall, save, decide subcommands |
| `skills/init/init.md` | Modify | Add Step 8: wiki setup (agent name, env var check, world creation) |
| `docs/wiki-project-instructions.md` | Create | Claude.ai project instructions template for non-engineers |

---

### Task 1: Config Schema + /init Wiki Setup Step

**Files:**
- Modify: `docs/decklar-config-schema.json`
- Modify: `skills/init/init.md`

**Interfaces:**
- Produces: `wiki` block readable by `config_get "wiki" "<key>"` in hooks
- Produces: `/init` Step 8 that populates the wiki config block and creates the world

- [ ] **Step 1: Add `wiki` block to config schema**

Open `docs/decklar-config-schema.json` and add the following inside the top-level `"properties"` object, after the `"memory"` block:

```json
"wiki": {
  "type": "object",
  "description": "Decklar Wiki config used by hook-17, hook-18, and /wiki. Populated by /init Step 8.",
  "properties": {
    "endpoint": {
      "type": "string",
      "description": "Memory Service base URL. e.g. https://memory-staging.decklar.com"
    },
    "worldName": {
      "type": "string",
      "description": "Memory world name. Always decklar-wiki."
    },
    "agentName": {
      "type": "string",
      "description": "User identity in the wiki world. A clean human name blob, e.g. heet or heet-shah."
    },
    "apiKeyEnvVar": {
      "type": "string",
      "description": "Name of the env var holding the API key, e.g. WIKI_API_KEY"
    },
    "accountIdEnvVar": {
      "type": "string",
      "description": "Name of the env var holding the account ID, e.g. WIKI_ACCOUNT_ID"
    }
  }
}
```

- [ ] **Step 2: Verify schema is valid JSON**

```bash
python3 -c "import json; json.load(open('docs/decklar-config-schema.json')); print('valid')"
```

Expected output: `valid`

- [ ] **Step 3: Add Step 8 to `skills/init/init.md`**

Append the following before the final `## Step 7: Summary` section (renumber Summary to Step 9 if desired, or just append as Step 8 after the existing summary):

````markdown
---

## Step 8: Decklar Wiki Setup

Ask the developer: **"What's your name for the wiki? (e.g. heet, heet-shah — this is your identity in the shared company knowledge base)"**

Save wiki config to `~/.claude/decklar-config.json`:

```bash
python3 -c "
import json, os
p = os.path.expanduser('~/.claude/decklar-config.json')
d = {}
try: d = json.load(open(p))
except: pass
d['wiki'] = {
    'endpoint': 'https://memory-staging.decklar.com',
    'worldName': 'decklar-wiki',
    'agentName': '<AGENT_NAME>',
    'apiKeyEnvVar': 'WIKI_API_KEY',
    'accountIdEnvVar': 'WIKI_ACCOUNT_ID'
}
json.dump(d, open(p, 'w'), indent=2)
print('Wiki config saved.')
"
```

Verify the required env vars are set:

```bash
python3 -c "
import os
missing = []
if not os.environ.get('WIKI_API_KEY'): missing.append('WIKI_API_KEY')
if not os.environ.get('WIKI_ACCOUNT_ID'): missing.append('WIKI_ACCOUNT_ID')
if missing:
    print('MISSING:', ' '.join(missing))
    print('Add these to your shell profile (~/.zshrc or ~/.bash_profile) and restart your terminal.')
else:
    print('ENV OK')
"
```

If `MISSING` is printed, tell the developer to add the env vars to their shell profile and re-run `/init`. Do not proceed to world creation until `ENV OK`.

Create the `decklar-wiki` world if it does not exist:

```bash
python3 -c "
import json, os, subprocess, sys

endpoint = 'https://memory-staging.decklar.com'
api_key = os.environ.get('WIKI_API_KEY', '')
account_id = os.environ.get('WIKI_ACCOUNT_ID', '')

if not api_key or not account_id:
    print('Skipping world creation — env vars not set.')
    sys.exit(0)

# Check if world already exists
r = subprocess.run([
    'curl', '-s',
    f'{endpoint}/v1/worlds?account_id={account_id}&is_active=true',
    '-H', f'apikey: {api_key}',
    '-H', f'x-account-id: {account_id}'
], capture_output=True, text=True)

try:
    worlds = json.loads(r.stdout)
    worlds = worlds if isinstance(worlds, list) else worlds.get('worlds', worlds.get('items', []))
    names = [w.get('world_name', '') for w in worlds if isinstance(w, dict)]
    if 'decklar-wiki' in names:
        print('World decklar-wiki already exists — skipping creation.')
        sys.exit(0)
except:
    pass

# Create world
payload = json.dumps({
    'account_id': account_id,
    'world_name': 'decklar-wiki',
    'description': 'Decklar company knowledge base',
    'is_active': True
})
r = subprocess.run([
    'curl', '-s', '-X', 'POST', f'{endpoint}/v1/worlds',
    '-H', f'apikey: {api_key}',
    '-H', f'x-account-id: {account_id}',
    '-H', 'Content-Type: application/json',
    '-d', payload
], capture_output=True, text=True)

print('World created:', r.stdout[:200] if r.stdout else r.stderr[:200])
"
```

Tell the developer:
```
✅ Decklar Wiki configured.
   World: decklar-wiki
   Agent name: <AGENT_NAME>
   hook-17 will digest your sessions automatically.
   hook-18 will inject wiki context at session start.
   Use /wiki to query or save knowledge manually.
```
````

- [ ] **Step 4: Commit**

```bash
git add docs/decklar-config-schema.json skills/init/init.md
git commit -m "feat: add wiki config schema and /init setup step"
```

---

### Task 2: hook-17-wiki-capture.sh (Stop event — auto-digest)

**Files:**
- Create: `hooks/hook-17-wiki-capture.sh`
- Modify: `docs/hooks-settings-patch.json`

**Interfaces:**
- Consumes: Stop event JSON on stdin with `transcript` array (Claude Code injects this)
- Consumes: `config_get "wiki" "endpoint"`, `config_get "wiki" "apiKeyEnvVar"`, `config_get "wiki" "accountIdEnvVar"`, `config_get "wiki" "agentName"`, `config_get "wiki" "worldName"`
- Produces: `POST /v1/digest` call per assistant turn, background, fire-and-forget

- [ ] **Step 1: Create `hooks/hook-17-wiki-capture.sh`**

```bash
#!/usr/bin/env bash
# Hook 17: Wiki capture — digests last assistant turn to decklar-wiki on every Stop.
source "$HOME/decklar-claude/hooks/lib.sh"

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
```

- [ ] **Step 2: Make hook executable**

```bash
chmod +x hooks/hook-17-wiki-capture.sh
```

- [ ] **Step 3: Add Stop event entry to `docs/hooks-settings-patch.json`**

Add a `"Stop"` key to the top-level JSON object (alongside existing `"PreToolUse"` and `"PostToolUse"`):

```json
"Stop": [
  {
    "matcher": ".*",
    "command": "$HOME/decklar-claude/hooks/hook-17-wiki-capture.sh"
  }
]
```

The full `docs/hooks-settings-patch.json` structure becomes:

```json
{
  "_comment": "...",
  "PreToolUse": [ ... existing entries ... ],
  "PostToolUse": [ ... existing entries ... ],
  "Stop": [
    {
      "matcher": ".*",
      "command": "$HOME/decklar-claude/hooks/hook-17-wiki-capture.sh"
    }
  ]
}
```

- [ ] **Step 4: Verify hooks-settings-patch.json is valid JSON**

```bash
python3 -c "import json; json.load(open('docs/hooks-settings-patch.json')); print('valid')"
```

Expected output: `valid`

- [ ] **Step 5: Commit**

```bash
git add hooks/hook-17-wiki-capture.sh docs/hooks-settings-patch.json
git commit -m "feat: add hook-17 wiki capture on Stop event"
```

---

### Task 3: hook-18-wiki-inject.sh (PreToolUse — session-start context injection)

**Files:**
- Create: `hooks/hook-18-wiki-inject.sh`
- Modify: `docs/hooks-settings-patch.json`

**Interfaces:**
- Consumes: same config keys as hook-17
- Produces: stdout context block injected into Claude's context window (Claude reads `echo` output from hooks)
- Dedup: `told_this_session "hook-18-wiki-inject"` — fires only once per session

- [ ] **Step 1: Create `hooks/hook-18-wiki-inject.sh`**

```bash
#!/usr/bin/env bash
# Hook 18: Wiki inject — fetches top-5 wiki entries and injects at session start.
# Fires once per session via told_this_session dedup.
source "$HOME/decklar-claude/hooks/lib.sh"

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

RESPONSE=$(curl -s -X POST "$ENDPOINT/v1/recall" \
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
        items = data.get('results', data.get('items', data.get('memories', [])))
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
```

- [ ] **Step 2: Make hook executable**

```bash
chmod +x hooks/hook-18-wiki-inject.sh
```

- [ ] **Step 3: Add hook-18 to PreToolUse in `docs/hooks-settings-patch.json`**

Insert as the **first** entry in the `"PreToolUse"` array (fires before other checks so wiki context is available early):

```json
{
  "matcher": ".*",
  "command": "$HOME/decklar-claude/hooks/hook-18-wiki-inject.sh"
}
```

- [ ] **Step 4: Verify hooks-settings-patch.json is valid JSON**

```bash
python3 -c "import json; json.load(open('docs/hooks-settings-patch.json')); print('valid')"
```

Expected output: `valid`

- [ ] **Step 5: Commit**

```bash
git add hooks/hook-18-wiki-inject.sh docs/hooks-settings-patch.json
git commit -m "feat: add hook-18 wiki context injection at session start"
```

---

### Task 4: /wiki Skill

**Files:**
- Create: `skills/wiki/wiki.md`

**Interfaces:**
- Consumes: `~/.claude/decklar-config.json` `wiki.*` block
- Produces: user-facing recall, save (digest), and decide flows

- [ ] **Step 1: Create `skills/wiki/wiki.md`**

```markdown
# /wiki — Decklar Company Knowledge Base

Query, save, and reason over shared Decklar knowledge stored in the Memory Service.

**Announce at start:** "Using /wiki."

---

## Config Check

Before any operation, read wiki config:

```bash
python3 -c "
import json, os
p = os.path.expanduser('~/.claude/decklar-config.json')
try:
    d = json.load(open(p))
    w = d.get('wiki', {})
    print(w.get('endpoint',''), w.get('agentName',''), w.get('worldName',''), w.get('apiKeyEnvVar',''), w.get('accountIdEnvVar',''))
except:
    print('', '', '', '', '')
"
```

If `endpoint` is empty: tell the user **"Wiki not configured — run `/init` to set up."** and stop.

Resolve API key and account ID from the env var names:
- `API_KEY` = value of the env var named by `apiKeyEnvVar`
- `ACCOUNT_ID` = value of the env var named by `accountIdEnvVar`

If either is empty: **"Wiki credentials not set — check that WIKI_API_KEY and WIKI_ACCOUNT_ID are exported in your shell."**

---

## Subcommands

### /wiki \<query\>

Search the wiki for `<query>`. If no query given, ask: "What are you looking for?"

```bash
curl -s -X POST "$ENDPOINT/v1/recall" \
  -H "apikey: $API_KEY" \
  -H "x-account-id: $ACCOUNT_ID" \
  -H "Content-Type: application/json" \
  -d '{
    "account_id": "'"$ACCOUNT_ID"'",
    "world_name": "decklar-wiki",
    "query": "'"$QUERY"'",
    "top_k": 10
  }'
```

Parse the response — items may be in a top-level array or under a `results`/`items`/`memories` key. For each result, show:
- The content (truncated to 400 chars if long)
- Agent name (who contributed it) if available in the response
- Score/relevance if available

If no results: **"Nothing found for '\<query\>' yet. Someone needs to save it with `/wiki save`."**

---

### /wiki save

Guided deliberate capture flow. Sets `agent_name` to the configured name.

Ask in sequence:
1. **"What's the entity or topic?"** (e.g. "Radar product", "Priya Mehta", "on-call escalation process")
2. **"What do you want to save about it?** (be specific — the more concrete, the better)"
3. **"Any tags? (comma-separated, optional)"**

Build content string:
```
## <entity>
<facts>
tags: <tags>
```

POST to digest:

```bash
curl -s -X POST "$ENDPOINT/v1/digest?wait=false" \
  -H "apikey: $API_KEY" \
  -H "x-account-id: $ACCOUNT_ID" \
  -H "Content-Type: application/json" \
  -d '{
    "account_id": "'"$ACCOUNT_ID"'",
    "world_name": "decklar-wiki",
    "agent_name": "'"$AGENT_NAME"'",
    "content": "'"$CONTENT"'"
  }'
```

Confirm: **"Saved to decklar-wiki. Others can find it with `/wiki <entity name or tag>`."**

---

### /wiki decide \<question\>

Use the Memory Service's reasoning endpoint to answer a question using recalled wiki knowledge.

If no question given, ask: "What do you need to decide or understand?"

```bash
curl -s -X POST "$ENDPOINT/v1/decide" \
  -H "apikey: $API_KEY" \
  -H "x-account-id: $ACCOUNT_ID" \
  -H "Content-Type: application/json" \
  -d '{
    "account_id": "'"$ACCOUNT_ID"'",
    "world_name": "decklar-wiki",
    "agent_name": "'"$AGENT_NAME"'",
    "query": "'"$QUESTION"'",
    "objective": "'"$QUESTION"'",
    "top_k": 10
  }'
```

Present the response directly. If empty or error: fall back to `/wiki <question>` recall and reason over it yourself.

---

## Examples

- `/wiki Radar` — what is the Radar product?
- `/wiki who owns the Logistics service` — team/person lookup
- `/wiki save` — guided capture of something just discussed
- `/wiki decide should we use graphiti or hindsight adapter` — reasoned answer from wiki knowledge
```

- [ ] **Step 2: Verify skill file exists**

```bash
ls skills/wiki/wiki.md
```

Expected: file listed.

- [ ] **Step 3: Commit**

```bash
git add skills/wiki/wiki.md
git commit -m "feat: add /wiki skill for recall, save, and decide"
```

---

### Task 5: Claude.ai Project Instructions Template

**Files:**
- Create: `docs/wiki-project-instructions.md`

**Interfaces:**
- Consumes: graphify MCP server connected to Claude.ai (IT setup step — outside this plugin)
- Produces: project instructions template that non-engineers paste into their Claude.ai Decklar project

- [ ] **Step 1: Create `docs/wiki-project-instructions.md`**

```markdown
# Decklar Wiki — Claude.ai Project Instructions

Copy the text below into your **Decklar Claude.ai project's instructions**
(Project → Instructions → Edit). Prerequisites: the graphify MCP server must
be connected to your Claude.ai account (ask IT or see internal Notion setup guide).

---

## Instructions to paste

You are a Decklar assistant with access to the company knowledge base via the Memory Service MCP tools (wiki_search, wiki_save).

**At the start of every conversation:**
1. Call `wiki_search` with the user's first message as the query, world_name `decklar-wiki`, top_k 5.
2. Use the results as background context before responding. Do not show the raw results — just let them inform your answer.

**During the conversation:**
Whenever you learn something new and concrete about a Decklar entity — a product, person, team, customer, integration, process, term, competitor, or decision — silently call `wiki_save` to record it. Use:
- `world_name`: `decklar-wiki`
- `agent_name`: the user's first name (ask once at conversation start if unknown)
- `content`: a clear, factual markdown summary of what was shared
- Do NOT save vague statements or opinions — only specific, reusable facts.

**For explicit queries like "what do you know about X" or "look up X":**
Call `wiki_search` with X as the query and present the results clearly.

**For decisions or reasoning:** Call `wiki_decide` with the question as both `query` and `objective`.
```

- [ ] **Step 2: Commit**

```bash
git add docs/wiki-project-instructions.md
git commit -m "docs: add Claude.ai wiki project instructions template"
```

---

## Self-Review

**Spec coverage check:**

| Spec requirement | Task |
|---|---|
| Memory Service as backend | Global Constraints |
| `world_name = decklar-wiki` | Global Constraints |
| `agent_name` = user's semantic name blob | Task 1 Step 3 (/init), hook-17, hook-18 |
| `polish` = off | Global Constraints (omitted from all payloads) |
| `wait=false` on digest | Global Constraints + hook-17 + /wiki save |
| Config stored in decklar-config.json | Task 1 |
| Config schema documented | Task 1 |
| Auto-capture from Claude Code sessions | Task 2 (hook-17) |
| Context injection at session start | Task 3 (hook-18) |
| `/wiki` explicit query | Task 4 |
| `/wiki save` explicit capture | Task 4 |
| `/wiki decide` reasoning | Task 4 |
| `/init` provisions world, sets agent name | Task 1 Step 3 |
| Claude.ai non-engineer path | Task 5 |
| Env vars for secrets (never hardcoded) | Global Constraints + all tasks |

**No placeholders found.**

**Type consistency:** `config_get "wiki" "<key>"` used consistently across hook-17, hook-18, and /wiki. World name `decklar-wiki` hardcoded identically in all locations. Env var indirection (`${!VAR}`) used in hooks; Python `os.environ.get()` used in /init and /wiki.
