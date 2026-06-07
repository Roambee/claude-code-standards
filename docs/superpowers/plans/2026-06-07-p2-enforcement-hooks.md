# Roambee Claude Plugin — P2: Enforcement Hooks

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans` to implement this plan task-by-task.

**Goal:** Implement all 16 enforcement hooks as shell scripts and populate `docs/hooks-settings-patch.json` so `/init` can install them automatically.

**Architecture:** Hooks are defined in `~/.claude/settings.json` under `hooks.PreToolUse` and `hooks.PostToolUse`. Each hook has a `matcher` (regex on tool name + input) and a `command` (shell script that exits 0 to allow, non-zero to block, or prints to inject context). The patch file `docs/hooks-settings-patch.json` is the source of truth — `/init` merges it into the developer's settings.

**Tech Stack:** Bash, jq (where available), Python3 (fallback for JSON parsing), standard Unix tools.

**Prerequisite:** P1 complete — `docs/hooks-settings-patch.json` placeholder exists.

**Design spec reference:** Hooks section of `2026-06-06-roambee-claude-standards-plugin-design.md`

---

## File Map

| Action | Path | Responsibility |
|--------|------|----------------|
| Modify | `docs/hooks-settings-patch.json` | All 16 hook definitions |
| Create | `hooks/` | Individual hook scripts (sourced by settings.json) |
| Create | `hooks/lib.sh` | Shared utilities (read roambee-config, git root, etc.) |

Hook scripts live in `~/roambee-claude/hooks/` and are called with absolute paths in `hooks-settings-patch.json`.

---

## Task 1: `hooks/lib.sh` — Shared utilities

**Files:**
- Create: `hooks/lib.sh`

- [ ] **Step 1: Create shared library**

```bash
#!/usr/bin/env bash
# Shared utilities for roambee-claude hooks

PLUGIN_DIR="$HOME/roambee-claude"
CONFIG_FILE="$HOME/.claude/roambee-config.json"

# Get git repo root or empty string if not in a git repo
git_root() {
  git rev-parse --show-toplevel 2>/dev/null || echo ""
}

# Read a value from roambee-config.json
# Usage: config_get "jira" "projectKey"
config_get() {
  python3 -c "
import json, os, sys
try:
    d = json.load(open('$CONFIG_FILE'))
    keys = sys.argv[1:]
    for k in keys:
        d = d[k]
    print(d)
except: print('')
" "$1" "$2" 2>/dev/null
}

# Exit codes
BLOCK=2      # Hard block — Claude stops and shows message
ALLOW=0      # Pass silently
INJECT=0     # Context injection — print message then exit 0 (Claude reads stdout)
```

- [ ] **Step 2: Commit**

```bash
git add hooks/lib.sh
chmod +x hooks/lib.sh
git commit -m "feat: add hook shared library"
```

---

## Task 2: Hooks 0–3 (Session + Architecture + Path-Aware + CI Warning)

**Files:**
- Create: `hooks/hook-00-plugin-update.sh`
- Create: `hooks/hook-01-architecture-check.sh`
- Create: `hooks/hook-02-path-aware-skill.sh`
- Create: `hooks/hook-03-ci-file-warning.sh`

- [ ] **Step 1: `hooks/hook-00-plugin-update.sh`**

```bash
#!/usr/bin/env bash
# Hook 0: Plugin update notifier — fires on first tool call of session
# Uses a session flag file to run only once per session

SESSION_FLAG="/tmp/roambee-hook0-$$-checked"
[ -f "$SESSION_FLAG" ] && exit 0
touch "$SESSION_FLAG"

BEHIND=$(git -C "$HOME/roambee-claude" fetch --quiet 2>/dev/null && \
         git -C "$HOME/roambee-claude" rev-list HEAD..origin/main --count 2>/dev/null || echo "0")

if [ "${BEHIND:-0}" -gt 0 ]; then
  echo "⚠️  roambee-claude plugin has $BEHIND new commit(s). Run \`git pull\` in ~/roambee-claude/ or run /doctor to apply updates."
