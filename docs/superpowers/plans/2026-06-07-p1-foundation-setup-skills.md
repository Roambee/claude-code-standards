# Roambee Claude Plugin — P1: Foundation & Setup Skills

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create the installable plugin scaffold, the saved-credentials schema, the universal CLAUDE.md template, and the three setup skills (`/init`, `/doctor`, `/new-repo`) that form the foundation every other plan builds on.

**Architecture:** The plugin is a directory of markdown skill files + a `plugin.json` manifest. Setup skills are markdown files that Claude reads and follows step-by-step. All user-specific configuration (AWS, Jira, OpenRouter) is persisted to `~/.claude/roambee-config.json` on first run and reused thereafter.

**Tech Stack:** Claude Code plugin format (`plugin.json` + skill markdown files), Bash for commands within skills, JSON for config persistence, AWS CLI, Atlassian MCP.

**Design spec reference:** `2026-06-06-roambee-claude-standards-plugin-design.md`

---

## File Map

| Action | Path | Responsibility |
|--------|------|----------------|
| Create | `plugin.json` | Plugin manifest, skills list, auto-install dependencies |
| Create | `templates/CLAUDE.md` | Universal company CLAUDE.md installed by `/init` |
| Create | `skills/init/init.md` | One-time machine setup skill |
| Create | `skills/doctor/doctor.md` | Health check + auto-fix skill |
| Create | `skills/new-repo/new-repo.md` | architecture.md generator |

Config file written at runtime (not in the repo):
- `~/.claude/roambee-config.json` — credentials + project settings saved by `/init`

---

## Task 1: `plugin.json`

**Files:**
- Create: `plugin.json`

- [ ] **Step 1: Create `plugin.json`**

```json
{
  "name": "roambee-claude",
  "version": "1.0.0",
  "description": "Roambee company-wide Claude Code standards and workflow enforcement plugin",
  "skills": [
    "init",
    "doctor",
    "new-repo",
    "plan",
    "standup",
    "pr",
    "next-ticket",
    "release-notes",
    "decklar-ui-library",
    "decklar-api-integration",
    "decklar-app-scaffold",
    "decklar-header-integration",
    "hive-app-creator",
    "testing-standards",
    "logging-standards",
    "api-design",
    "migration-standards",
    "python-ai-service",
    "ai-testing",
    "agentic-standards",
    "provider-abstraction"
  ],
  "dependencies": {
    "plugins": [
      { "name": "superpowers",     "source": "thedotmack/superpowers" },
      { "name": "feature-dev",     "source": "thedotmack/feature-dev" },
      { "name": "code-simplifier", "source": "thedotmack/code-simplifier" },
      { "name": "github",          "source": "github/gh-mcp" },
      { "name": "claude-mem",      "source": "thedotmack/claude-mem" },
      { "name": "hookify",         "source": "thedotmack/hookify" },
      { "name": "coderabbit",      "source": "coderabbit-ai/coderabbit-claude" },
      { "name": "frontend-design", "source": "thedotmack/frontend-design" }
    ],
    "mcpServers": [
      {
        "name": "playwright",
        "command": "npx",
        "args": ["@playwright/mcp@latest"]
      }
    ]
  }
}
```

- [ ] **Step 2: Verify the file parses as valid JSON**

```bash
python3 -m json.tool plugin.json > /dev/null && echo "✅ Valid JSON" || echo "❌ Invalid JSON"
```

Expected: `✅ Valid JSON`

- [ ] **Step 3: Commit**

```bash
git init
git add plugin.json
git commit -m "chore: initialise roambee-claude plugin manifest"
```

---

## Task 2: `~/.claude/roambee-config.json` Schema

This file is NOT in the repo — it lives on each developer's machine and is written by `/init`. Document its schema here so all skills know what to expect.

**Files:**
- Create: `docs/roambee-config-schema.json` (reference only — not installed)

- [ ] **Step 1: Create the schema reference**

