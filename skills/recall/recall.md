# /recall — Search Team Memory

Use when you want to find how the team solved a problem, discovered a pattern, or made a decision. Works across all entries saved by all team members via `/remember`.

**Announce at start:** "Loading /recall. Searching team memory."

---

## Step 1: Get the Query

If the developer typed `/recall <keywords>`, use those keywords directly.

Otherwise ask: "What are you looking for? You can search by: keywords, module name, author, type (`bug-fix`, `pattern`, `decision`, `gotcha`), or just describe the problem."

---

## Step 2: Read Config

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

If `backend` is `graphify` → skip to **Graphify Search** section.

---

## Step 3: Pull Latest (if git remote configured)

```bash
STORE=$(python3 -c "import json,os; c=json.load(open(os.path.expanduser('~/.claude/roambee-config.json'))); print(c.get('memory',{}).get('store', os.path.expanduser('~/.claude/roambee-memory')))")
REMOTE=$(python3 -c "import json,os; c=json.load(open(os.path.expanduser('~/.claude/roambee-config.json'))); print(c.get('memory',{}).get('remote',''))")

if [ -n "$REMOTE" ] && [ -d "$STORE/.git" ]; then
  cd "$STORE" && git pull --quiet origin main 2>/dev/null || echo "(could not pull — using local cache)"
fi

[ ! -d "$STORE" ] && echo "No team memory found. Save learnings first with /remember." && exit 0
```

---

## Step 4: Search and Rank

```bash
python3 << 'EOF'
import os, sys, glob, re

store = os.path.expanduser(
    __import__('json').load(open(os.path.expanduser('~/.claude/roambee-config.json')))
    .get('memory', {}).get('store', os.path.expanduser('~/.claude/roambee-memory'))
)

query = "<query from Step 1>".lower()
terms = query.split()

results = []
for filepath in glob.glob(store + '/**/*.md', recursive=True):
    try:
        content = open(filepath).read()
        content_lower = content.lower()

        # Score: weight title matches higher than body matches
        title_match = next((l.lstrip('# ') for l in content.split('\n') if l.startswith('# ')), '')
        title_score = sum(3 for t in terms if t in title_match.lower())
        tag_score   = sum(2 for t in terms if t in content_lower[:300])  # frontmatter zone
        body_score  = sum(1 for t in terms if t in content_lower)

        score = title_score + tag_score + body_score
        if score == 0:
            continue

        # Parse frontmatter
        fm = {}
        for line in content.split('\n')[1:20]:
            if line == '---': break
            if ': ' in line:
                k, v = line.split(': ', 1)
                fm[k.strip()] = v.strip()

        # First non-heading, non-frontmatter paragraph as preview
        lines = [l for l in content.split('\n') if l and not l.startswith('#') and not l.startswith('---') and ': ' not in l[:30]]
        preview = lines[0][:120] if lines else ''

        results.append({
            'score': score,
            'filepath': filepath,
            'title': title_match,
            'author': fm.get('author', '?'),
            'date': fm.get('date', '?'),
            'type': fm.get('type', '?'),
            'module': fm.get('module', '?'),
            'tags': fm.get('tags', ''),
            'preview': preview,
        })
    except Exception:
        continue

results.sort(key=lambda x: x['score'], reverse=True)

if not results:
    print(f"No matches found for: {query}")
    print("Try broader keywords, or check what's saved with: ls ~/.claude/roambee-memory/**/*.md")
else:
    print(f"Found {len(results)} match(es) for '{query}':\n")
    for i, r in enumerate(results[:5], 1):
        print(f"[{i}] {r['title']}")
        print(f"    {r['author']}  ·  {r['date']}  ·  {r['type']}  ·  {r['module']}")
        print(f"    tags: {r['tags']}")
        print(f"    {r['preview']}")
        print(f"    → {r['filepath']}")
        print()
EOF
```

---

## Step 5: Present Results and Offer to Read

Show the ranked results. Then ask:

"Want me to read any of these in full? Give me the number."

If yes, read the full file and present its content to the developer.

If results are weak (low scores, partial matches), ask: "These are partial matches — try a different keyword? (e.g. the exact error message, the package name, or the author)"

---

## Graphify Search (when backend = "graphify")

When `memory.backend = "graphify"` in `roambee-config.json`:

```bash
ENDPOINT=$(python3 -c "import json,os; c=json.load(open(os.path.expanduser('~/.claude/roambee-config.json'))); print(c['memory']['endpoint'])")
QUERY="<query from Step 1>"

python3 -c "
import urllib.request, urllib.parse, json, os
url = os.environ['ENDPOINT'] + '/memories/search?q=' + urllib.parse.quote(os.environ['QUERY'])
with urllib.request.urlopen(url) as resp:
    results = json.loads(resp.read())
    for r in results.get('entries', [])[:5]:
        print(r['title'], '—', r['author'], r['date'])
        print(r['preview'])
        print()
"
```

_Update the endpoint path, query params, and auth headers to match the graphify API when it's ready. Set `memory.backend = \"graphify\"` and `memory.endpoint = \"<url>\"` in `~/.claude/roambee-config.json`._

---

## Tips

- `/recall typeorm migration` — finds bug fixes involving TypeORM migrations
- `/recall packages/ai` — finds all entries for the AI packages
- `/recall heet` — finds everything saved by Heet
- `/recall bug-fix` — lists all bug fix entries
- No results? The fix might not have been saved yet — ask the person who solved it to run `/remember`