fi
exit 0
```

- [ ] **Step 2: `hooks/hook-01-architecture-check.sh`**

```bash
#!/usr/bin/env bash
# Hook 1: Architecture check — hard block if architecture.md missing
# Runs on first Write/Edit per session in a git repo

SESSION_FLAG="/tmp/roambee-hook1-$$-checked"
[ -f "$SESSION_FLAG" ] && exit 0

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
[ -z "$REPO_ROOT" ] && touch "$SESSION_FLAG" && exit 0

# Check for opt-out flag
[ -f "$REPO_ROOT/.no-architecture-check" ] && touch "$SESSION_FLAG" && exit 0

if [ ! -f "$REPO_ROOT/architecture.md" ]; then
  echo "BLOCK: This repository is missing \`architecture.md\`. Run \`/new-repo\` to generate it before writing any code. This ensures Claude has full context about the service architecture."
  exit 2
fi

touch "$SESSION_FLAG"
exit 0
```

- [ ] **Step 3: `hooks/hook-02-path-aware-skill.sh`**

The file path being written is passed as `$ROAMBEE_FILE_PATH` env var (set by the hook matcher).

```bash
#!/usr/bin/env bash
# Hook 2: Path-aware skill reminder — context injection based on file path

FILE_PATH="${ROAMBEE_FILE_PATH:-}"