```json
{
  "$schema": "http://json-schema.org/draft-07/schema",
  "description": "Written by /init to ~/.claude/roambee-config.json. All fields are optional until the feature that needs them is first used.",
  "type": "object",
  "properties": {
    "codeartifact": {
      "type": "object",
      "properties": {
        "accountId": { "type": "string", "description": "AWS account ID owning the CodeArtifact domain" },
        "region":    { "type": "string", "description": "AWS region, e.g. ap-south-1" },
        "profile":   { "type": "string", "description": "AWS CLI profile name, e.g. default" }
      }
    },
    "jira": {
      "type": "object",
      "properties": {
        "domain":     { "type": "string", "description": "Atlassian domain, e.g. roambee.atlassian.net" },
        "projectKey": { "type": "string", "description": "Jira project key, e.g. RMB" }
      }
    },
    "openrouter": {
      "type": "object",
      "properties": {
        "baseUrl":    { "type": "string", "description": "OpenRouter base URL" },
        "keyEnvVar":  { "type": "string", "description": "Name of the env var holding the API key, e.g. OPENROUTER_API_KEY" }
      }
    }
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add docs/roambee-config-schema.json
git commit -m "docs: add roambee-config.json schema reference"
```

---

## Task 3: `templates/CLAUDE.md`

This is the universal company CLAUDE.md that `/init` installs to `~/.claude/CLAUDE.md` on every developer machine.

**Files:**
- Create: `templates/CLAUDE.md`

- [ ] **Step 1: Create `templates/CLAUDE.md`**

```markdown
# Roambee — Claude Code Global Standards

Installed by `roambee-claude /init`. Do not edit manually — run `/init` to update.

---

## Git Workflow

- Branch naming: `<type>/<TICKET-ID>/<short-title-in-kebab-case>`
  - Types: `feat`, `fix`, `chore`, `refactor`, `docs`
  - Example: `feat/RMB-1234/add-shipment-export`
- Always cut from a fresh `origin/dev` — never branch off another feature branch
- One Jira ticket per branch — no bundling unrelated work

## Commit Format

Conventional commits only:
```
feat(scope): short description

Body if needed. No "Co-Authored-By: Claude" lines.
```
Valid scopes match commitlint config in the monorepo root.

## Planning Rule

Never begin implementation of a plan without a Jira ticket. Use `/plan` — it creates tickets and writes the plan in one step. If a plan exists in conversation with no ticket, ask for the ticket ID before writing any code.

## Branch Context Rule

If already on a branch with a ticket ID, ask the user whether new work belongs to that ticket or needs a new one. Infer from context:
- Bug fix / debugging session → same branch, same ticket
- New feature discussion → new branch, new ticket

Always confirm before acting.

## Skill Invocation Order

For every feature or fix:
1. Implement
2. Run tests (unit + e2e where applicable)
3. `feature-dev:code-reviewer`
4. `code-simplifier`
5. Update `architecture.md` and `README.md` if the change affects them
6. Commit
7. `/pr`

## Subagent Protocol

- Every subagent response must include a `## Flags` section reporting: scope changes, blockers, code review findings, decisions made
- Never make autonomous decisions that affect shared systems (DB, CI, branches, PRs, emails)
- Before marking any task Done: verify tests pass, update docs if needed, transition Jira ticket

## PR Policy

Always use `/pr` — never open a PR manually. `/pr` confirms tests pass, creates the PR with a standard template, links to Jira, and transitions the ticket to In Review.

## Docs Update Rule

`architecture.md` and `README.md` are living documents. Any commit that adds a service, changes local dev setup, adds env vars, or changes the tech stack must update those files in the same commit. Stale docs = incomplete work.

## AI Development

- Always use OpenRouter as the provider — no direct Anthropic/OpenAI SDK calls in production services
- Before writing any LLM call, ask the user: what model? what task? Present the cost table from `provider-abstraction` skill
- Prompts are versioned files (`prompts/feature-name.md`), never inline strings longer than ~100 chars
- Every LLM call must log: model name, token counts in + out, latency, request ID

## Code Style

