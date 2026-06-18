# /create-skill — Roambee Skill Creator

Use when a developer wants to write a new Claude Code skill for the Roambee plugin.

**Announce at start:** "Loading create-skill. Let's build a new Roambee skill."

---

## Step 1: Gather the Skill Definition

Ask the developer these questions one at a time:

1. **Name:** "What should the skill be called? Use kebab-case (e.g. `db-seed`, `hotfix`, `env-check`)."
2. **Trigger:** "When would a developer type `/<name>`? What problem does this solve?"
3. **Workflow:** "Walk me through what Claude should do, step by step, when this skill runs."
4. **Audience:** "Is this for app devs, AI devs, or everyone? Any prerequisites (e.g. must have Jira auth)?"

---

## Step 2: Check for Duplicates

Before writing anything:

```bash
ls skills/
```

If a similar skill already exists, read it and ask: "There's already a `/<existing>` skill that does X — should we extend that one instead?"

---

## Step 3: Draft the Skill

Write a draft using this exact format — every Roambee skill follows it:

```markdown
# /<name> — <One-line title>

<One sentence: what this does and who uses it.>

**Announce at start:** "<Short confirmation message so the developer knows the skill loaded.>"

---

## Step 1: ...

## Step 2: ...
```

**Rules for each step:**
- Every step must have concrete content: a bash command, an MCP tool call, a code snippet, or an explicit question to ask the user
- No placeholder steps like "implement the logic" or "handle the response" — show the actual command or code
- If the skill touches Jira, use `mcp__claude_ai_Atlassian__*` tools (reference `/plan` or `/pr` for examples)
- If the skill reads config, use `~/.claude/roambee-config.json` via `python3 -c "import json,os; ..."`
- If the skill references Jira tickets, extract them with `grep -oE 'RMB-[0-9]+'`

**Good skill reference examples to read for format:**
- Simple workflow: `skills/standup/standup.md`
- Jira-integrated: `skills/pr/pr.md`
- AI-specific: `skills/provider-abstraction/provider-abstraction.md`

---

## Step 4: Review With the Developer

Read the draft back and ask:

"Here's the skill draft. Does this match what you had in mind? Anything to add, change, or remove?"

Iterate until the developer approves.

---

## Step 5: Write the File

```bash
mkdir -p skills/<name>
```

Write `skills/<name>/<name>.md` with the approved content.

Verify:
```bash
cat skills/<name>/<name>.md | head -5
```

---

## Step 6: Quick Sanity Check

Mentally simulate: if a developer types `/<name>` right now, would Claude know exactly what to do at every step? If any step is ambiguous or references something undefined, fix it before committing.

---

## Step 7: Commit

```bash
git add skills/<name>/
git commit -m "feat: add <name> skill"
```

---

## Step 8: Offer to Contribute

Ask: "This skill is now available locally. Would you like to contribute it to `Roambee/claude-code-standards` so all engineers get it automatically? If yes, run `/contribute-skill`."
