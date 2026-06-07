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
