# Roambee Claude Code Standards Plugin — Design Spec

**Date:** 2026-06-06  
**Status:** Draft — in progress  
**Owner:** Heet Shah

---

## Overview

A company-wide Claude Code plugin (`roambee-claude`) that enforces consistent development standards across all Roambee engineering teams. Covers app developers (React microfrontends, NestJS backends) and AI developers (FastAPI, LLM integrations, agentic workflows).

Distributed as a Claude Code plugin via the `.claude-plugin/marketplace.json` + `.claude-plugin/plugin.json` manifest pair at the repo root. Push to a dedicated GitHub org repo (`roambee/claude-code-standards`) and developers register it with a relative `{ "source": "github", "repo": "roambee/claude-code-standards" }` marketplace entry — no per-machine path configuration needed.

### Installation (developer onboarding)

```json
// ~/.claude/settings.json — add once per developer machine
"extraKnownMarketplaces": {
  "roambee": {
    "source": { "source": "github", "repo": "roambee/claude-code-standards" }
  }
}
```

Then run `/init` — one command installs everything.

---

## Plugin Structure

```
~/roambee-claude/
├── plugin.json                      # includes dependencies[] for auto-install
├── skills/
│   ├── init/                        # Machine setup
│   │   └── init.md
│   ├── doctor/                      # Health check
│   │   └── doctor.md
│   ├── new-repo/                    # architecture.md generator
│   │   └── new-repo.md
│   ├── standup/                     # NEW — daily standup generator
│   │   └── standup.md
│   ├── plan/                        # NEW — Jira-aware planning wrapper
│   │   └── plan.md
│   ├── pr/                          # NEW — PR creation with Jira linkage
│   │   └── pr.md
│   ├── next-ticket/                 # NEW — Sprint ticket picker + branch creator
│   │   └── next-ticket.md
│   ├── release-notes/               # NEW — Changelog generator from Jira
│   │   └── release-notes.md
│   │
│   # App developer skills
│   ├── decklar-ui-library/          # MIGRATED from local ~/.claude/skills
│   │   ├── SKILL.md
│   │   ├── assets/
│   │   └── references/
│   ├── decklar-api-integration/     # MIGRATED
│   │   ├── SKILL.md
│   │   ├── assets/
│   │   └── references/
│   ├── decklar-app-scaffold/        # MIGRATED
│   │   ├── SKILL.md
│   │   └── references/
│   ├── decklar-header-integration/  # MIGRATED
│   │   └── SKILL.md
│   ├── hive-app-creator/            # MIGRATED
│   │   ├── SKILL.md
│   │   └── references/
│   ├── testing-standards/           # NEW
│   │   └── testing-standards.md
│   ├── logging-standards/           # NEW
│   │   └── logging-standards.md
│   ├── api-design/                  # NEW
│   │   └── api-design.md
│   ├── migration-standards/         # NEW — TypeORM migration patterns
│   │   └── migration-standards.md
│   │
│   # AI developer skills
│   ├── python-ai-service/           # NEW
│   │   └── python-ai-service.md
│   ├── ai-testing/                  # NEW
│   │   └── ai-testing.md
│   ├── agentic-standards/           # NEW
│   │   └── agentic-standards.md
│   └── provider-abstraction/        # NEW — includes model cost estimator
│       └── provider-abstraction.md
│
└── templates/
    └── CLAUDE.md                    # Universal company CLAUDE.md content
```

---

## `plugin.json` Structure

