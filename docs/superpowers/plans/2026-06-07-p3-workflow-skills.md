# Decklar Claude Plugin — P3: Workflow Skills

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans` to implement this plan task-by-task.

**Goal:** Write the five Jira-integrated workflow skills: `/plan`, `/pr`, `/next-ticket`, `/standup`, `/release-notes`.

**Architecture:** Each skill is a markdown file Claude reads and follows. All skills read from `~/.claude/decklar-config.json` for Jira domain and project key. All Jira operations use the Atlassian MCP (`mcp__claude_ai_Atlassian__*` tools).

**Tech Stack:** Claude Code skill markdown format, Atlassian MCP, GitHub MCP (`gh`), Git bash commands.

**Prerequisite:** P1 complete — `~/.claude/decklar-config.json` schema established, Atlassian MCP authenticated via `/init`.

**Design spec reference:** Skills section of `2026-06-06-decklar-claude-standards-plugin-design.md`

---

## File Map

| Action | Path | Responsibility |
|--------|------|----------------|
| Create | `skills/plan/plan.md` | Jira-aware planning wrapper |
| Create | `skills/pr/pr.md` | PR creation with Jira linkage |
| Create | `skills/next-ticket/next-ticket.md` | Sprint ticket picker + branch creator |
| Create | `skills/standup/standup.md` | Daily standup generator |
| Create | `skills/release-notes/release-notes.md` | Changelog from Jira |

---

## Task 1: `skills/plan/plan.md`

**Files:**
- Create: `skills/plan/plan.md`

- [ ] **Step 1: Create the file**

````markdown
# /plan — Jira-Aware Planning

Wraps `superpowers:writing-plans`. Always use `/plan` instead of raw planning — it ensures a Jira ticket exists before implementation begins.

**Announce at start:** "Using /plan to create a Jira-linked implementation plan."

---

## Step 1: Read Branch Context

```bash
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
TICKET=$(echo "$BRANCH" | grep -oE 'RMB-[0-9]+' || echo "")
echo "Branch: $BRANCH"
echo "Ticket: $TICKET"
```

---

## Step 2: Classify Intent from Conversation

Read the current conversation. Classify as one of:
- **bug-fix**: conversation mentions an error, exception, broken behaviour, stack trace, or the user has been debugging
- **new-feature**: conversation discusses new functionality, a new screen, new API, or new service

---

## Step 3: Decide Branch + Ticket Strategy

| Scenario | Action |
|----------|--------|
| Branch has `RMB-XXXX` + bug-fix context | Ask: "Are we fixing [RMB-XXXX] on this branch, or is this a separate new feature?" |
| Branch has `RMB-XXXX` + new-feature context | Ask: "This looks like a new feature. New branch + ticket, or add to [RMB-XXXX]?" |
| No ticket in branch + any context | New ticket required — proceed to Step 4 |
| User confirms existing ticket | Fetch ticket details via `mcp__claude_ai_Atlassian__getJiraIssue` and skip to Step 5 |

---

## Step 4: Determine Ticket Scope

Ask the user:
> "What is the scope of this change?
> 1. Large feature — Story with Tasks under it
> 2. Medium change — Task with Sub-tasks
> 3. Small fix — Single Task or Sub-task"

Wait for answer. Do not assume.

Read `~/.claude/decklar-config.json` for `jira.projectKey` and `jira.domain`.

**If Large (Story + Tasks):**
1. Call `mcp__claude_ai_Atlassian__createJiraIssue` — type: Story, summary: [feature name]
2. For each major phase of the planned work, call `mcp__claude_ai_Atlassian__createJiraIssue` — type: Task, parent: Story key

**If Medium (Task + Sub-tasks):**
1. Call `mcp__claude_ai_Atlassian__createJiraIssue` — type: Task, summary: [change name]
2. For each step in the plan, call `mcp__claude_ai_Atlassian__createJiraIssue` — type: Sub-task, parent: Task key

**If Small (Single Task):**
1. Ask: "Is this a sub-task under an existing ticket? If yes, which one?"
2. Call `mcp__claude_ai_Atlassian__createJiraIssue` accordingly

Display all created ticket IDs and links. Suggest branch name:
```
feat/RMB-XXXX/short-description-of-work
```
Ask: "Create this branch now?"
If yes:
```bash
git checkout -b feat/RMB-XXXX/short-description origin/dev
```

---

## Step 5: Write the Plan

Invoke `superpowers:writing-plans` with full context. The plan header must include all Jira ticket IDs.

---

## Step 6: Subagent Execution Instructions

When the plan is executed by subagents, each subagent must:
- On task start: call `mcp__claude_ai_Atlassian__transitionJiraIssue` → **In Progress**
- On task complete (tests passing): upload Playwright screenshot or test output, add Jira comment, call `mcp__claude_ai_Atlassian__transitionJiraIssue` → **Done**
- On blocker: call `mcp__claude_ai_Atlassian__addCommentToJiraIssue` with blocker description, report in `## Flags`
- Parent ticket: In Progress when first sub-task starts; Done only when all sub-tasks are Done
- Never mark Done if tests have not passed
````

