# /init — Decklar Machine Setup

Run once per developer machine. Idempotent — safe to re-run.

**Announce at start:** "Running /init to set up your Decklar Claude Code environment."

```bash
PLUGIN_DIR=$(python3 -c "
import json, os
try:
    data = json.load(open(os.path.expanduser('~/.claude/plugins/installed_plugins.json')))
    for key, installs in data.get('plugins', {}).items():
        if 'decklar-claude' in key:
            p = installs[0].get('installPath', '')
            if p and os.path.exists(p):
                print(p)
                exit()
except: pass
print('')
")
[ -z "$PLUGIN_DIR" ] && { echo "❌ decklar-claude plugin not found in installed_plugins.json. Is the plugin installed?"; exit 1; }
```

---

## Step 1: AWS CodeArtifact

Check for saved credentials:
```bash
python3 -c "
import json, os
p = os.path.expanduser('~/.claude/decklar-config.json')
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

Save to `~/.claude/decklar-config.json` (merge, don't overwrite):
```bash
python3 -c "
import json, os
p = os.path.expanduser('~/.claude/decklar-config.json')
d = {}
try: d = json.load(open(p))
except: pass
d.setdefault('codeartifact', {}).update({
    'accountId': '<ACCOUNT_ID>',
    'region': '<REGION>',
    'profile': '<PROFILE>'
})
d['pluginDir'] = '$PLUGIN_DIR'
os.makedirs(os.path.dirname(p), exist_ok=True)
json.dump(d, open(p, 'w'), indent=2)
print('Credentials saved.')
"
```

Authenticate:
```bash
aws codeartifact login --tool npm \
  --domain decklar \
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
cp "$PLUGIN_DIR/templates/CLAUDE.md" ~/.claude/CLAUDE.md
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
hooks_patch_path = '$PLUGIN_DIR/docs/hooks-settings-patch.json'

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
plugin_path = '$PLUGIN_DIR/.claude-plugin/plugin.json'

settings = {}
try: settings = json.load(open(settings_path))
except: pass

plugin = json.load(open(plugin_path))
deps = plugin.get('dependencies', [])

settings.setdefault('plugins', {})
for p in deps:
    if p['name'] not in settings['plugins']:
        settings['plugins'][p['name']] = {'source': p['source']}
        print(f'  Added plugin: {p[\"name\"]}')

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
5. Ask the developer: "Which Jira site? (e.g. decklar.atlassian.net)"
6. Ask: "What is the Jira project key? (e.g. RMB)"
7. Save to `~/.claude/decklar-config.json`:

```bash
python3 -c "
import json, os
p = os.path.expanduser('~/.claude/decklar-config.json')
d = {}
try: d = json.load(open(p))
except: pass
d['jira'] = {'domain': '<DOMAIN>', 'projectKey': '<PROJECT_KEY>'}
json.dump(d, open(p, 'w'), indent=2)
print('✅ Jira config saved.')
"
```

---

## Step 7: GitHub CLI

```bash
if ! command -v gh &>/dev/null; then
  echo "❌ GitHub CLI (gh) is not installed."
  echo "   Install: brew install gh"
  echo "   Then re-run /init to complete this step."
else
  gh auth status 2>&1 | grep -q "Logged in" \
    && echo "✅ GitHub CLI already authenticated" \
    || gh auth login
fi
```

If `gh auth login` is triggered, follow the browser prompt. When done, verify with `gh auth status`.

---

## Step 8: Decklar Wiki Setup

Ask the developer: **"What's your name for the wiki? (e.g. heet, heet-shah — this is your identity in the shared company knowledge base)"**

Save wiki config to `~/.claude/decklar-config.json`:

```bash
python3 -c "
import json, os
p = os.path.expanduser('~/.claude/decklar-config.json')
d = {}
try: d = json.load(open(p))
except: pass
d['wiki'] = {
    'endpoint': 'https://memory-staging.decklar.com',
    'worldName': 'decklar-wiki',
    'agentName': '<AGENT_NAME>',
    'apiKeyEnvVar': 'WIKI_API_KEY',
    'accountIdEnvVar': 'WIKI_ACCOUNT_ID'
}
json.dump(d, open(p, 'w'), indent=2)
print('Wiki config saved.')
"
```

Auto-export wiki credentials from plugin config into `~/.zshrc` and the current session:

```bash
CREDS_FILE="$PLUGIN_DIR/config/wiki-env.sh"
ZSHRC="$HOME/.zshrc"
MARKER="# decklar-wiki-env"

if ! grep -q "$MARKER" "$ZSHRC" 2>/dev/null; then
  echo "" >> "$ZSHRC"
  echo "$MARKER" >> "$ZSHRC"
  cat "$CREDS_FILE" >> "$ZSHRC"
fi

source "$CREDS_FILE"
echo "✅ Wiki credentials exported"
```

Create the `decklar-wiki` world if it does not exist:

```bash
python3 -c "
import json, os, subprocess, sys

endpoint = 'https://memory-staging.decklar.com'
api_key = os.environ.get('WIKI_API_KEY', '')
account_id = os.environ.get('WIKI_ACCOUNT_ID', '')

if not api_key or not account_id:
    print('Skipping world creation — env vars not set.')
    sys.exit(0)

# Check if world already exists
r = subprocess.run([
    'curl', '-s',
    f'{endpoint}/v1/worlds?account_id={account_id}&is_active=true',
    '-H', f'apikey: {api_key}',
    '-H', f'x-account-id: {account_id}'
], capture_output=True, text=True)

try:
    worlds = json.loads(r.stdout)
    worlds = worlds if isinstance(worlds, list) else worlds.get('data', worlds.get('worlds', worlds.get('items', [])))
    names = [w.get('world_name', '') for w in worlds if isinstance(w, dict)]
    if 'decklar-wiki' in names:
        print('World decklar-wiki already exists — skipping creation.')
        sys.exit(0)
except:
    pass

# Create world
payload = json.dumps({
    'account_id': account_id,
    'world_name': 'decklar-wiki',
    'description': 'Decklar company knowledge base',
    'is_active': True
})
r = subprocess.run([
    'curl', '-s', '-X', 'POST', f'{endpoint}/v1/worlds',
    '-H', f'apikey: {api_key}',
    '-H', f'x-account-id: {account_id}',
    '-H', 'Content-Type: application/json',
    '-d', payload
], capture_output=True, text=True)

print('World created:', r.stdout[:200] if r.stdout else r.stderr[:200])
"
```

Tell the developer:
```
✅ Decklar Wiki configured.
   World: decklar-wiki
   Agent name: <AGENT_NAME>
   hook-17 will digest your sessions automatically.
   hook-18 will inject wiki context at session start.
   Use /wiki to query or save knowledge manually.
```

---

## Step 7: Summary

Print a checklist of what was completed:

```
✅ AWS CodeArtifact authenticated (token valid 12h)
✅ ~/.claude/CLAUDE.md installed
✅ Hooks installed (will be active after restart)
✅ Required plugins added to settings.json
✅ Playwright Chromium installed
✅ Atlassian MCP authenticated — project: <PROJECT_KEY>
✅ GitHub CLI authenticated
✅ Decklar Wiki configured — world: decklar-wiki, agent: <AGENT_NAME>

Run /doctor at any time to verify the setup is still healthy.
```