```json
{
  "name": "roambee-claude",
  "version": "1.0.0",
  "description": "Roambee company-wide Claude Code standards plugin",
  "skills": ["init", "doctor", "new-repo", "plan", "standup", "pr", "next-ticket", "release-notes",
             "decklar-ui-library", "decklar-api-integration", "decklar-app-scaffold",
             "decklar-header-integration", "hive-app-creator",
             "testing-standards", "logging-standards", "api-design", "migration-standards",
             "python-ai-service", "ai-testing", "agentic-standards", "provider-abstraction"],
  "dependencies": {
    "plugins": [
      { "name": "superpowers",      "source": "thedotmack/superpowers" },
      { "name": "feature-dev",      "source": "thedotmack/feature-dev" },
      { "name": "code-simplifier",  "source": "thedotmack/code-simplifier" },
      { "name": "github",           "source": "github/gh-mcp" },
      { "name": "claude-mem",       "source": "thedotmack/claude-mem" },
      { "name": "hookify",          "source": "thedotmack/hookify" },
      { "name": "coderabbit",       "source": "coderabbit-ai/coderabbit-claude" },
      { "name": "frontend-design",  "source": "thedotmack/frontend-design" }
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

`/init` reads `dependencies` and installs everything automatically — a developer only needs to install `roambee-claude` itself.

---

## Skills

### `/init` — Machine Setup

Run once per developer machine. Idempotent — safe to re-run.

**What it does:**
1. Authenticates with AWS CodeArtifact so `npm install` can resolve `@decklar/ui-library`:
   ```bash
   aws codeartifact login --tool npm --domain roambee \
     --domain-owner <ACCOUNT_ID> --repository npm-internal
   ```
   - On first run: prompts the developer for `ACCOUNT_ID`, `region`, and `profile` and saves them to `~/.claude/roambee-config.json`
   - On subsequent runs: reads from `~/.claude/roambee-config.json` — no re-prompting
   - Notes that the token expires after 12h and must be refreshed (run `/init` again or `/doctor --fix`)

2. Writes `~/.claude/CLAUDE.md` from `templates/CLAUDE.md`

3. Patches `~/.claude/settings.json` with all hooks (see Hooks section)

4. Auto-installs all required Claude Code plugins declared in `plugin.json` under `dependencies[]`. For each entry:
   - Checks if the plugin is already present in `~/.claude/settings.json`
   - If missing, patches it in automatically (adds the marketplace source)
   - Required plugins: `superpowers`, `feature-dev`, `code-simplifier`, `github`, `claude-mem`, `hookify`, `coderabbit`, `frontend-design`
   - Developer only needs to install `roambee-claude` — everything else follows automatically

5. Installs Playwright and the Playwright MCP server:
   - Runs `npx playwright install --with-deps chromium` if Playwright is not present
   - Adds the Playwright MCP server to `~/.claude/settings.json` under `mcpServers` if missing:
     ```json
     "playwright": {
       "command": "npx",
       "args": ["@playwright/mcp@latest"]
     }
     ```
   - This gives subagents a tool interface to a live headless browser — no mouse takeover

6. Sets up Atlassian MCP authentication:
   - Checks if `mcp__claude_ai_Atlassian` is already authenticated
   - If not, triggers the Atlassian OAuth flow via `mcp__claude_ai_Atlassian__authenticate`
   - Verifies access to the Roambee Jira project after auth completes
   - Saves the connected Jira project key (e.g. `RMB`) to `~/.claude/roambee-config.json`

---

### `/doctor` — Health Check

Run at any time to verify the Claude Code setup is healthy.

**Checks:**
- [ ] AWS CodeArtifact token is valid (attempts a dry-run npm ping)
- [ ] `~/.claude/CLAUDE.md` exists and matches expected version
- [ ] All hooks are present in `~/.claude/settings.json`
- [ ] `architecture.md` exists in current repo root
- [ ] Required plugins are installed
- [ ] `roambee-claude` plugin is up to date (checks local git vs remote)
- [ ] Atlassian MCP is authenticated and can reach the Roambee Jira project

Reports pass/fail per check. Auto-fixes what it can: refreshes CodeArtifact token, overwrites CLAUDE.md to latest, patches missing hooks. For Atlassian, if unauthenticated, re-triggers the OAuth flow.

---

### `/new-repo` — Architecture Doc Generator

Run once per repo after cloning. Generates `architecture.md` at the repo root.

**What it does:**
1. Reads `package.json` / `pyproject.toml`, key directories, README
2. Asks Claude to summarize: what the service does, its tech stack, key modules, external dependencies, environment requirements, and how to run it locally
3. Writes `architecture.md` to repo root
4. Commits it — so the architecture-check hook passes from day one

**`architecture.md` template sections:**
- Service overview (one paragraph)
- Tech stack
- Key modules / packages and their responsibilities
- External dependencies (DBs, APIs, queues)
- Environment variables (reference `.env.example`)
- Local dev setup
- How to run tests
- Deployment notes (CI/CD pipeline, environments)

---

### `/plan` — Jira-Aware Planning Wrapper

Wraps `superpowers:writing-plans`. Must be used instead of raw planning — enforces the rule that no implementation begins without a Jira ticket.

**Step 1 — Read context**

Check the current git branch:
```bash
git rev-parse --abbrev-ref HEAD
```
Extract ticket ID if branch matches `type/RMB-XXXX/title`.

Read the conversation context to classify intent:
- **Bug fix / debugging**: conversation mentions an error, exception, broken behaviour, or the user has been debugging
- **New feature**: conversation discusses new functionality, a new screen, a new API, or a new service

**Step 2 — Decide branch + ticket strategy**

| Scenario | Action |
|----------|--------|
| Branch has `RMB-XXXX` + bug fix context | Ask: "Are we planning a fix for [RMB-XXXX] on this branch, or is this a separate new feature?" |
| Branch has `RMB-XXXX` + new feature context | Ask: "This looks like a new feature. Should I open a new branch + ticket, or add this work to [RMB-XXXX]?" |
| Branch is `main`, `dev`, or unnamed + any context | New ticket required. Proceed to Step 3. |
| User confirms existing ticket | Link the plan to that ticket. Skip to Step 4. |

**Step 3 — Determine ticket scope**

Ask the user:
> "What is the scope of this change?"
> 1. **Large feature** — Story with Task sub-items under it
> 2. **Medium change** — Single Task with Sub-tasks
> 3. **Small fix or tweak** — Single Sub-task or standalone Task

Do not assume. Wait for the answer before creating anything.

**Step 4 — Create Jira tickets via Atlassian MCP**

Based on scope answer:
- Large: Create a Story, then create Tasks under it for each major phase of the plan
- Medium: Create a Task, then create Sub-tasks for each step
- Small: Create a single Task or Sub-task (ask which parent ticket if Sub-task)

After creation, display the ticket IDs and links. Ask the user to confirm the branch name:
```
Suggested branch: feat/RMB-XXXX/short-description
```

**Step 5 — Write the plan**

Now invoke `superpowers:writing-plans` with full context. The written plan must reference the Jira ticket ID(s) at the top.

**Step 6 — Subagent execution with live Jira updates**

When the plan is executed (via `superpowers:subagent-driven-development` or `superpowers:executing-plans`), each subagent is responsible for its own ticket lifecycle:

- **On task start**: call `mcp__claude_ai_Atlassian__transitionJiraIssue` to move the task ticket to **In Progress**
- **On task complete**: run tests → if passing, upload Playwright screenshot (for frontend tasks) or test output summary (for backend tasks) as a Jira attachment, then add a comment summarising what was built, then transition to **Done**
- **On blocker**: add a Jira comment describing the blocker, surface it in the subagent's `## Flags` section — do not transition to Done
- **On parent story/task**: transition the parent to In Progress when the first sub-task starts; transition to Done only when all sub-tasks are Done

