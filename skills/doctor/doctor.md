# /doctor — Roambee Setup Health Check

Verifies the Claude Code environment is correctly set up. Auto-fixes what it can.

**Announce at start:** "Running /doctor to check your Roambee Claude Code setup."

---

## Check 1: AWS CodeArtifact Token

```bash
aws codeartifact get-authorization-token \
  --domain roambee \
  --domain-owner $(python3 -c "import json,os; print(json.load(open(os.path.expanduser('~/.claude/roambee-config.json')))['codeartifact']['accountId'])") \
  --region $(python3 -c "import json,os; print(json.load(open(os.path.expanduser('~/.claude/roambee-config.json')))['codeartifact']['region'])") \
  --query authorizationToken --output text > /dev/null 2>&1 && echo "VALID" || echo "EXPIRED"
```

- **VALID**: ✅ CodeArtifact token is active
- **EXPIRED**: ⚠️ Auto-fix: re-run `aws codeartifact login` using saved credentials from `~/.claude/roambee-config.json`. Same command as Step 1 of `/init`.

---

## Check 2: `~/.claude/CLAUDE.md`

```bash
test -f ~/.claude/CLAUDE.md && echo "EXISTS" || echo "MISSING"
```

- **EXISTS**: Verify it contains the string `Roambee — Claude Code Global Standards`. If not, it's a custom file — warn but don't overwrite.
- **MISSING**: Auto-fix: copy from plugin `templates/CLAUDE.md`.

---

## Check 3: Hooks in `~/.claude/settings.json`

Read `~/.claude/settings.json`. Check that all hook matchers from `docs/hooks-settings-patch.json` are present.

```bash
python3 -c "
import json, os
settings = json.load(open(os.path.expanduser('~/.claude/settings.json')))
patch = json.load(open('docs/hooks-settings-patch.json'))
missing = []
for event, hooks in patch.items():
    if event.startswith('_'): continue
    existing = [h.get('matcher') for h in settings.get('hooks', {}).get(event, [])]
    for hook in hooks:
        if hook.get('matcher') not in existing:
            missing.append(f'{event}: {hook.get(\"matcher\", hook.get(\"command\", \"?\")[:40])}')
if missing:
    print('MISSING:')
    for m in missing: print(f'  - {m}')
else:
    print('ALL_PRESENT')
"
```

- **ALL_PRESENT**: ✅ All hooks active
- **MISSING**: Auto-fix: merge missing hooks using same logic as `/init` Step 3.

---

## Check 4: `architecture.md` in current repo

```bash
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) && \
test -f "$REPO_ROOT/architecture.md" && echo "EXISTS" || echo "MISSING"
```

- **EXISTS**: ✅
- **MISSING**: ⚠️ Cannot auto-fix. Output: "Run `/new-repo` in this repository to generate `architecture.md`."

---

## Check 5: Required Plugins Installed

```bash
python3 -c "
import json, os
settings = json.load(open(os.path.expanduser('~/.claude/settings.json')))
plugin = json.load(open('plugin.json'))
installed = set(settings.get('plugins', {}).keys())
required = {p['name'] for p in plugin.get('dependencies', {}).get('plugins', [])}
missing = required - installed
if missing:
    print('MISSING: ' + ', '.join(sorted(missing)))
else:
    print('ALL_INSTALLED')
"
```

- **ALL_INSTALLED**: ✅
- **MISSING**: Auto-fix: add missing plugins to `~/.claude/settings.json`. Output: "Restart Claude Code to activate."

---

## Check 6: Playwright Installed

```bash
npx playwright --version 2>/dev/null | grep -q "Version" && echo "INSTALLED" || echo "MISSING"
```

- **INSTALLED**: ✅
- **MISSING**: Auto-fix: `npx playwright install --with-deps chromium`

---

## Check 7: Atlassian MCP Authenticated

Call `mcp__claude_ai_Atlassian__atlassianUserInfo`.

- **Success**: ✅ Authenticated as [display name]
- **Fails / unauthenticated**: Auto-fix: trigger OAuth flow (`mcp__claude_ai_Atlassian__authenticate` → `mcp__claude_ai_Atlassian__complete_authentication`). Re-run Check 7 after.

---

## Check 8: Plugin Up to Date

```bash
git -C ~/roambee-claude fetch --quiet 2>/dev/null
BEHIND=$(git -C ~/roambee-claude rev-list HEAD..origin/main --count 2>/dev/null)
echo "${BEHIND:-0}"
```

- **0**: ✅ Plugin is up to date
- **>0**: ⚠️ Plugin is N commit(s) behind. Run `git pull` in `~/roambee-claude/` to update, then re-run `/init`.

---

## Summary Output

Print a table:

```
Roambee Claude Code Health Check
─────────────────────────────────────────
✅ CodeArtifact token      active
✅ ~/.claude/CLAUDE.md     installed
✅ Hooks                   16/16 active
⚠️  architecture.md        MISSING — run /new-repo
✅ Required plugins        8/8 installed
✅ Playwright              installed
✅ Atlassian MCP           authenticated (Heet Shah)
✅ Plugin version          up to date
─────────────────────────────────────────
1 issue found. See above for fix instructions.
```
