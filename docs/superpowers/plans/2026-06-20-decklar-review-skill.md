# /decklar-review Skill Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a `/decklar-review` skill that reviews a git diff for Decklar standards violations and over-engineering patterns in one flat tagged list, and declare `ponytail` as an explicit plugin dependency.

**Architecture:** Pure-markdown skill — no scripts or helpers. The SKILL.md instructs Claude to run `git diff main` or `git diff --staged`, scan `+` lines for 13 named tags across standards and over-engineering categories, and print one finding per line. Plugin dependency declaration is a single JSON line.

**Tech Stack:** Markdown (SKILL.md), JSON (plugin.json)

## Global Constraints

- Scan `+` lines only — never flag context lines or deletions
- Do not apply fixes — review only, report only
- Output format is strict: `<file>:L<line>: <tag>: <what>. <fix>.`
- Final summary line: `<N> findings. net: -<M> lines possible.` where M covers over-engineering findings only
- If diff is empty: `Nothing to review.` and stop
- If nothing found: `Clean. Ship.`

---

### Task 1: Declare ponytail as a plugin dependency

**Files:**
- Modify: `.claude-plugin/plugin.json`

**Interfaces:**
- Produces: `ponytail` entry in `dependencies.plugins` array, consistent with existing entry format `{ "name": "...", "source": "..." }`

- [ ] **Step 1: Add the ponytail entry**

In `.claude-plugin/plugin.json`, add to `dependencies.plugins` after the `frontend-design` entry:

```json
{ "name": "ponytail",       "source": "DietrichGebert/ponytail" }
```

The full `dependencies.plugins` array should read:

```json
"plugins": [
  { "name": "superpowers",     "source": "thedotmack/superpowers" },
  { "name": "feature-dev",     "source": "thedotmack/feature-dev" },
  { "name": "code-simplifier", "source": "thedotmack/code-simplifier" },
  { "name": "github",          "source": "github/gh-mcp" },
  { "name": "claude-mem",      "source": "thedotmack/claude-mem" },
  { "name": "hookify",         "source": "thedotmack/hookify" },
  { "name": "coderabbit",      "source": "coderabbit-ai/coderabbit-claude" },
  { "name": "frontend-design", "source": "thedotmack/frontend-design" },
  { "name": "ponytail",        "source": "DietrichGebert/ponytail" }
]
```

- [ ] **Step 2: Verify JSON is valid**

```bash
python3 -c "import json; json.load(open('.claude-plugin/plugin.json')); print('valid')"
```

Expected output: `valid`

- [ ] **Step 3: Commit**

```bash
git add .claude-plugin/plugin.json
git commit -m "feat: add ponytail as explicit plugin dependency"
```

---

### Task 2: Create the /decklar-review skill

**Files:**
- Create: `skills/decklar-review/SKILL.md`

**Interfaces:**
- Consumes: nothing (standalone skill)
- Produces: `decklar-review` skill registered and invocable as `/decklar-review` or `/decklar-review --staged`

- [ ] **Step 1: Create the skill directory and file**

Create `skills/decklar-review/SKILL.md` with the full content below. Copy exactly — the frontmatter, section headers, tag descriptions, examples, and output rules are all load-bearing.

````markdown
---
name: decklar-review
description: >
  Combined PR diff review: Decklar standards violations + over-engineering in
  one flat tagged list. Scans git diff additions only. Use before every merge.
  Trigger: /decklar-review (branch vs main) or /decklar-review --staged (staged only).
argument-hint: "[--staged]"
---

# /decklar-review

Review the current diff for Decklar standards violations and over-engineering. One finding per line. Does not apply fixes.

## Step 1: Get the diff

Check whether the user passed `--staged`.

If `--staged`:
```bash
git diff --staged
```

Otherwise:
```bash
git diff main
```

If the output is empty, print `Nothing to review.` and stop.

## Step 2: Scope