Subagents must never mark a ticket Done if tests have not passed for the work they own.

**Rule enforced in CLAUDE.md:**
> Never begin implementation of a plan without a Jira ticket. Use `/plan` to write plans — it creates tickets automatically. If a plan already exists in the conversation with no ticket, ask the user for the ticket ID before writing any code.
> Subagents must update Jira ticket status as they work — In Progress on start, Done on completion, comment on blocker.

---

### `/standup` — Daily Standup Generator

Run at the start or end of a working day. Generates a standup message from git activity and Jira ticket state.

**What it does:**
1. Runs `git log --since=yesterday --author=$(git config user.email)` across all repos that were touched
2. Groups commits by Jira ticket ID extracted from branch name / commit message
3. For each ticket, fetches current Jira status (if Jira MCP is connected)
4. Produces a formatted standup:
   ```
   Yesterday:
   - [RMB-1234] Implemented pagination for shipment list API (merged to dev)
   - [RMB-1235] Fixed roles redirect bug — PR open, awaiting review

   Today:
   - [RMB-1236] Start work on user export feature

   Blockers: none
   ```
5. "Today" section is filled in by asking the user: "What are you picking up today?" — or pulled from the Jira ticket assigned and In Progress

**Notes:**
- If no Jira MCP connection, skips ticket status and uses commit messages only
- Developer reviews and edits before sending — the skill generates a draft, not a final message
- Works best when branch naming convention (`type/RMB-XXXX/title`) is followed

---

### `/pr` — Pull Request Creation

Run when implementation is complete and tests pass. Creates a PR, links it to Jira, and transitions the ticket.

**What it does:**
1. Confirms all tests are passing before proceeding — blocks if not
2. Reads `~/.claude/roambee-config.json` for Jira project key and Atlassian domain
3. Extracts the Jira ticket ID from the current branch name
4. Generates a PR body using this template:
   ```
   ## Summary
   [What was built — pulled from the Jira ticket title and plan]

   ## Changes
   [Bullet list of key files changed and why]

   ## Test Plan
   [How this was tested — unit tests, e2e, Playwright screenshots]

   ## Jira
   [RMB-XXXX](https://roambee.atlassian.net/browse/RMB-XXXX)
   ```
5. Asks the user: "Ready to open PR against `dev`? Reviewers will be [detected from CODEOWNERS for changed packages]. Confirm?"
6. Creates the PR via GitHub MCP (`gh pr create`) — never opens without confirmation
7. Calls `mcp__claude_ai_Atlassian__transitionJiraIssue` → **In Review**
8. Calls `mcp__claude_ai_Atlassian__addCommentToJiraIssue` with the PR URL: "PR opened: [link]"

**Reviewer detection**: reads `.github/CODEOWNERS` at repo root. For each package directory in the diff, finds the matching CODEOWNERS entry and adds those handles as reviewers.

---

### `/next-ticket` — Sprint Ticket Picker

Run at the start of a work session to pick up the next task without touching Jira manually.

**What it does:**
1. Calls `mcp__claude_ai_Atlassian__searchJiraIssuesUsingJql` with:
   ```
   project = RMB AND assignee = currentUser() AND sprint in openSprints()
   AND status in ("To Do", "In Progress") ORDER BY priority DESC
   ```
