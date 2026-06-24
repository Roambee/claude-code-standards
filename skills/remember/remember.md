# /remember — Capture a Team Learning

Use after solving a bug, discovering a pattern, making a decision, or hitting a non-obvious gotcha. Formats the learning so claude-mem captures it at session end and the whole team can find it later with `/recall`.

**Announce at start:** "Loading /remember. Let's capture this for the team."

---

## Step 1: Collect the Learning

Ask the developer these questions:

1. **Title:** "One-line title — what did you solve or discover?"

2. **Type:** "What kind of learning is this?"

   | Type | Use when |
   |------|----------|
   | `bug-fix` | You fixed something broken |
   | `pattern` | A reusable approach worth repeating |
   | `decision` | A choice made with reasoning |
   | `gotcha` | A non-obvious trap to avoid |

3. **Module:** "Which service or package does this relate to? (e.g. `packages/api/auth`, `packages/ai/classifier`)"

4. **Tags:** "Keywords someone might search for, comma-separated. (e.g. `typeorm, migration, deadlock, postgres`)"

5. **Content** — ask for the relevant sections based on type:

   **bug-fix:** Problem → Root cause → Fix (include the key code or command) → Watch-outs
   **pattern:** When to use → How it works → Example → Tradeoffs
   **decision:** What was decided → Why → Alternatives rejected → Consequences
   **gotcha:** The trap → Why it happens → How to avoid or recover

---

## Step 2: Output the Structured Learning

Format the collected content as a clearly marked block so claude-mem's session capture picks it up with high signal:

```
━━━ TEAM LEARNING ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Type:   <type>
Module: <module>
Tags:   <tags>
Author: <git config user.name>

## <Title>

### <Section headings appropriate to the type>
<Content>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Step 3: Confirm

Tell the developer:

```
✅ Learning captured in this session.

claude-mem will index it when this session ends.
Anyone on the team can find it with:

  /recall <any of your tags or keywords>

For example: /recall <first tag from above>
```

> **Note for when graphify/hindsight is ready:** Replace Step 2's output block with a POST to the graphify API. The schema (type, module, tags, title, content) is already structured for import. Update `memory.backend` and `memory.endpoint` in `~/.claude/decklar-config.json` at that point.