Only examine lines that begin with `+` (but not `+++`). Skip context lines (no prefix) and deletions (`-` prefix). A `console.log` on a `-` line is being removed — correct behavior, do not flag it.

## Step 3: Scan for violations

Check each `+` line against the tags below. Report the first matching tag per line — do not double-tag. For standards tags, use the regex patterns. For over-engineering tags, use judgment on the surrounding block of added code.

### Standards tags

**`cross-mfe:`** — Direct import across MFE packages
- File is under `packages/client/<pkg>/`
- Line imports from `@decklar/<other-pkg>` or a relative `../../` path resolving into another `packages/client/` package
- Allowed targets (do not flag): `@decklar/shared`, `@decklar/client-utility`, anything from `@decklar/decklar`
- Fix: Use EventEmitter for runtime communication, or move shared code to `packages/shared/`

**`secret:`** — Hardcoded credential
- `AKIA[A-Z0-9]{16}` (AWS access key)
- `Bearer [A-Za-z0-9\-_]{20,}` (Bearer token literal)
- `password\s*=\s*['"][^'"]{6,}` (hardcoded password assignment)
- File path ends in `.env` and is not `.env.example`
- Fix: Use environment variables; add a placeholder entry to `.env.example`

**`swagger:`** — API endpoint without documentation
- Line contains `@Get(`, `@Post(`, `@Put(`, `@Patch(`, or `@Delete(`
- The surrounding added block has no `@ApiOperation`, `@ApiResponse`, or `@ApiTags`
- Fix: Add `@ApiTags('resource')` on the controller class, `@ApiOperation({ summary: '' })` and `@ApiResponse({ status: 200 })` on each method

**`pii:`** — PII field without safeguards noted
- Field/property/column name matches (case-insensitive): `email`, `phone`, `mobile`, `address`, `fullName`, `firstName`, `lastName`, `dateOfBirth`, `dob`, `ssn`, `nationalId`, `passportNumber`, `full_name`, `first_name`, `last_name`, `date_of_birth`, `national_id`, `passport_number`
- Fix: Confirm field is encrypted at rest, excluded from logs, and covered by data retention policy before merging

**`env-var:`** — Undeclared environment variable
- Line contains `process.env.<VAR>` and `<VAR>` is not present in `.env.example`
- Read `.env.example` to check. If the file doesn't exist, skip this tag.
- Fix: Add `<VAR>=<placeholder-value>` to `.env.example`

**`migration:`** — Unsafe or malformed migration
- File name contains `migration` and does not start with a 13-digit timestamp (e.g. `1717800000000-`)
- Added lines contain `DROP TABLE`, `DROP COLUMN`, `TRUNCATE`, or `ALTER COLUMN`
- Migration file has no `down()` method in the added lines (check if `async down(` appears anywhere in the file)
- Fix: Add reversible `down()` that undoes `up()` exactly; rename to `<timestamp>-<description>.ts`; confirm destructive ops with the user

**`prompt:`** — Inline prompt string
- A string literal (single-quoted, double-quoted, or backtick) longer than 300 characters
- Fix: Extract to `prompts/<feature-name>.md` so it can be versioned and reviewed independently

**`logging:`** — Wrong logger in NestJS service
- Line contains `console.log(` or `console.error(` and the file contains `@Injectable()`
- Fix: Use `private readonly logger = new Logger(ClassName.name)` imported from `@nestjs/common`; call `this.logger.log()` / `this.logger.error()`

### Over-engineering tags

Apply these to blocks of added code, not individual lines. Report the most specific tag.

**`yagni:`** — Abstraction with no second use
- Interface or abstract class with exactly one implementation in the diff
- Config object or constant whose value never varies across environments
- Middleware, interceptor, or decorator layer with a single caller
- Fix: Inline until a second use exists