- No comments unless the WHY is non-obvious (hidden constraint, workaround, subtle invariant)
- No docstrings, no multi-line comment blocks
- No backwards-compat shims — if something is unused, delete it
- No feature flags for internal code changes

## CI Pipeline Summary

The pipeline checks: commitlint, ESLint, TypeScript compilation, unit tests, e2e tests (NestJS), build. A commit that breaks any of these will fail CI. Know before you push.
```

- [ ] **Step 2: Commit**

```bash
git add templates/CLAUDE.md
git commit -m "feat: add universal CLAUDE.md template"
```

---

## Task 4: `skills/init/init.md`

**Files:**
- Create: `skills/init/init.md`

- [ ] **Step 1: Create `skills/init/init.md`**

````markdown
# /init — Roambee Machine Setup

Run once per developer machine. Idempotent — safe to re-run.

**Announce at start:** "Running /init to set up your Roambee Claude Code environment."

---

## Step 1: AWS CodeArtifact

Check for saved credentials:
```bash
python3 -c "
import json, os
p = os.path.expanduser('~/.claude/roambee-config.json')
try:
    d = json.load(open(p))
    ca = d.get('codeartifact', {})
    print(ca.get('accountId',''), ca.get('region',''), ca.get('profile','default'))
except: print('', '', 'default')
"
```

If `accountId` is empty, ask the developer:
1. "What is your AWS Account ID for CodeArtifact?" (12-digit number)
2. "What AWS region is the CodeArtifact domain in? (e.g. ap-south-1, us-east-1)"
3. "What AWS CLI profile to use? (press Enter for 'default')"

Save to `~/.claude/roambee-config.json` (merge, don't overwrite):
```bash
python3 -c "
import json, os
p = os.path.expanduser('~/.claude/roambee-config.json')
d = {}
try: d = json.load(open(p))
except: pass
d.setdefault('codeartifact', {}).update({
    'accountId': '<ACCOUNT_ID>',
    'region': '<REGION>',
    'profile': '<PROFILE>'
})
json.dump(d, open(p, 'w'), indent=2)
print('Credentials saved.')
"
```

Authenticate:
```bash
aws codeartifact login --tool npm \
  --domain roambee \
  --domain-owner <accountId> \
  --region <region> \
  --profile <profile> \
  --repository npm-internal
```

Expected output includes: `Logged in to npm repository`. If it fails, check that the profile has `codeartifact:GetAuthorizationToken` permission.

Note: token expires after 12h. Re-run `/init` or `/doctor --fix` to refresh.

---

## Step 2: Install CLAUDE.md

```bash
cp "$(dirname "$0")/../../templates/CLAUDE.md" ~/.claude/CLAUDE.md
echo "✅ ~/.claude/CLAUDE.md installed"
```

If `~/.claude/CLAUDE.md` already exists, overwrite it — the template is the source of truth.

---

## Step 3: Install Hooks

Read the hooks from `docs/hooks-settings-patch.json` in the plugin repo and merge them into `~/.claude/settings.json`:

```bash
python3 -c "
import json, os
settings_path = os.path.expanduser('~/.claude/settings.json')
hooks_patch_path = os.path.join(os.path.dirname(os.path.abspath('$0')), '../../docs/hooks-settings-patch.json')

settings = {}
try: settings = json.load(open(settings_path))
except: pass

patch = json.load(open(hooks_patch_path))
settings.setdefault('hooks', {})
for event, hooks in patch.items():
    settings['hooks'].setdefault(event, [])
    existing_matchers = [h.get('matcher') for h in settings['hooks'][event]]
    for hook in hooks:
        if hook.get('matcher') not in existing_matchers:
            settings['hooks'][event].append(hook)

json.dump(settings, open(settings_path, 'w'), indent=2)
print('✅ Hooks installed into ~/.claude/settings.json')
"
```

---

## Step 4: Install Required Plugins

Read `plugin.json` dependencies and patch them into `~/.claude/settings.json`:

```bash
python3 -c "
import json, os
settings_path = os.path.expanduser('~/.claude/settings.json')
plugin_path = os.path.join(os.path.dirname(os.path.abspath('$0')), '../../plugin.json')

