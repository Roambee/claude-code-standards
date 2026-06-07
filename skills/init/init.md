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

Note: token expires after 12h. Re-run `/init` or `/doctor` to refresh.

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
    if event.startswith('_'): continue
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