case "$FILE_PATH" in
  */src/components/*)
    echo "📌 Skill reminder: Load \`decklar-ui-library\` before writing this component. It covers required patterns, known bugs, and @decklar/ui-library usage."
    ;;
  */src/api/hooks/*|*/src/api/services/*)
    echo "📌 Skill reminder: Load \`decklar-api-integration\` before wiring this API. It covers Query Key Factory, React Query hooks, and URL-persisted filters."
    ;;
  */App.tsx)
    echo "📌 Skill reminder: Load \`decklar-header-integration\` before editing App.tsx. It covers GlobalSearchHeader integration."
    ;;
  */packages/client/*/src/index.*)
    echo "📌 Skill reminder: This looks like a new MFE entry point. Load \`decklar-app-scaffold\` or \`hive-app-creator\` before scaffolding."
    ;;
esac
exit 0
```

- [ ] **Step 4: `hooks/hook-03-ci-warning.sh`**

```bash
#!/usr/bin/env bash
# Hook 3: CI file warning

echo "⚠️  You are editing a CI/CD configuration file. This affects all developers. Be conservative, verify the change won't break the pipeline, and confirm the target environment before proceeding."
exit 0
```

- [ ] **Step 5: Commit**

```bash
chmod +x hooks/hook-0*.sh
git add hooks/
git commit -m "feat: add hooks 0-3 (update notifier, architecture check, path-aware, CI warning)"
```

---

## Task 3: Hooks 4–6 (Pre-Commit Gate, Migration Safety, Secret Scan)

**Files:**
- Create: `hooks/hook-04-precommit-gate.sh`
- Create: `hooks/hook-05-migration-safety.sh`
- Create: `hooks/hook-06-secret-scan.sh`

- [ ] **Step 1: `hooks/hook-04-precommit-gate.sh`**

```bash
#!/usr/bin/env bash
# Hook 4: Pre-commit quality gate

DIFF=$(git diff --cached 2>/dev/null)
VIOLATIONS=()

# console.log in non-test files
if echo "$DIFF" | grep -E '^\+.*console\.log\(' | grep -qvE '\.(test|spec)\.(ts|tsx|js)'; then
  VIOLATIONS+=("console.log() found in non-test file(s)")
fi

# debugger statements
if echo "$DIFF" | grep -qE '^\+.*\bdebugger\b'; then
  VIOLATIONS+=("debugger statement found")
fi

# Architecture-impacting changes without doc update
STAGED_FILES=$(git diff --cached --name-only)
ARCH_IMPACTING=$(echo "$STAGED_FILES" | grep -E '(controllers?|services?|modules?|routers?)/[^/]+\.(ts|py)$|^packages/[^/]+/package\.json$|main\.(ts|py)$|^App\.tsx$')
if [ -n "$ARCH_IMPACTING" ]; then
  DOC_UPDATED=$(echo "$STAGED_FILES" | grep -E '^(architecture\.md|README\.md)$')
  if [ -z "$DOC_UPDATED" ]; then
    echo "📝 Docs reminder: These changes may affect architecture.md or README.md. Review and update them if needed before committing:"
    echo "$ARCH_IMPACTING" | sed 's/^/  - /'
  fi
fi

if [ ${#VIOLATIONS[@]} -gt 0 ]; then
  echo "BLOCK: Pre-commit quality gate failed:"
  for v in "${VIOLATIONS[@]}"; do
    echo "  ❌ $v"
  done
  echo "Fix the above issues before committing."
  exit 2
fi

exit 0
```

- [ ] **Step 2: `hooks/hook-05-migration-safety.sh`**

```bash
#!/usr/bin/env bash
# Hook 5: Migration safety — hard block on destructive operations

COMMAND="${ROAMBEE_BASH_COMMAND:-}"
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)

# Find the migration file most recently modified (likely the one being run)
MIGRATION_FILE=$(find "$REPO_ROOT" -name "*migration*.ts" -newer "$REPO_ROOT/package.json" 2>/dev/null | head -1)
[ -z "$MIGRATION_FILE" ] && exit 0

DANGEROUS=$(grep -iE '(DROP TABLE|DROP COLUMN|TRUNCATE|ALTER COLUMN)' "$MIGRATION_FILE" 2>/dev/null)
if [ -n "$DANGEROUS" ]; then
  echo "BLOCK: Destructive database operation detected in migration:"
  echo "$DANGEROUS" | head -5
  echo ""
  echo "Review the migration carefully. If intentional, confirm with the user before proceeding. Ensure a down() method exists to reverse this."
  exit 2
fi

exit 0
```

- [ ] **Step 3: `hooks/hook-06-secret-scan.sh`**

The content being written is passed via stdin or `$ROAMBEE_FILE_CONTENT` env var.

```bash
#!/usr/bin/env bash
# Hook 6: Secret scan

CONTENT="${ROAMBEE_FILE_CONTENT:-$(cat 2>/dev/null)}"
FILE_PATH="${ROAMBEE_FILE_PATH:-}"
MATCHES=()

# AWS Access Key
echo "$CONTENT" | grep -qE 'AKIA[A-Z0-9]{16}' && MATCHES+=("AWS Access Key pattern detected")

# Bearer token
echo "$CONTENT" | grep -qE 'Bearer [A-Za-z0-9\-_]{20,}' && MATCHES+=("Bearer token literal detected")

# Password assignment
echo "$CONTENT" | grep -qE "password\s*=\s*['\"][^'\"]{6,}" && MATCHES+=("Hardcoded password assignment detected")

# .env file being written (not .env.example)
if echo "$FILE_PATH" | grep -qE '\.env$' && ! echo "$FILE_PATH" | grep -q '\.env\.example'; then
  MATCHES+=(".env file being written — secrets must not be committed")
fi

if [ ${#MATCHES[@]} -gt 0 ]; then
  echo "BLOCK: Secret scan failed:"
  for m in "${MATCHES[@]}"; do
    echo "  🔴 $m"
  done
  echo "Remove secrets before writing this file. Use environment variables and .env.example with placeholders."
  exit 2
fi

exit 0
```

- [ ] **Step 4: Commit**

```bash
chmod +x hooks/hook-0[4-6].sh
git add hooks/
git commit -m "feat: add hooks 4-6 (pre-commit gate, migration safety, secret scan)"
```

---

## Task 4: Hooks 7–10 (Dependency, Prompt, AI Observability, Env Guard)

**Files:**
- Create: `hooks/hook-07-dependency-governance.sh`
- Create: `hooks/hook-08-prompt-as-code.sh`
- Create: `hooks/hook-09-ai-observability.sh`
- Create: `hooks/hook-10-environment-guard.sh`

- [ ] **Step 1: `hooks/hook-07-dependency-governance.sh`**

```bash
#!/usr/bin/env bash
# Hook 7: Dependency governance

echo "📦 You are adding a dependency. Before proceeding:"
echo "  1. Check if an equivalent already exists in the monorepo (grep the packages/ directory)"
echo "  2. UI components must use @decklar/ui-library — do not add a separate component library"
echo "  3. Python LLM calls must go through OpenRouter — do not add @anthropic-ai/sdk or openai directly"
exit 0
```

- [ ] **Step 2: `hooks/hook-08-prompt-as-code.sh`**

```bash
#!/usr/bin/env bash
# Hook 8: Prompt-as-code reminder

CONTENT="${ROAMBEE_FILE_CONTENT:-$(cat 2>/dev/null)}"

# Check for string literals > 300 chars (rough proxy for embedded prompts)
if echo "$CONTENT" | python3 -c "
import sys, re
content = sys.stdin.read()
# Find quoted strings longer than 300 chars
matches = re.findall(r'[\"\']{1,3}.{300,}[\"\']{1,3}', content, re.DOTALL)
sys.exit(0 if matches else 1)
" 2>/dev/null; then
  echo "💡 This looks like a long string literal that may be a prompt. Consider extracting it to \`prompts/<feature-name>.md\` so it can be versioned, reviewed, and reused independently."
fi
exit 0
```

- [ ] **Step 3: `hooks/hook-09-ai-observability.sh`**

```bash
#!/usr/bin/env bash
# Hook 9: AI observability reminder

echo "🤖 You are editing an AI service. Before writing LLM calls, ensure:"
echo "  1. Every call logs: model name, token counts (in + out), latency, request_id"
echo "  2. No raw user input or PII is logged"
echo "  3. All LLM calls go through OpenRouter (not direct Anthropic/OpenAI SDK)"
exit 0
```

- [ ] **Step 4: `hooks/hook-10-environment-guard.sh`**

```bash
#!/usr/bin/env bash
# Hook 10: Environment guard

echo "🌍 This command may target a non-local environment. Before proceeding, confirm:"
echo "  - Target environment: dev / staging / prod?"
echo "  - Is this the intended environment for this operation?"
exit 0
```

- [ ] **Step 5: Commit**

```bash
chmod +x hooks/hook-0[7-9].sh hooks/hook-10-*.sh
git add hooks/
git commit -m "feat: add hooks 7-10 (dependency, prompt-as-code, AI observability, env guard)"
```

---

## Task 5: Hooks 11–15 (PII, Cross-MFE, Env Var, Swagger, Doc Update)

**Files:**
- Create: `hooks/hook-11-pii-detector.sh`
- Create: `hooks/hook-12-cross-mfe-import.sh`
- Create: `hooks/hook-13-env-var-governance.sh`
- Create: `hooks/hook-14-swagger-enforcement.sh`
- Create: `hooks/hook-15-subagent-doc-update.sh`

- [ ] **Step 1: `hooks/hook-11-pii-detector.sh`**

```bash
#!/usr/bin/env bash
# Hook 11: PII field detector

CONTENT="${ROAMBEE_FILE_CONTENT:-$(cat 2>/dev/null)}"

PII_FIELDS="email|phone|mobile|address|location|fullName|firstName|lastName|dateOfBirth|dob|ssn|nationalId|passportNumber|full_name|first_name|last_name|date_of_birth|national_id|passport_number"

FOUND=$(echo "$CONTENT" | grep -iE "(${PII_FIELDS})\s*[:=@]" | head -3)
if [ -n "$FOUND" ]; then
  echo "🔒 PII field detected. Before proceeding, confirm:"
  echo "  1. Is this field encrypted at rest?"
  echo "  2. Is it excluded from logs?"
  echo "  3. Does it comply with the data retention policy?"
  echo "  Matched: $(echo "$FOUND" | head -1 | sed 's/^[[:space:]]*//')"
