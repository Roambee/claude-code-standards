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
🚀 Roambee v2.4.0 is here!

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