**`stdlib:`** — Hand-rolled standard library
- Manual `groupBy`, `chunk`, `flatten`, `debounce`, `throttle`, `deepClone`, `pick`, `omit`, `unique` — all ship in lodash (already a common dep) or native JS
- Hand-rolled date formatter when `Intl.DateTimeFormat` covers it
- Hand-rolled UUID generator when `crypto.randomUUID()` exists
- Fix: Name the stdlib or built-in equivalent

**`native:`** — Dependency doing what the platform already does
- A date/time library imported for a single format call
- A UUID package when `crypto.randomUUID()` is available (Node 14.17+)
- A query-string parser when `URLSearchParams` covers it
- Fix: Name the native API

**`shrink:`** — More lines than needed
- Manual loop that builds an array/object when `.map()`, `.filter()`, `.reduce()`, or `Object.fromEntries()` would be one line
- Explicit `if/else` returning `true`/`false` when a boolean expression suffices
- Fix: Show the shorter form inline in the finding

**`delete:`** — Dead code
- Exported function or class with no importer in the diff (and clearly no existing callers)
- Commented-out code block
- Speculative `// TODO: add X later` stub with no callers
- Fix: Delete it

## Step 4: Output

Order findings by file path alphabetically, then by line number within each file.

Format — one line per finding:
```
<file>:L<line>: <tag>: <what>. <fix>.
```

Keep `<what>` to one clause (what the problem is). Keep `<fix>` to one clause (the concrete action). No newlines inside a finding.

**Examples:**
```
packages/client/shipments/src/Foo.tsx:L3: cross-mfe: imports from @decklar/users-mfe. Use EventEmitter or move to packages/shared/.
src/auth/auth.controller.ts:L12: swagger: @Post endpoint missing @ApiOperation and @ApiResponse. Add both decorators before merge.
src/shipment/shipment.service.ts:L47: logging: console.log inside @Injectable service. Replace with this.logger.log() from @nestjs/common Logger.
src/utils/date.ts:L8: stdlib: hand-rolled date formatter (12 lines). Use Intl.DateTimeFormat — 1 line.
src/utils/date.ts:L22: yagni: DateFormatterInterface with one implementation. Inline until a second exists.
```

After all findings, print exactly one summary line:
```
<N> findings. net: -<M> lines possible.
```

- `N` = total number of findings (all tags)
- `M` = estimated lines removable from over-engineering findings only (yagni/stdlib/native/shrink/delete). Standards findings don't contribute.

If there are no findings at all: print `Clean. Ship.` and stop (no summary line).

## Boundaries

- Additions only — never flag deletions or context lines
- Does not apply fixes — lists findings only
- Does not replace real-time hooks (hook-06, hook-12, etc.) which fire during file writes
- "stop decklar-review" or "normal mode" to revert to default review behavior
````

- [ ] **Step 2: Verify the file exists and frontmatter is intact**

```bash
head -8 skills/decklar-review/SKILL.md
```

Expected output:
```
---
name: decklar-review
description: >
  Combined PR diff review: Decklar standards violations + over-engineering in
  one flat tagged list. Scans git diff additions only. Use before every merge.
  Trigger: /decklar-review (branch vs main) or /decklar-review --staged (staged only).
argument-hint: "[--staged]"
---
```

- [ ] **Step 3: Smoke-test the skill against itself**

The skill file itself is a good test target — it's a new addition. Stage it and run a quick manual check:

```bash
git diff HEAD -- skills/decklar-review/SKILL.md | grep "^+" | head -20
```

Confirm the `+` lines are the additions you expect. Then invoke `/decklar-review --staged` in a Claude Code session and verify:
- Output is a flat list or `Clean. Ship.`
- Each finding follows `<file>:L<line>: <tag>: <what>. <fix>.`
- Summary line appears last

- [ ] **Step 4: Commit**

```bash
git add skills/decklar-review/SKILL.md
git commit -m "feat: add /decklar-review skill — combined standards + over-engineering diff review"
```
