# /roambee-review Skill Design

**Date:** 2026-06-20
**Status:** Approved

## Summary

A single SKILL.md that instructs Claude to run a git diff, analyze additions for both Roambee standards violations and over-engineering patterns, and print one finding per line in a flat tagged list. No scripts, no helpers — Claude runs the diff and does the analysis in-context.

Also adds `ponytail` as an explicit plugin dependency so all Roambee devs get it on install.

---

## Invocation

| Command | Diff source |
|---|---|
| `/roambee-review` | `git diff main` — full branch, PR-ready check |
| `/roambee-review --staged` | `git diff --staged` — mid-development check |

If the diff is empty: print `Nothing to review.` and stop.

---

## Output Format

One finding per line:

```
<file>:L<line>: <tag>: <what>. <fix>.
```

All findings in a single flat list — standards and over-engineering interleaved, ordered by file/line. Tags carry the signal; no emoji, no section headers.

Final line always:
```
<N> findings. net: -<M> lines possible.
```
If nothing found: `Clean. Ship.`

---

## Tags

### Standards Tags

| Tag | What it catches |
|---|---|
| `cross-mfe:` | `import` from another `packages/client/<pkg>` (not `shared`, `client-utility`, `decklar`) |
| `secret:` | AWS key pattern, Bearer token literal, hardcoded password, `.env` file write |
| `swagger:` | `@Get/@Post/@Put/@Patch/@Delete` endpoint with no `@ApiOperation`/`@ApiResponse`/`@ApiTags` |
| `pii:` | Field names matching `email|phone|ssn|dateOfBirth|address|nationalId|...` without encryption/log comment |
| `env-var:` | `process.env.FOO` where `FOO` is absent from `.env.example` |
| `migration:` | Migration file missing `down()`, contains `DROP TABLE`/`TRUNCATE`/`ALTER COLUMN`, or has non-timestamped name |
| `prompt:` | String literal >300 chars (likely an inline prompt that should live in `prompts/<name>.md`) |
| `logging:` | `console.log`/`console.error` inside a NestJS `@Injectable` service (should use `Logger`) |

### Over-Engineering Tags

| Tag | What it catches |
|---|---|
| `yagni:` | Abstraction with one implementation, config value that never changes, layer with one caller |
| `stdlib:` | Hand-rolled function the standard library ships — name the stdlib equivalent |
| `native:` | Dependency or code doing what the platform already provides |
| `shrink:` | Same logic expressible in fewer lines — show the shorter form |
| `delete:` | Dead code, unused export, speculative feature with no caller |

---

## Analysis Rules

- **Scope:** Only `+` lines in the diff (additions). Context lines and deletions are ignored.
- **Standards:** Pattern-matched (regex/structural). Claude checks each added line against the pattern table above.
- **Over-engineering:** Judgment-based. Claude reads added code for YAGNI, reinvented stdlib, unnecessary wrappers, dead exports — same discipline as ponytail-review but diff-scoped only.
- **No false positives over deletions:** If a `console.log` is being *removed*, that's correct — don't flag it.

---

## Files Changed

| File | Change |
|---|---|
| `skills/roambee-review/SKILL.md` | New — the skill itself |
| `.claude-plugin/plugin.json` | Add `ponytail` to `dependencies.plugins` |

---

## Non-Goals

- Does not apply fixes (review only, like ponytail-review)
- Does not auto-trigger on commit — manual slash command only
- Does not check context lines or deleted code
- Does not replace the real-time hooks (hook-06, hook-12, etc.) — those still fire during file writes
