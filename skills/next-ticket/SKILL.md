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