- [ ] **Step 2: Commit**

```bash
git add skills/plan/plan.md
git commit -m "feat: add /plan Jira-aware planning skill"
```

---

## Task 2: `skills/pr/pr.md`

**Files:**
- Create: `skills/pr/pr.md`

- [ ] **Step 1: Create the file**

````markdown
# /pr — Pull Request Creation

Always use `/pr` to open PRs. Never open a PR manually. This skill confirms tests pass, creates the PR with a standard template, links Jira, and transitions the ticket.

**Announce at start:** "Using /pr to create a pull request."

---

## Step 1: Confirm Tests Pass

```bash
npm test 2>&1 | tail -5
```

If tests fail: output "STOP: Tests are failing. Fix them before opening a PR." and halt.

---

## Step 2: Read Branch and Ticket

```bash
BRANCH=$(git rev-parse --abbrev-ref HEAD)
TICKET=$(echo "$BRANCH" | grep -oE 'RMB-[0-9]+')
```

Fetch ticket details: `mcp__claude_ai_Atlassian__getJiraIssue` with the ticket key.

---

## Step 3: Detect Reviewers from CODEOWNERS

```bash
REPO_ROOT=$(git rev-parse --show-toplevel)
CHANGED_PACKAGES=$(git diff origin/dev...HEAD --name-only | grep -oE 'packages/[^/]+' | sort -u)
```

For each changed package, look up `.github/CODEOWNERS` for matching entries. Collect reviewer handles. If `CODEOWNERS` is missing, skip reviewer assignment.

---

## Step 4: Generate PR Body

Use this template (fill in from ticket details and git log):

```markdown
## Summary
[Jira ticket title and one-line description of what was built]

## Changes
[Bullet list of key files changed and why — from git diff summary]

## Test Plan
- [ ] Unit tests passing (`npm test`)
- [ ] E2E tests passing (`npm run test:e2e`)
- [ ] Playwright screenshot attached to Jira ticket [RMB-XXXX]

## Jira
[RMB-XXXX](https://[domain]/browse/RMB-XXXX)
```

---

## Step 5: Confirm with User

Show the PR title, target branch (dev), and reviewer list.
Ask: "Open this PR? [y/n]"

If no: stop. Developer can edit the summary and re-run `/pr`.

---

## Step 6: Create PR

```bash
gh pr create \
  --title "[RMB-XXXX] <ticket title>" \
  --body "<generated body>" \
  --base dev \
  --reviewer "<handles>"
```

---

## Step 7: Update Jira

1. Call `mcp__claude_ai_Atlassian__transitionJiraIssue` → **In Review**
2. Call `mcp__claude_ai_Atlassian__addCommentToJiraIssue`:
   > "PR opened: [PR URL]"

Output: "✅ PR created: [URL]. Jira ticket [RMB-XXXX] transitioned to In Review."
````

- [ ] **Step 2: Commit**

```bash
git add skills/pr/pr.md
git commit -m "feat: add /pr pull request skill"
```

---

## Task 3: `skills/next-ticket/next-ticket.md`

**Files:**
- Create: `skills/next-ticket/next-ticket.md`

- [ ] **Step 1: Create the file**

````markdown
# /next-ticket — Sprint Ticket Picker

Pick up your next Jira task and create the branch without touching Jira manually.

**Announce at start:** "Fetching your sprint tickets from Jira."

---

## Step 1: Fetch Sprint Tickets

Read `~/.claude/decklar-config.json` for `jira.projectKey`.

Call `mcp__claude_ai_Atlassian__searchJiraIssuesUsingJql`:
```
project = <projectKey> AND assignee = currentUser()
AND sprint in openSprints()
AND status in ("To Do", "In Progress")
ORDER BY priority DESC, status ASC
```

---

## Step 2: Display and Pick

Show a numbered list:
```
Your open sprint tickets:
1. [RMB-1234] Add shipment export feature          [To Do] [High]
2. [RMB-1235] Fix roles redirect bug               [In Progress] [Medium]
3. [RMB-1236] Update user management pagination    [To Do] [Low]

Pick a number (or 0 to cancel):
```

Wait for input.

---

## Step 3: Act on Selection

**If status is "To Do":**
1. Fetch full ticket: `mcp__claude_ai_Atlassian__getJiraIssue`
2. Display ticket description and acceptance criteria
3. Suggest branch name: `feat/RMB-XXXX/short-title-in-kebab-case`
4. Ask: "Create this branch and start work? [y/n]"
5. If yes:
   ```bash
   git checkout -b feat/RMB-XXXX/short-title origin/dev
   ```
6. Transition to In Progress: `mcp__claude_ai_Atlassian__transitionJiraIssue`

**If status is "In Progress":**
Ask: "This ticket is already In Progress. Resume work on it, or pick a different one? [resume/pick]"
If resume: fetch ticket details and display them. If pick: return to Step 2.
````

- [ ] **Step 2: Commit**

```bash
git add skills/next-ticket/next-ticket.md
git commit -m "feat: add /next-ticket sprint picker skill"
```

---

