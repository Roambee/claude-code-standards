---
name: roambee-review
description: >
  Combined PR diff review: Roambee standards violations + over-engineering in
  one flat tagged list. Scans git diff additions only. Use before every merge.
  Trigger: /roambee-review (branch vs main) or /roambee-review --staged (staged only).
argument-hint: "[--staged]"
---

# /roambee-review

Review the current diff for Roambee standards violations and over-engineering. One finding per line. Does not apply fixes.

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
- Line imports from `@roambee/<other-pkg>` or a relative `../../` path resolving into another `packages/client/` package
- Allowed targets (do not flag): `@roambee/shared`, `@roambee/client-utility`, anything from `@roambee/decklar`
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
packages/client/shipments/src/Foo.tsx:L3: cross-mfe: imports from @roambee/users-mfe. Use EventEmitter or move to packages/shared/.
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
- "stop roambee-review" or "normal mode" to revert to default review behavior
