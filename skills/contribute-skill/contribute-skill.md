# /contribute-skill — Submit a Skill to the Shared Plugin

Use when a developer wants to contribute a skill to `Roambee/claude-code-standards` so all engineers get it.

**Announce at start:** "Loading contribute-skill. Let's get your skill into the shared plugin."

---

## Step 1: Identify the Skill

Ask: "Which skill are you contributing? Give me the directory name (e.g. `hotfix`, `db-seed`)."

Check it exists:
```bash
ls skills/<name>/
cat skills/<name>/<name>.md | head -10
```

If it doesn't exist yet: "Run `/create-skill` first, then come back here."

---

## Step 2: Contribution Checklist

Before opening a PR, verify every item:

- [ ] **Reusable** — useful across multiple teams, not specific to one service or project
- [ ] **Concrete steps** — every step has actual commands or code, no placeholders
- [ ] **Announce at start** — the skill has a confirmation message on load
- [ ] **Roambee-aware** — references correct tools/paths (`mcp__claude_ai_Atlassian__*`, `~/.claude/roambee-config.json`, `RMB-XXXX`) where relevant
- [ ] **No duplicate** — doesn't replicate an existing skill in the plugin

```bash
# Quick duplicate check
ls skills/
```

If any item is unchecked, fix the skill first.

---

## Step 3: Create a Contribution Branch

```bash
SKILL_NAME=<name>
git checkout main
git pull origin main
git checkout -b skill/contribute-$SKILL_NAME
```

---

## Step 4: Stage, Commit, Push

```bash
git add skills/<name>/
git commit -m "feat: add <name> skill"
git push -u origin skill/contribute-<name>
```

---

## Step 5: Open the Pull Request

Ask the developer:
1. "One line — when would someone type `/<name>`? (This goes in the PR description.)"
2. "Two to three sentences — what does this skill do step by step?"
3. "Who benefits most: app devs, AI devs, or all engineers?"

Then open the PR:

```bash
gh pr create \
  --repo Roambee/claude-code-standards \
  --base main \
  --head skill/contribute-<name> \
  --title "feat: add <name> skill" \
  --body "$(cat <<'EOF'
## New skill: `/<name>`

**Trigger:** <one-line: when a developer would invoke this>

**What it does:**
<2-3 sentences describing the step-by-step workflow>

**Who benefits:** <app devs / AI devs / all engineers>

**Tested by:** <contributor name>

---
*Submitted via `/contribute-skill`*
EOF
)"
```

---

## Step 6: Share for Review

After the PR is open, share the URL with the plugin maintainer for review. Once merged into `main`, all engineers get the skill automatically on the next Claude Code marketplace sync — no action needed on their end.