2. Displays a numbered list of the results (title, status, priority)
3. Developer picks a number
4. If status is "To Do": transitions to **In Progress**, creates branch:
   ```bash
   git checkout -b feat/RMB-XXXX/short-title origin/dev
   ```
5. If status is "In Progress": asks "Resume work on this ticket or pick a different one?"
6. Outputs the ticket description and acceptance criteria so the developer has full context without opening Jira

---

### `/release-notes` — Changelog Generator

Run when cutting a release to generate a formatted changelog from Jira.

**What it does:**
1. Asks: "What is the release version? What is the date range or comparison tag? (e.g. `v2.4.0` comparing against `v2.3.0`, or `from: 2026-05-01 to: 2026-06-06`)"
2. Calls `mcp__claude_ai_Atlassian__searchJiraIssuesUsingJql`:
   ```
   project = RMB AND status = Done AND resolved >= [startDate]
   AND resolved <= [endDate] ORDER BY type ASC
   ```
3. Groups tickets by type:
   - **Features** (Story type)
   - **Bug Fixes** (Bug type)
   - **Internal / Tech Debt** (Task type with no user-facing impact)
4. Outputs two formats:
   - **Developer changelog** (markdown, for GitHub Releases): full ticket list with IDs and descriptions
   - **Product changelog** (plain English, for Confluence or Slack announcement): grouped features without ticket IDs, written for a non-technical audience
5. Asks: "Post this to Confluence? If yes, which space and page?"

---

### App Developer Skills

#### `decklar-ui-library` (MIGRATED)
Use when building UI components. Enforces `@decklar/ui-library` usage, component patterns, layout rules, known bugs and workarounds.
→ Migrate from `~/Downloads/.claude/skills/decklar-ui-library/`

#### `decklar-api-integration` (MIGRATED)
Use when wiring backend APIs in microfrontends. Covers endpoint constants, Query Key Factory, service layer, React Query hooks, URL-persisted filters.
→ Migrate from `~/Downloads/.claude/skills/decklar-api-integration/`

#### `decklar-app-scaffold` (MIGRATED)
Use when creating a new Single-SPA microfrontend. Scaffolds folder structure, config files, root registration, import maps.
→ Migrate from `~/Downloads/.claude/skills/decklar-app-scaffold/`

#### `decklar-header-integration` (MIGRATED)
Use when adding or migrating the app header. Covers `GlobalSearchHeader` + `useGlobalSearchHeader` integration.
→ Migrate from `~/Downloads/.claude/skills/decklar-header-integration/`

#### `hive-app-creator` (MIGRATED)
Use when creating a new module inside HC20 or a brand-new microfrontend app. Covers both workflow A (HC20 module) and workflow B (new MFE).
→ Migrate from `~/Downloads/.claude/skills/hive-app-creator/`

#### `testing-standards` (NEW)
Use before writing any `*.test.ts` / `*.spec.ts` file.

**Covers:**
- **Frontend unit**: Jest + React Testing Library for microfrontend components
  - How to mock `@roambee/client-utility` cross-MFE imports
  - How to test React Query hooks
  - How to test `EventEmitter`-driven flows
- **Frontend integration (Playwright)**: Subagents run `npx playwright test` against the locally running dev server. Playwright spins up its own headless Chromium — no mouse takeover, no interference with the developer's browser. Tests navigate to `localhost:<port>`, interact with the UI, capture screenshots, and assert on DOM state.
  - Dev server must be running before Playwright tests execute — subagent starts it if not already up
  - Playwright MCP (installed by `/init`) is used by subagents as a tool interface — allows mid-test inspection and navigation without re-running the full suite each time
  - **Screenshot → Jira workflow**: After tests pass, subagent posts evidence to the Jira ticket:
    1. Playwright captures a final screenshot of the completed feature state (saved to `playwright-report/screenshots/`)
    2. Subagent uploads it as an attachment to the Jira ticket via the Jira REST API:
       ```
       POST https://{domain}.atlassian.net/rest/api/3/issue/{issueKey}/attachments
       Headers: X-Atlassian-Token: no-check
       Body: multipart/form-data with the screenshot file
       ```
       Called via `mcp__claude_ai_Atlassian__fetch` or a Bash `curl` command using the saved auth token
    3. Subagent adds a comment via `mcp__claude_ai_Atlassian__addCommentToJiraIssue`:
       > "✅ Feature verified via Playwright. Screenshot attached — [brief description of what's shown, e.g. 'user list loads with pagination, 10 rows visible, filter applied correctly']."
    4. Jira ticket now has a visual record of what was built, reviewable without pulling the branch
- **Backend**: NestJS e2e tests — real DB connections only, no mocks (mocks mask migration failures). Subagents run `npm run test:e2e` inside the relevant package — connects to the developer's local DB via env vars. No special setup required beyond the DB being running.
- **Python AI services**: `pytest` with mocked LLM calls in unit tests; real DB/service connections in integration tests run on demand
- Test file location and naming conventions per package type
- Coverage expectations (TBD — set per team)