settings = {}
try: settings = json.load(open(settings_path))
except: pass

plugin = json.load(open(plugin_path))
deps = plugin.get('dependencies', {})

settings.setdefault('plugins', {})
for p in deps.get('plugins', []):
    if p['name'] not in settings['plugins']:
        settings['plugins'][p['name']] = {'source': p['source']}
        print(f'  Added plugin: {p[\"name\"]}')

settings.setdefault('mcpServers', {})
for mcp in deps.get('mcpServers', []):
    if mcp['name'] not in settings['mcpServers']:
        settings['mcpServers'][mcp['name']] = {
            'command': mcp['command'],
            'args': mcp['args']
        }
        print(f'  Added MCP server: {mcp[\"name\"]}')

json.dump(settings, open(settings_path, 'w'), indent=2)
print('✅ Plugins and MCP servers installed. Restart Claude Code to activate.')
"
```

---

## Step 5: Install Playwright

```bash
npx playwright install --with-deps chromium 2>&1 | tail -5
echo "✅ Playwright Chromium installed"
```

---

## Step 6: Atlassian MCP Setup

Check if Atlassian MCP is authenticated by calling `mcp__claude_ai_Atlassian__atlassianUserInfo`. If the call fails or returns unauthenticated:

1. Call `mcp__claude_ai_Atlassian__authenticate` to start the OAuth flow
2. Wait for the developer to complete authentication in the browser
3. Call `mcp__claude_ai_Atlassian__complete_authentication`
4. Call `mcp__claude_ai_Atlassian__getAccessibleAtlassianResources` to list available sites
5. Ask the developer: "Which Jira site? (e.g. roambee.atlassian.net)"
6. Ask: "What is the Jira project key? (e.g. RMB)"
7. Save to `~/.claude/roambee-config.json`:

```bash
python3 -c "
import json, os
p = os.path.expanduser('~/.claude/roambee-config.json')
d = {}
try: d = json.load(open(p))
except: pass
d['jira'] = {'domain': '<DOMAIN>', 'projectKey': '<PROJECT_KEY>'}
json.dump(d, open(p, 'w'), indent=2)
print('✅ Jira config saved.')
"
```

---

## Step 7: Summary

Print a checklist of what was completed:

```
✅ AWS CodeArtifact authenticated (token valid 12h)
✅ ~/.claude/CLAUDE.md installed
✅ Hooks installed (16 hooks active)
✅ Required plugins added to settings.json
✅ Playwright Chromium installed
✅ Atlassian MCP authenticated — project: <PROJECT_KEY>

Run /doctor at any time to verify the setup is still healthy.
```
````

- [ ] **Step 2: Verify the file was created correctly**

```bash
wc -l skills/init/init.md
```

Expected: more than 80 lines.

- [ ] **Step 3: Commit**

```bash
git add skills/init/init.md
git commit -m "feat: add /init machine setup skill"
```

---

## Task 5: `skills/doctor/doctor.md`

**Files:**
- Create: `skills/doctor/doctor.md`

- [ ] **Step 1: Create `skills/doctor/doctor.md`**

````markdown
# /doctor — Roambee Setup Health Check

Verifies the Claude Code environment is correctly set up. Auto-fixes what it can.

**Announce at start:** "Running /doctor to check your Roambee Claude Code setup."

---

## Check 1: AWS CodeArtifact Token

```bash
npm ping --registry https://npm.pkg.github.com 2>/dev/null || \
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

Read `~/.claude/settings.json`. Check that all 16 hook matchers from `docs/hooks-settings-patch.json` are present.

