# /recall — Search Team Memory

Use when you want to find how the team solved a problem, discovered a pattern, or made a decision in a previous session. Searches across all sessions and all team members via claude-mem.

**Announce at start:** "Loading /recall. Searching team memory."

---

## Step 1: Get the Query

If the developer typed `/recall <keywords>`, use those keywords directly.

Otherwise ask: "What are you looking for? You can use keywords, a module name, an author name, or describe the problem."

---

## Step 2: Search — Get the Index

Call `mcp__plugin_claude-mem_mcp-search__search` with the query.

Use `obs_type` to narrow by learning type when the developer specifies one:

| Developer says | obs_type value |
|----------------|---------------|
| "bug fix", "how we fixed" | `bugfix` |
| "pattern", "approach", "how we do" | `feature` |
| "decision", "why we chose" | `decision` |
| "gotcha", "trap", "watch out" | `discovery` |
| _(no type specified)_ | _(omit — search all)_ |

Example calls:
```
search(query="typeorm migration deadlock", limit=20)
search(query="openrouter retry", obs_type="bugfix", limit=20)
search(query="packages/ai/classifier", limit=20)
search(query="heet shah auth", limit=20)
```

This returns a table of IDs, timestamps, and titles at ~50-100 tokens per result. **Do not fetch full details yet.**

---

## Step 3: Timeline — Get Context Around Interesting Hits

For any result that looks relevant, call `mcp__plugin_claude-mem_mcp-search__timeline` to see what was happening around it:

```
timeline(anchor=<ID>, depth_before=3, depth_after=3)
```

This surfaces the session context around that observation — useful for understanding the full picture of how something was solved.

---

## Step 4: Fetch — Read Full Details for Selected Entries

After reviewing the index and timeline, pick the most relevant IDs. Fetch them all in one call:

```
get_observations(ids=[<id1>, <id2>, ...])
```

Never fetch more than you need — each observation is 500–1000 tokens.

---

## Step 5: Present Results

Show the developer:
- What was found (title, author, date, module)
- The key facts from the observation — problem, root cause, fix, or pattern
- Any related observations from the timeline that add context

If nothing relevant was found, say: "No matches for '<query>'. This might not have been saved yet — ask the person who solved it to run `/remember` in their next session, or try different keywords."

---

## Tips

- `/recall typeorm migration` — finds past TypeORM issues
- `/recall packages/ai` — finds all entries touching the AI packages
- `/recall heet` — finds everything from Heet's sessions
- `/recall bug-fix auth` — finds auth bug fixes across all sessions

> **Note for when graphify/hindsight is ready:** Replace Steps 2–4 with a GET to the graphify search API. Update `memory.backend` and `memory.endpoint` in `~/.claude/decklar-config.json`.