#### `logging-standards` (NEW)
Use when adding any logging, error handling, or user notifications.

**Covers:**
- **NestJS services**: use `Logger` from `@nestjs/common`, not `console.log`
- **React frontend**: user-facing errors via `EventEmitter.emit('showSnackbar', {...})`, not `console.error`
- **Python AI services**: structured JSON logging, include `request_id`, `service`, `level`
- **What to never log**: raw user input, PII, full prompt content, auth tokens

#### `api-design` (NEW)
Use when designing or reviewing a new API endpoint.

**Covers:**
- URL versioning: `/v1/` for stable, `/v2/` for current generation
- Response format: always use `ResponseHandlerService` in NestJS (never `res.json()` directly)
- Pagination shape: `{ data: [], total: number, page: number, pageSize: number }`
- Error response format
- Auth header expectations
- Naming conventions (kebab-case URLs, camelCase JSON)
- Swagger/OpenAPI: every endpoint must have `@ApiOperation()`, `@ApiResponse()`, and `@ApiTags()` — no undocumented endpoints

#### `migration-standards` (NEW)
Use before writing any TypeORM migration file.

**Covers:**
- **Naming**: `<timestamp>-<description>.ts` — description must be meaningful (e.g. `1234567890-add-shipment-status-index`, not `1234567890-migration`)
- **Always write `down()`**: every migration must be fully reversible. If a rollback is genuinely impossible (e.g. data-destructive), document why in a comment at the top and confirm with the user before proceeding
- **Schema vs data migrations**: never mix them. Schema changes (ALTER TABLE, ADD COLUMN) go in one migration; data backfills go in a separate migration that runs after
- **No business logic**: migrations must not import from services, repositories, or application code — only raw QueryRunner calls. Application code can be renamed or deleted; migrations run forever
- **Idempotency**: use `IF NOT EXISTS` / `IF EXISTS` guards where TypeORM supports them
- **Test before committing**: run `migration:run` locally and verify the DB state. Run `migration:revert` and verify the rollback also leaves the DB clean
- **Column type changes**: never change a column type in a single migration. Pattern: add new column → backfill data → remove old column (three separate migrations or one with explicit steps)

---

### AI Developer Skills

#### `python-ai-service` (NEW)
Use when building or editing a FastAPI AI microservice.

**Covers:**
- Pydantic models for every request/response (no raw dicts)
- `async`/`await` for all LLM calls — never block the event loop
- Health check endpoint on every service (`GET /health`)
- Python version pinning in `pyproject.toml`
- Dependency management with `uv` (preferred) or pinned `requirements.txt`
- Service structure: `routers/`, `services/`, `models/`, `prompts/`

#### `ai-testing` (NEW)
Use before writing tests for AI services or LLM-powered features.

**Covers:**
- Mock all LLM calls in unit tests — never hit real API in CI (cost + non-determinism)
- How to write provider-agnostic mocks (works for both Anthropic and OpenRouter)
- Golden output tests: assert on response shape, not exact text
- Evaluation harnesses for agent quality: separate from unit tests, run on demand
- Latency budget tests: in integration suite, not unit

#### `agentic-standards` (NEW)
Use when building any agentic workflow, multi-step agent, or tool-using LLM feature.

**Rules:**
- Every tool call must have an explicit timeout and retry limit
- Agent steps must be logged at start AND end — not just on error
- No agent may make irreversible actions (DB writes, emails, deploys, external API mutations) without a human confirmation step
- Maximum recursion / loop depth must be defined per agent
- Tool definitions must include a clear `description` — the model reads this, not you
- Agents must handle `tool_use` errors gracefully and surface them, not silently retry forever

#### `provider-abstraction` (NEW)
Use when writing any LLM integration code.

**Rules:**
- **Always use OpenRouter as the provider** — no direct Anthropic SDK calls in production services (exception: Claude Code tooling itself)
- **Before writing any LLM call**: check `~/.claude/roambee-config.json` for saved OpenRouter base URL and key env var name. If not present, check monorepo root `.env` / `.env.example`. If still not found, ask the user.
- **Before choosing a model**, present this cost reference table and ask the user to pick:

| Model | Best for | Est. cost / 1k calls |
|-------|----------|----------------------|
| `anthropic/claude-haiku-4-5` | Classification, extraction, short Q&A | ~$0.08 |
| `anthropic/claude-sonnet-4-5` | Reasoning, code gen, multi-step tasks | ~$0.90 |
| `anthropic/claude-opus-4` | Complex agentic workflows, long context | ~$4.50 |
| `openai/gpt-4o-mini` | Simple summarisation, cheap fallback | ~$0.04 |
| `openai/gpt-4o` | Vision tasks, structured extraction | ~$1.50 |

  Costs are approximate input+output blended. Always confirm with the user — never assume.
