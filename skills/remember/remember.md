# /remember — Save a Team Learning to Shared Memory

Use after solving a bug, discovering a reusable pattern, making a decision, or hitting a non-obvious gotcha. Saves the learning in a structured format the whole team can search.

**Announce at start:** "Loading /remember. Let's capture this for the team."

---

## Step 1: Read Backend Config

```bash
python3 -c "
import json, os
cfg_path = os.path.expanduser('~/.claude/roambee-config.json')
cfg = json.load(open(cfg_path)) if os.path.exists(cfg_path) else {}
mem = cfg.get('memory', {})
print('backend:', mem.get('backend', 'local'))
print('store:',   mem.get('store',   os.path.expanduser('~/.claude/roambee-memory')))
print('remote:',  mem.get('remote',  ''))
print('endpoint:', mem.get('endpoint', ''))
"
```

- If `backend` is `graphify` → skip to **Step 5**
- Otherwise continue (local file + optional git sync)

---

## Step 2: Collect the Learning

Ask the developer these questions:

1. **Title:** "One-line title — what did you solve or discover?"

2. **Type:** "What kind of learning is this?"

   | Type | Use when |
   |------|----------|
   | `bug-fix` | You fixed something broken |
   | `pattern` | A reusable approach worth repeating |
   | `decision` | A choice made with reasoning |
   | `gotcha` | A non-obvious trap to avoid |

3. **Module:** "Which service or package does this relate to? (e.g. `packages/api/auth`, `packages/ai/classifier`, `packages/web/shipments`)"

4. **Tags:** "Keywords someone might search for, comma-separated. (e.g. `typeorm, migration, deadlock, postgres`)"

5. **Content** — ask for the relevant sections based on type:

   **bug-fix:**
   - "Describe the problem — what was the symptom?"
   - "What was the root cause?"
   - "What was the fix? Include the key code or command."
   - "Any gotchas or things to watch for next time?"

   **pattern:**
   - "When should someone use this pattern?"
   - "Describe the pattern — how does it work?"
   - "Show an example (code or commands)."
   - "What are the tradeoffs?"

   **decision:**
   - "What was decided?"
   - "Why was this decision made?"
   - "What alternatives were considered and why rejected?"
   - "What does this constrain or enable going forward?"

   **gotcha:**
   - "Describe the trap — what happens if you fall into it?"
   - "Why does it happen?"
   - "How do you avoid or recover from it?"

---

## Step 3: Initialise the Store (first run only)

```bash
STORE=$(python3 -c "import json,os; c=json.load(open(os.path.expanduser('~/.claude/roambee-config.json'))); print(c.get('memory',{}).get('store', os.path.expanduser('~/.claude/roambee-memory')))")
REMOTE=$(python3 -c "import json,os; c=json.load(open(os.path.expanduser('~/.claude/roambee-config.json'))); print(c.get('memory',{}).get('remote',''))")

mkdir -p "$STORE/bug-fix" "$STORE/pattern" "$STORE/decision" "$STORE/gotcha"

if [ ! -d "$STORE/.git" ] && [ -n "$REMOTE" ]; then
  cd "$STORE"
  git init -q
  git remote add origin "$REMOTE"
  git pull origin main --quiet 2>/dev/null || true
fi
```

---

## Step 4: Write the Entry File

```bash
AUTHOR=$(git config user.name 2>/dev/null || echo "unknown")
DATE=$(date +%Y-%m-%d)
TYPE="<type from step 2>"
SLUG=$(echo "<title from step 2>" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd '[:alnum:]-' | cut -c1-50)
FILEPATH="$STORE/$TYPE/$DATE-$SLUG.md"
```

Write the file with this structure — the `related: []` field is intentionally empty for now; it becomes graph edges when the graphify backend is connected:

```markdown
---
id: <DATE>-<SLUG>
author: <AUTHOR>
date: <DATE>
type: <TYPE>
module: <MODULE>
tags: [<TAGS>]
related: []
---

# <TITLE>

<Sections from Step 2, formatted with ## headings appropriate to the type>
```

Verify the file was written:
```bash
head -8 "$FILEPATH"
```

---

## Step 5: Sync to Team (if git remote configured)

```bash
REMOTE=$(python3 -c "import json,os; c=json.load(open(os.path.expanduser('~/.claude/roambee-config.json'))); print(c.get('memory',{}).get('remote',''))")

if [ -n "$REMOTE" ]; then
  cd "$STORE"
  git add "$FILEPATH"
  git commit -q -m "mem: add $TYPE — $SLUG (by $AUTHOR)"
  git push -q origin main
  echo "Pushed to team memory remote."
fi
```

---

## Step 5 (graphify): POST to Graphify Backend

When `memory.backend = "graphify"` in `roambee-config.json`, skip the file write above and POST the structured entry instead:

```bash
ENDPOINT=$(python3 -c "import json,os; c=json.load(open(os.path.expanduser('~/.claude/roambee-config.json'))); print(c['memory']['endpoint'])")

python3 -c "
import json, os, urllib.request, datetime

entry = {
    'id':      '<DATE>-<SLUG>',
    'author':  '<AUTHOR>',
    'date':    '<DATE>',
    'type':    '<TYPE>',
    'module':  '<MODULE>',
    'tags':    [<TAGS as list>],
    'related': [],
    'title':   '<TITLE>',
    'content': '<full markdown content>'
}

req = urllib.request.Request(
    os.environ['ENDPOINT'] + '/memories',
    data=json.dumps(entry).encode(),
    headers={'Content-Type': 'application/json'},
    method='POST'
)
with urllib.request.urlopen(req) as resp:
    print('Saved to graphify:', resp.read().decode())
"
```

_Update the endpoint path and auth headers to match the graphify API when it's ready. Set `memory.backend = \"graphify\"` and `memory.endpoint = \"<url>\"` in `~/.claude/roambee-config.json`._

---

## Step 6: Confirm

Tell the developer:

```
✅ Saved: $FILEPATH
   by <AUTHOR> · <DATE> · <TYPE> · <MODULE>

Search it later with: /recall <keyword>
Anyone on the team can find it with the same command.
```
