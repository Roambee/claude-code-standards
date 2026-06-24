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