- Define a thin provider wrapper so the model can be swapped without rewriting feature logic
- Wrapper interface: `{ complete(prompt, options) }` — hide provider-specific SDK details behind it
- Log: model name used, token counts in + out, latency, request ID on every call
- Rate limiting and fallback: if OpenRouter returns a provider error, surface it — don't silently retry with a different model

---

## Hooks

All hooks are installed by `/init` into `~/.claude/settings.json`.

### Hook 0 — Plugin Update Notifier (Context Injection)
- **Trigger**: `PreToolUse` — first tool call of any session
- **Logic**: Runs `git -C ~/roambee-claude fetch --quiet && git -C ~/roambee-claude rev-list HEAD..origin/main --count` to check if the local plugin is behind remote
- **On behind**: Outputs "roambee-claude plugin has X new commit(s). Run `git pull` in `~/roambee-claude/` or run `/doctor` to apply updates."
- **On up to date**: Passes silently. Runs once per session only.

### Hook 1 — Architecture Check (Hard Block)
- **Trigger**: `PreToolUse` — first `Write` or `Edit` of any session where the working directory is inside a git repo
- **Logic**: Check if `architecture.md` exists at the git repo root (`git rev-parse --show-toplevel`)
- **On missing**: Output message telling Claude to stop and ask the developer to run `/new-repo` first. Hard block.
- **On present**: Pass silently (checked once per session, not on every file)

### Hook 2 — Path-Aware Skill Reminder (Context Injection)
- **Trigger**: `PreToolUse` on `Write` or `Edit` for `.tsx` / `.jsx` files
- **Logic**: Analyze the file path being written:

| File path pattern | Reminder injected |
|-------------------|------------------|
| `src/components/**` | Load `decklar-ui-library` |
| `src/api/hooks/**` | Load `decklar-api-integration` |
| `src/api/services/**` | Load `decklar-api-integration` |
| `App.tsx` | Load `decklar-header-integration` |
| New file in `packages/client/<new>/` | Load `decklar-app-scaffold` or `hive-app-creator` |

- **Output**: One-line context injection. Not a hard block — Claude self-checks.

### Hook 3 — CI File Warning (Context Injection)
- **Trigger**: `PreToolUse` on `Write` or `Edit` matching `.github/workflows/**` or `Jenkinsfile`
- **Output**: "You are editing a CI/CD configuration file. This affects all developers on the team. Be conservative, verify the change won't break the pipeline, and confirm the target environment before proceeding."

### Hook 4 — Pre-Commit Quality Gate (Hard Block)
- **Trigger**: `PreToolUse` on `Bash` commands containing `git commit`
- **Logic**: Scans staged diff for:
  - `console.log(` in non-test files
  - `debugger`
  - Obvious secret patterns (see Hook 6)
  - Architecture-impacting changes without corresponding `architecture.md` or `README.md` update (see logic below)
- **Architecture/README staleness check**: if staged diff contains any of the following, check whether `architecture.md` or `README.md` is also in the staged files. If not, context inject: "These changes may affect the project architecture or README. Review and update them before committing."
  - New files under `routers/`, `controllers/`, `services/`, `modules/`
  - Changes to `package.json` `dependencies` or `devDependencies`
  - New environment variable references (`process.env.*`, `os.environ[*]`)
  - New packages added under `packages/` in the monorepo root
  - Changes to entry points (`main.ts`, `index.ts` at root level, `App.tsx`)
- **On violation**: Blocks commit and lists what must be fixed first (quality issues = hard block; doc staleness = context injection only, developer decides)

### Hook 5 — Migration Safety (Hard Block)
- **Trigger**: `PreToolUse` on `Bash` commands matching `dev:migration:up` or `migration:run`
- **Logic**: Reads the migration file about to be applied, checks for:
  - `DROP TABLE`, `DROP COLUMN`
  - `TRUNCATE`
  - `ALTER COLUMN` with type changes that lose data
- **On match**: Blocks and surfaces the destructive operation for explicit user confirmation

### Hook 6 — Secret Scan (Hard Block)
- **Trigger**: `PreToolUse` on `Write` or `Edit` for any file
- **Logic**: Scans content being written for patterns:
  - `AKIA[A-Z0-9]{16}` (AWS access key)
  - `Bearer [A-Za-z0-9\-_]{20,}`
  - `password\s*=\s*["'][^"']{6,}`
  - `.env` files being written outside of `.env.example`
- **On match**: Hard block with specific pattern identified

### Hook 7 — Dependency Governance (Context Injection)
- **Trigger**: `PreToolUse` on `Write` or `Edit` for `package.json` or `pyproject.toml`
- **Logic**: Detects new dependencies being added
- **Output**: "You are adding a new dependency. Check if an equivalent already exists in the monorepo before proceeding. UI components must use `@decklar/ui-library`. Python LLM calls must go through OpenRouter."