```bash
python3 -c "
import json, os
settings = json.load(open(os.path.expanduser('~/.claude/settings.json')))
patch = json.load(open('docs/hooks-settings-patch.json'))
missing = []
for event, hooks in patch.items():
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
- **MISSING**: Auto-fix: merge missing hooks from `docs/hooks-settings-patch.json` using same logic as `/init` Step 3.

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

Read `plugin.json` dependencies. For each, check `~/.claude/settings.json`:

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
- **MISSING**: Auto-fix: add missing plugins to `~/.claude/settings.json`. Same logic as `/init` Step 4. Output: "Restart Claude Code to activate newly added plugins."

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
- **>0**: ⚠️ `roambee-claude` is N commit(s) behind. Run `git pull` in `~/roambee-claude/` to update, then re-run `/init` to apply changes.

---

## Summary Output

Print a table:

```
Roambee Claude Code Health Check
─────────────────────────────────────────
✅ CodeArtifact token      active
✅ ~/.claude/CLAUDE.md     installed (v1.0.0)
✅ Hooks                   16/16 active
⚠️  architecture.md        MISSING — run /new-repo
✅ Required plugins        8/8 installed
✅ Playwright              1.44.0
✅ Atlassian MCP           authenticated (Heet Shah)
✅ Plugin version          up to date
─────────────────────────────────────────
1 issue found. See above for fix instructions.
```
````

- [ ] **Step 2: Commit**

```bash
git add skills/doctor/doctor.md
git commit -m "feat: add /doctor health check skill"
```

---

## Task 6: `skills/new-repo/new-repo.md`

**Files:**
- Create: `skills/new-repo/new-repo.md`

- [ ] **Step 1: Create `skills/new-repo/new-repo.md`**

````markdown
# /new-repo — Architecture Doc Generator

Run once per repo after cloning. Generates `architecture.md` at the repo root. Required before Claude will write or edit any file in the repo (Hook 1 enforces this).

**Announce at start:** "Running /new-repo to generate architecture.md for this repository."

---

## Step 1: Gather Context

Read the following files (skip gracefully if missing):
```bash
cat package.json 2>/dev/null || cat pyproject.toml 2>/dev/null
cat README.md 2>/dev/null | head -100
ls -la src/ packages/ apps/ 2>/dev/null | head -40
cat .env.example 2>/dev/null
```

Also check:
```bash
git log --oneline -10
git remote get-url origin
```

---

## Step 2: Generate `architecture.md`

Using the gathered context, write `architecture.md` at the repo root with this exact structure:

```markdown
# [Service/App Name] — Architecture

> Generated by `roambee-claude /new-repo` on [date]. Keep this file updated as the project evolves — Hook 15 will remind you.

## Overview
[One paragraph: what this service does, who uses it, and where it sits in the Roambee ecosystem]

## Tech Stack
| Layer | Technology |
|-------|-----------|
| Language | [e.g. TypeScript / Python 3.11] |
| Framework | [e.g. NestJS 10 / FastAPI 0.110] |
| Database | [e.g. PostgreSQL via TypeORM] |
| Key libraries | [e.g. OpenFGA, React Query, Pydantic] |

## Key Modules
| Module / Package | Responsibility |
|-----------------|----------------|
| [path or name] | [what it does] |

## External Dependencies
| System | Purpose | Connection |
|--------|---------|------------|
| [e.g. Central Authorization Service] | [auth checks] | [HTTP, port 3001] |

## Environment Variables
See `.env.example`. Required variables:
| Variable | Description |
|----------|-------------|
| [VAR_NAME] | [what it controls] |

## Local Dev Setup
```bash
# 1. Install dependencies
npm install   # or: uv sync

# 2. Copy env file
cp .env.example .env
# Edit .env with your local values

# 3. Run migrations (if applicable)
npm run migration:run

# 4. Start dev server
npm run start:dev   # or: uvicorn main:app --reload
```

## Running Tests
```bash
# Unit tests
npm run test        # or: pytest

# E2E tests (requires running DB)
npm run test:e2e

# Frontend integration (requires dev server running)
npx playwright test
```