## Task 4: `skills/standup/standup.md`

**Files:**
- Create: `skills/standup/standup.md`

- [ ] **Step 1: Create the file**

````markdown
# /standup — Daily Standup Generator

Generates a standup draft from git activity and Jira ticket state.

**Announce at start:** "Generating your standup from git log and Jira."

---

## Step 1: Gather Git Activity

```bash
git log --since=yesterday --author="$(git config user.email)" \
  --pretty=format:"%s %D" --all 2>/dev/null | head -20
```

Group commits by Jira ticket ID (extract `RMB-\d+` from commit messages and branch names):
```bash
git branch -a --contains HEAD | grep -oE 'RMB-[0-9]+' | head -5
```

---

## Step 2: Fetch Ticket Status

For each unique ticket ID found, call `mcp__claude_ai_Atlassian__getJiraIssue` to get current status and title. If Atlassian MCP is unavailable, skip this step and use commit messages only.

---

## Step 3: Determine Today's Work

Ask the user: "What are you picking up today? (Press Enter to pull from your In Progress Jira tickets)"

If Enter: call `mcp__claude_ai_Atlassian__searchJiraIssuesUsingJql`:
```
project = <projectKey> AND assignee = currentUser() AND status = "In Progress"
```

---

## Step 4: Format Standup Draft

```
Yesterday:
- [RMB-1234] <ticket title> — <one-line summary of what was done> (<status: merged/in review/in progress>)
- [RMB-1235] <ticket title> — <one-line summary>

Today:
- [RMB-1236] <ticket title>

Blockers: [none / describe blocker]
```

Output the draft. Tell the developer: "Review and edit before sending. This is a draft."
````

- [ ] **Step 2: Commit**

```bash
git add skills/standup/standup.md
git commit -m "feat: add /standup daily standup generator skill"
```

---

## Task 5: `skills/release-notes/release-notes.md`

**Files:**
- Create: `skills/release-notes/release-notes.md`

- [ ] **Step 1: Create the file**

````markdown
# /release-notes — Changelog Generator

Generates a formatted changelog from Jira tickets resolved in a date range.

**Announce at start:** "Generating release notes from Jira."

---

## Step 1: Gather Parameters

Ask the user:
1. "What is the release version? (e.g. v2.4.0)"
2. "Date range or git tag comparison?"
   - Date range: "from YYYY-MM-DD to YYYY-MM-DD"
   - Tag comparison: "since tag v2.3.0"

If tag comparison:
```bash
git log v2.3.0..HEAD --pretty=format:"%s" | grep -oE 'RMB-[0-9]+' | sort -u
```

---

## Step 2: Fetch Resolved Tickets

Call `mcp__claude_ai_Atlassian__searchJiraIssuesUsingJql`:
```
project = <projectKey>
AND status = Done
AND resolved >= "<startDate>"
AND resolved <= "<endDate>"
ORDER BY issuetype ASC, priority DESC
```

---

## Step 3: Group and Format

**Developer Changelog (markdown — for GitHub Releases):**
```markdown
## v2.4.0 — 2026-06-07

### Features
- [RMB-1234] Add shipment export to CSV
- [RMB-1238] User management pagination improvements

### Bug Fixes
- [RMB-1235] Fix roles redirect on login
- [RMB-1241] Resolve API timeout on large shipment lists

### Internal
- [RMB-1237] Upgrade NestJS to v10.3
- [RMB-1240] Migrate auth middleware to comply with data retention policy
```

**Product Changelog (plain English — for Confluence or Slack):**
```
🚀 Decklar v2.4.0 is here!

✨ New features:
• Export shipment data to CSV directly from the dashboard
• Improved pagination for large user lists

🐛 Bug fixes:
• Login now correctly redirects to your assigned role's home screen
• Fixed API timeouts when loading large shipment lists

This release is live on production. Questions? Reach out to #engineering.
```

---

## Step 4: Optional Confluence Publish

Ask: "Post the product changelog to Confluence? If yes, which space and page title?"

If yes: call `mcp__claude_ai_Atlassian__updateConfluencePage` or `mcp__claude_ai_Atlassian__createConfluencePage` with the plain-English version.
````

- [ ] **Step 2: Commit**

```bash
git add skills/release-notes/release-notes.md
git commit -m "feat: add /release-notes changelog generator skill"
```

---

## Task 6: End-to-End Verification

- [ ] **Step 1: Verify `/plan` detects branch context**

On a branch named `feat/RMB-9999/test`, invoke `/plan`. Expected: Claude detects the ticket ID and asks whether this is a bug fix or new feature.

- [ ] **Step 2: Verify `/next-ticket` fetches Jira tickets**

Invoke `/next-ticket`. Expected: Claude calls Atlassian MCP and displays a numbered list of your sprint tickets.

- [ ] **Step 3: Verify `/pr` blocks on failing tests**

Introduce a deliberate test failure. Invoke `/pr`. Expected: Claude detects failing tests and refuses to open a PR.

- [ ] **Step 4: Final commit**

```bash
git status
git commit -m "chore: P3 complete — workflow skills implemented"
```