fi
exit 0
```

- [ ] **Step 2: `hooks/hook-12-cross-mfe-import.sh`**

```bash
#!/usr/bin/env bash
# Hook 12: Cross-package MFE import guard

CONTENT="${ROAMBEE_FILE_CONTENT:-$(cat 2>/dev/null)}"
FILE_PATH="${ROAMBEE_FILE_PATH:-}"

# Only applies inside packages/client/
echo "$FILE_PATH" | grep -q "packages/client/" || exit 0

CURRENT_PKG=$(echo "$FILE_PATH" | sed 's|.*/packages/client/\([^/]*\)/.*|\1|')

# Detect imports from other packages/client/* packages
BAD_IMPORT=$(echo "$CONTENT" | grep -E "from ['\"](@roambee/|../../)[^'\"]*['\"]" | \
  python3 -c "
import sys, re
current = '$CURRENT_PKG'
for line in sys.stdin:
    m = re.search(r\"from ['\\\"](@roambee/|../../)([^'\\\"]*)\", line)
    if m:
        target = m.group(2)
        # Skip allowed packages
        if any(x in target for x in ['client-utility', 'shared', 'decklar']):
            continue
        print(line.strip())
" | head -1)

if [ -n "$BAD_IMPORT" ]; then
  echo "BLOCK: Direct cross-MFE import detected:"
  echo "  $BAD_IMPORT"
  echo ""
  echo "Cross-MFE communication must use EventEmitter or packages/shared/. Direct imports break module federation at runtime."
  exit 2
fi
exit 0
```

- [ ] **Step 3: `hooks/hook-13-env-var-governance.sh`**

```bash
#!/usr/bin/env bash
# Hook 13: Environment variable governance

CONTENT="${ROAMBEE_FILE_CONTENT:-$(cat 2>/dev/null)}"
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
ENV_EXAMPLE="$REPO_ROOT/.env.example"

[ ! -f "$ENV_EXAMPLE" ] && exit 0

# Extract env var names from content being written
NEW_VARS=$(echo "$CONTENT" | grep -oE 'process\.env\.[A-Z_]+|os\.environ\[['"'"'""][A-Z_]+['"'"'"]\]|os\.environ\.get\(['"'"'""][A-Z_]+' | \
  sed "s/process\.env\.//;s/os\.environ\['//;s/os\.environ\.get('//;s/'.*//;s/\[\"//;s/\"\]//" | sort -u)

[ -z "$NEW_VARS" ] && exit 0

MISSING=()
for VAR in $NEW_VARS; do
  grep -q "^${VAR}=" "$ENV_EXAMPLE" || MISSING+=("$VAR")
done

if [ ${#MISSING[@]} -gt 0 ]; then
  echo "BLOCK: Environment variable(s) used in code but missing from .env.example:"
  for v in "${MISSING[@]}"; do
    echo "  ❌ $v"
  done
  echo ""
  echo "Add each missing variable to .env.example with a placeholder value and a comment describing what it does. Then re-attempt."
  exit 2
fi
exit 0
```

- [ ] **Step 4: `hooks/hook-14-swagger-enforcement.sh`**

```bash
#!/usr/bin/env bash
# Hook 14: Swagger/OpenAPI enforcement

CONTENT="${ROAMBEE_FILE_CONTENT:-$(cat 2>/dev/null)}"

# Check for new HTTP method decorators
HAS_ENDPOINT=$(echo "$CONTENT" | grep -cE '@(Get|Post|Put|Patch|Delete)\(')
[ "$HAS_ENDPOINT" -eq 0 ] && exit 0

# Check for Swagger decorators
HAS_SWAGGER=$(echo "$CONTENT" | grep -cE '@Api(Operation|Response|Tags)\(')

if [ "$HAS_SWAGGER" -eq 0 ]; then
  echo "📋 New API endpoint(s) detected without Swagger documentation. Add:"
  echo "  @ApiTags('resource-name')       — on the controller class"
  echo "  @ApiOperation({ summary: '' })  — on each endpoint method"
  echo "  @ApiResponse({ status: 200 })   — on each endpoint method"
  echo "Undocumented endpoints accumulate quickly and break the API contract."
fi
exit 0
```

- [ ] **Step 5: `hooks/hook-15-subagent-doc-update.sh`**

```bash
#!/usr/bin/env bash
# Hook 15: Subagent doc update reminder (PostToolUse — fires after Write/Edit)

FILE_PATH="${ROAMBEE_FILE_PATH:-}"

# Check if the file is architecture-impacting
IMPACTING=$(echo "$FILE_PATH" | grep -E '(controllers?|services?|modules?|routers?)/[^/]+\.(ts|py)$|main\.(ts|py)$|App\.tsx$|package\.json$|pyproject\.toml$')
[ -z "$IMPACTING" ] && exit 0

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
[ -z "$REPO_ROOT" ] && exit 0

echo "📝 Before marking this task Done — check if architecture.md or README.md needs updating."
echo "   If you added a service, changed local setup, added env vars, or changed the tech stack, update those files and include them in the commit."
exit 0
```

- [ ] **Step 6: Commit**

```bash
chmod +x hooks/hook-1[1-5]-*.sh
git add hooks/
git commit -m "feat: add hooks 11-15 (PII, cross-MFE, env vars, Swagger, doc update)"
```

---

## Task 6: Populate `docs/hooks-settings-patch.json`

**Files:**
- Modify: `docs/hooks-settings-patch.json`

- [ ] **Step 1: Write the complete patch file**

```json
{
  "_comment": "Merged into ~/.claude/settings.json by /init. Each hook references an absolute path to the script in ~/roambee-claude/hooks/.",
  "PreToolUse": [
    {
      "matcher": ".*",
      "command": "~/roambee-claude/hooks/hook-00-plugin-update.sh"
    },
    {
      "matcher": "Write|Edit",
      "command": "ROAMBEE_FILE_PATH=\"$CLAUDE_FILE_PATH\" ~/roambee-claude/hooks/hook-01-architecture-check.sh"
    },
    {
      "matcher": "Write|Edit",
      "command": "ROAMBEE_FILE_PATH=\"$CLAUDE_FILE_PATH\" ~/roambee-claude/hooks/hook-02-path-aware-skill.sh"
    },
    {
      "matcher": "Write|Edit",
      "inputFilter": "(\\.github/workflows/|Jenkinsfile)",
      "command": "~/roambee-claude/hooks/hook-03-ci-warning.sh"
    },
    {
      "matcher": "Bash",
      "inputFilter": "git commit",
      "command": "~/roambee-claude/hooks/hook-04-precommit-gate.sh"
    },
    {
      "matcher": "Bash",
      "inputFilter": "(migration:run|migration:up|dev:migration)",
      "command": "~/roambee-claude/hooks/hook-05-migration-safety.sh"
    },
    {
      "matcher": "Write|Edit",
      "command": "ROAMBEE_FILE_PATH=\"$CLAUDE_FILE_PATH\" ROAMBEE_FILE_CONTENT=\"$CLAUDE_FILE_CONTENT\" ~/roambee-claude/hooks/hook-06-secret-scan.sh"
    },
    {
      "matcher": "Write|Edit",
      "inputFilter": "(package\\.json|pyproject\\.toml)",
      "command": "~/roambee-claude/hooks/hook-07-dependency-governance.sh"
    },
    {
      "matcher": "Write|Edit",
      "inputFilter": "\\.(py|ts)$",
      "command": "ROAMBEE_FILE_CONTENT=\"$CLAUDE_FILE_CONTENT\" ~/roambee-claude/hooks/hook-08-prompt-as-code.sh"
    },
    {
      "matcher": "Write|Edit",
      "inputFilter": "packages/ai/",
      "command": "~/roambee-claude/hooks/hook-09-ai-observability.sh"
    },
    {
      "matcher": "Bash",
      "inputFilter": "(prod|staging|rds\\.amazonaws|postgres://[^l])",
      "command": "~/roambee-claude/hooks/hook-10-environment-guard.sh"
    },
    {
      "matcher": "Write|Edit",
      "inputFilter": "\\.(ts|tsx|py)$",
      "command": "ROAMBEE_FILE_PATH=\"$CLAUDE_FILE_PATH\" ROAMBEE_FILE_CONTENT=\"$CLAUDE_FILE_CONTENT\" ~/roambee-claude/hooks/hook-11-pii-detector.sh"
    },
    {
      "matcher": "Write|Edit",
      "inputFilter": "packages/client/.*\\.(ts|tsx)$",
      "command": "ROAMBEE_FILE_PATH=\"$CLAUDE_FILE_PATH\" ROAMBEE_FILE_CONTENT=\"$CLAUDE_FILE_CONTENT\" ~/roambee-claude/hooks/hook-12-cross-mfe-import.sh"
    },
    {
      "matcher": "Write|Edit",
      "inputFilter": "\\.(ts|tsx|py)$",
      "command": "ROAMBEE_FILE_PATH=\"$CLAUDE_FILE_PATH\" ROAMBEE_FILE_CONTENT=\"$CLAUDE_FILE_CONTENT\" ~/roambee-claude/hooks/hook-13-env-var-governance.sh"
    },
    {
      "matcher": "Write|Edit",
      "inputFilter": "\\.controller\\.ts$",
      "command": "ROAMBEE_FILE_CONTENT=\"$CLAUDE_FILE_CONTENT\" ~/roambee-claude/hooks/hook-14-swagger-enforcement.sh"
    }
  ],
  "PostToolUse": [
    {
      "matcher": "Write|Edit",
      "command": "ROAMBEE_FILE_PATH=\"$CLAUDE_FILE_PATH\" ~/roambee-claude/hooks/hook-15-subagent-doc-update.sh"
    }
  ]
}
```

- [ ] **Step 2: Verify all 16 hook scripts are referenced**

```bash
grep -c "hook-" docs/hooks-settings-patch.json
```

Expected: 16

- [ ] **Step 3: Commit**

```bash
git add docs/hooks-settings-patch.json
git commit -m "feat: populate hooks-settings-patch.json with all 16 hook definitions"
```

---

## Task 7: End-to-End Verification

- [ ] **Step 1: Run `/init` and verify hooks appear in settings**

After `/init`:
```bash
python3 -c "
import json, os
s = json.load(open(os.path.expanduser('~/.claude/settings.json')))
count = len(s.get('hooks', {}).get('PreToolUse', [])) + len(s.get('hooks', {}).get('PostToolUse', []))
print(f'{count} hooks installed')
"
```

Expected: `16 hooks installed`

- [ ] **Step 2: Test Hook 1 (architecture check)**

In a repo without `architecture.md`, ask Claude to write a file. Expected: Claude outputs the block message and stops.

- [ ] **Step 3: Test Hook 6 (secret scan)**

Ask Claude to write a file containing `password = "mysecret123"`. Expected: Claude is blocked.

- [ ] **Step 4: Test Hook 13 (env var governance)**

Ask Claude to write `process.env.NEW_UNREGISTERED_VAR` in a TypeScript file in a repo with `.env.example`. Expected: Claude is blocked and told to add it to `.env.example`.

- [ ] **Step 5: Final commit**

```bash
git status
git commit -m "chore: P2 complete — all 16 enforcement hooks implemented"
```