### Hook 8 — Prompt-as-Code Reminder (Context Injection)
- **Trigger**: `PreToolUse` on `Write` or `Edit` for `.py` or `.ts` files
- **Logic**: Detects string literals over ~300 characters (likely a prompt)
- **Output**: "This looks like a prompt string. Consider extracting it to a dedicated prompt file (`prompts/feature-name.md`) so it can be versioned and reviewed independently."

### Hook 9 — AI Observability Reminder (Context Injection)
- **Trigger**: `PreToolUse` on `Write` or `Edit` for files in `packages/ai/**`
- **Output**: "You are editing an AI service. Ensure: (1) LLM calls log model name, token counts, and latency. (2) No raw user input or PII is logged. (3) All LLM calls go through OpenRouter."

### Hook 10 — Environment Guard (Context Injection)
- **Trigger**: `PreToolUse` on `Bash` commands matching database connection strings or deploy commands targeting non-localhost
- **Output**: "This command may target a non-local environment. Confirm the target environment (dev / staging / prod) before proceeding."

### Hook 11 — PII Field Detector (Context Injection)
- **Trigger**: `PreToolUse` on `Write` or `Edit` for `.ts`, `.tsx`, `.py` files
- **Logic**: Scans content being written for field names matching PII patterns:
  - Property/column names: `email`, `phone`, `mobile`, `address`, `location`, `fullName`, `firstName`, `lastName`, `dateOfBirth`, `dob`, `ssn`, `nationalId`, `passport`
  - Also catches camelCase variants and snake_case variants
- **On match**: Context injection (not a hard block) — "This field (`{fieldName}`) may contain PII. Before proceeding confirm: (1) is it encrypted at rest? (2) is it excluded from logs? (3) does it comply with the data retention policy?"
- **Scope**: Triggers on entity definitions, API response types, and log statements — not on UI display components where the field is read-only

### Hook 12 — Cross-Package Import Guard (Hard Block)
- **Trigger**: `PreToolUse` on `Write` or `Edit` for `.ts` / `.tsx` files inside `packages/client/**`
- **Logic**: Scans the import statements in the file being written. Detects any import whose path crosses MFE boundaries:
  - Pattern: `from '../../<other-mfe-package>/src/...'` or `from '@roambee/<other-mfe-package>'` where the source and target are both under `packages/client/` but are different package directories
- **On match**: Hard block — "Direct import from another MFE (`{package}`) detected. Cross-MFE communication must go through the shared `EventEmitter` or shared utilities in `packages/shared/`. Direct imports break module federation at runtime."
- **Exceptions**: Imports from `packages/shared/`, `@decklar/ui-library`, and `@roambee/client-utility` are allowed

### Hook 13 — Environment Variable Governance (Hard Block)
- **Trigger**: `PreToolUse` on `Write` or `Edit` for `.ts`, `.tsx`, `.py` files
- **Logic**: Scans content being written for new environment variable references:
  - `process.env.SOME_VAR` (TypeScript/JavaScript)
  - `os.environ['SOME_VAR']` or `os.environ.get('SOME_VAR')` (Python)
  - Compares each found var against the contents of `.env.example` at the repo root
- **On missing from `.env.example`**: Hard block — "Environment variable `SOME_VAR` is referenced in code but not declared in `.env.example`. Add it with a placeholder value and a comment describing what it is before proceeding."
- **Rationale**: Silent missing env vars are one of the most common causes of "works on my machine" failures during onboarding and in CI

### Hook 14 — Swagger/OpenAPI Enforcement (Context Injection)
- **Trigger**: `PreToolUse` on `Write` or `Edit` for `*.controller.ts` files
- **Logic**: Detects new HTTP method decorators being added: `@Get(`, `@Post(`, `@Put(`, `@Patch(`, `@Delete(`
- **Checks**: Whether the same file content includes matching `@ApiOperation(`, `@ApiResponse(`, and `@ApiTags(` for each new endpoint
- **On missing Swagger decorators**: Context injection — "New endpoint detected without Swagger documentation. Add `@ApiOperation()`, `@ApiResponse()`, and ensure `@ApiTags()` is on the controller class. Undocumented endpoints accumulate quickly."
- Not a hard block — but fires on every new endpoint until decorators are present

### Hook 15 — Subagent Documentation Update (Context Injection)
- **Trigger**: `PostToolUse` — fires after any `Write` or `Edit` tool call made by a subagent (detected via subagent context flag)
- **Logic**: At the end of each subagent's task, before transitioning the Jira ticket to Done, checks if any of the following were modified:
  - New service, module, or controller created
  - New package added to monorepo
  - New external dependency or environment variable added
  - Entry point or top-level config changed
- **On match**: Injects into the subagent's context: "Before marking this task Done — review `architecture.md` and `README.md`. If what you built changes the architecture, external dependencies, environment setup, or how to run the service, update those files now and include them in the commit."
- Ensures docs evolve with code across every subagent task, not just at PR time

---

## Universal `~/.claude/CLAUDE.md`

Content installed by `/init`. Covers:

- **Git workflow**: branch naming (`<type>/<TICKET-ID>/<title>`), cut from fresh `origin/dev`, one ticket per branch
- **Commit format**: conventional commits, no `Co-Authored-By: Claude` lines
- **Planning rule**: never begin implementation of a plan without a Jira ticket. Use `/plan` to write plans — it creates tickets automatically. If a plan already exists in the conversation with no ticket, ask the user for the ticket ID before writing any code.
- **Branch context rule**: if already on a branch with a ticket ID, ask the user whether the new work belongs to that ticket or needs a new one — infer from context (bug fix = same branch, new feature = new branch) but always confirm before acting.
- **Skill invocation order**: implement → run tests → `feature-dev:code-reviewer` → `code-simplifier` → update docs if needed → commit → `/pr`
- **Subagent protocol**: always include `## Flags` section, never make autonomous decisions. Before marking any task Done: update `architecture.md` and `README.md` if what was built affects them.
- **PR policy**: always use `/pr` skill — never open a PR manually or without running tests first. `/pr` handles Jira transition and comment automatically.
- **Docs update rule**: `architecture.md` and `README.md` are living documents. Any commit that adds a new service, changes how the project is run locally, adds environment variables, or changes the tech stack must include updates to those files in the same commit. Stale docs are treated the same as stale tests — a sign the work isn't complete.
- **AI development**: always use OpenRouter, always ask user for model + task before writing LLM code, prompts are versioned files not inline strings
- **Code style**: no comments unless WHY is non-obvious, no docstrings, no backwards-compat shims
- **CI context summary**: what the pipeline checks (lint, tests, build) — so Claude knows what will fail

---

## Repo-level `architecture.md` (generated by `/new-repo`)

Every repo must have this file at its root. The architecture check hook (Hook 1) hard-blocks any session in a repo that is missing it.

Template:
```markdown
# [Service/App Name] — Architecture

## Overview
[One paragraph: what this service does and who uses it]

## Tech Stack
[Language, framework, DB, key libraries]

## Key Modules
[Table: module name → responsibility]

## External Dependencies
[APIs, databases, queues, other services this talks to]

## Environment Variables
See `.env.example`. Required: [list key vars]

## Local Dev Setup
[Steps to get running locally]

## Running Tests
[Commands]

## Deployment
[CI/CD pipeline, environments, deploy command]
```

---

## Decisions

### AWS CodeArtifact (`/init`)
Cannot be automated — requires asking the user the first time. `/init` prompts for `ACCOUNT_ID`, `region`, and `profile` on first run, saves them to `~/.claude/roambee-config.json`. Subsequent runs (and `/doctor`) read from that file without re-prompting. Token refresh is still manual (12h TTL) but credentials are not re-entered.

### OpenRouter base URL and auth pattern
Do not hardcode. `/init` checks the monorepo root `.env` / `.env.example` for `OPENROUTER_API_KEY` and base URL. If not found, asks the user during first AI service spec (the `provider-abstraction` skill prompts: "what OpenRouter endpoint and key env var should be used here?"). Answer is saved to `~/.claude/roambee-config.json` for reuse.

### `architecture.md` exemption
Opt-out via a flag file inside the repo: if `.no-architecture-check` exists at the repo root, Hook 1 passes silently. Developer (or repo owner) places this file intentionally in POCs, throwaway scripts, or the `roambee-claude` plugin repo itself.

### `/doctor` auto-fix
Should auto-fix what it can: re-run CodeArtifact login (if credentials saved), overwrite `~/.claude/CLAUDE.md` to latest version, patch missing hooks into `settings.json`. For things it cannot fix (missing plugins), report with instructions.

### Testing coverage thresholds
Deferred — needs more discussion. Placeholder remains in `testing-standards` skill.

### Prompt-as-code hook scope
Leave at all `.py`/`.ts` files for now. Revisit if false-positive rate is too high.

### Jenkins / CI ownership
No standard `Jenkinsfile` pattern from the developer side — CI is exclusively owned by DevOps. Hook 3 (CI file warning) is sufficient. No `ci-standards` skill needed.

### Skill tracks / `plugin.json`
Install all skills for all developers. No manual track selection. The plugin uses conversation context to determine which track applies — if the session is in a React MFE, App track skills fire; if in `packages/ai/`, AI track skills fire. A developer who later starts working across both tracks gets both automatically.

---

## Rollout Plan (rough)

1. **Phase 1 — Local (now)**: Build plugin at `~/roambee-claude/`, test on your own machine
2. **Phase 2 — Small team**: Share with 2-3 trusted devs, collect feedback, fill open questions
3. **Phase 3 — GitHub org repo**: Push to `github.com/roambee/claude-code-standards`, switch each developer's `extraKnownMarketplaces.roambee` entry to `{ "source": "github", "repo": "roambee/claude-code-standards" }`
4. **Phase 4 — Company rollout**: Update developer onboarding docs, announce, have devs run `/init`