## Deployment
- CI/CD: [Jenkins / GitHub Actions]
- Environments: dev → staging → prod
- Deploy: [describe the deploy command or pipeline trigger]
```

---

## Step 3: Commit `architecture.md`

```bash
git add architecture.md
git commit -m "docs: add architecture.md (generated by /new-repo)"
```

Output: "✅ architecture.md created and committed. Hook 1 will now pass for this repository."

---

## Maintenance Note

Tell the developer: "Keep this file updated as the project evolves. Hook 4 will remind you when commits include architecture-impacting changes, and Hook 15 will remind subagents before they mark tasks Done."
````

- [ ] **Step 2: Commit**

```bash
git add skills/new-repo/new-repo.md
git commit -m "feat: add /new-repo architecture doc generator skill"
```

---

## Task 7: `docs/hooks-settings-patch.json` placeholder

The hooks skill (P2) will populate this file with all 16 hook definitions. `/init` and `/doctor` reference it. Create a placeholder now so the references don't break.

**Files:**
- Create: `docs/hooks-settings-patch.json`

- [ ] **Step 1: Create placeholder**

```json
{
  "_comment": "Populated by P2 — Enforcement Hooks. This file is merged into ~/.claude/settings.json by /init.",
  "PreToolUse": [],
  "PostToolUse": []
}
```

- [ ] **Step 2: Commit**

```bash
git add docs/hooks-settings-patch.json
git commit -m "chore: add hooks-settings-patch.json placeholder (populated in P2)"
```

---

## Task 8: End-to-End Verification

- [ ] **Step 1: Register the plugin locally**

Add to `~/.claude/settings.json`:
```json
"extraKnownMarketplaces": {
  "roambee": {
    "source": {
      "source": "github",
      "repo": "Roambee/claude-code-standards"
    }
  }
}
```

- [ ] **Step 2: Restart Claude Code and verify plugin is recognised**

Open a new Claude Code session. Run:
```
/init
```

Expected: Claude reads `skills/init/init.md` and starts executing Step 1 (checks for CodeArtifact credentials).

- [ ] **Step 3: Verify `/doctor` runs**

```
/doctor
```

Expected: Claude reads `skills/doctor/doctor.md` and runs all 8 checks, printing a summary table.

- [ ] **Step 4: Verify `/new-repo` runs in a test repo**

```bash
mkdir /tmp/test-repo && cd /tmp/test-repo && git init && echo '{"name":"test"}' > package.json && git add . && git commit -m "init"
```

Open Claude Code in `/tmp/test-repo`. Run `/new-repo`. Expected: `architecture.md` created and committed.

- [ ] **Step 5: Verify Hook 1 would block (architecture check)**

In a repo without `architecture.md`, attempt to ask Claude to write a file. Expected: Claude stops and says to run `/new-repo` first.

Note: Hook 1 is defined in P2 — this step is a preview. Come back to verify after P2 is complete.

- [ ] **Step 6: Final commit**

```bash
git add -A
git status
git commit -m "chore: P1 complete — foundation and setup skills"
```

---

## Self-Review Checklist

- [x] `plugin.json` lists all 21 skills and all dependencies
- [x] `roambee-config.json` schema documented — all skills know what fields to expect
- [x] `templates/CLAUDE.md` covers all rules from the design spec
- [x] `/init` saves credentials on first run and skips re-prompting on subsequent runs
- [x] `/init` installs hooks, plugins, Playwright, and Atlassian MCP in one pass
- [x] `/doctor` auto-fixes: CodeArtifact token, CLAUDE.md, hooks, plugins, Playwright, Atlassian auth
- [x] `/doctor` reports-only (no auto-fix): architecture.md missing, plugin update available
- [x] `/new-repo` generates a complete architecture.md and commits it
- [x] `hooks-settings-patch.json` placeholder created — P2 will populate it

**Gaps / known deferred items:**
- Hook 1 (architecture check) is referenced in `/init` Step 3 but not yet implemented — P2
- Plugin dependency auto-install uses a custom Python script since Claude Code doesn't have native dependency resolution — acceptable for v1
- OpenRouter config is gathered by `provider-abstraction` skill on first use, not by `/init` — intentional (only AI devs need it)
