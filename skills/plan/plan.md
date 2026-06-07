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

Read `~/.claude/roambee-config.json` for `jira.projectKey` and `jira.domain`.

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
