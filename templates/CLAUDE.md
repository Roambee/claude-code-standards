# Roambee — Claude Code Global Standards

Installed by `roambee-claude /init`. Do not edit manually — run `/init` to update.

---

<!-- STABLE CONTENT FIRST — cached by Claude Code after first load.
     Add volatile content (sprint focus, current decisions) at the bottom. -->

## Git Workflow

- Branch naming: `<type>/<TICKET-ID>/<short-title-in-kebab-case>`
  - Types: `feat`, `fix`, `chore`, `refactor`, `docs`
  - Example: `feat/RMB-1234/add-shipment-export`
- Always cut from a fresh `origin/dev` — never branch off another feature branch
- One Jira ticket per branch — no bundling unrelated work

## Commit Format

Conventional commits only:
```
feat(scope): short description

Body if needed. No "Co-Authored-By: Claude" lines.
```
Valid scopes match commitlint config in the monorepo root.

## Code Style

- No comments unless the WHY is non-obvious (hidden constraint, workaround, subtle invariant)
- No docstrings, no multi-line comment blocks
- No backwards-compat shims — if something is unused, delete it
- No feature flags for internal code changes

## CI Pipeline Summary

The pipeline checks: commitlint, ESLint, TypeScript compilation, unit tests, e2e tests (NestJS), build. A commit that breaks any of these will fail CI. Know before you push.

## AI Development

- Always use OpenRouter as the provider — no direct Anthropic/OpenAI SDK calls in production services
- Before writing any LLM call, ask the user: what model? what task? Present the cost table from `provider-abstraction` skill
- Prompts are versioned files (`prompts/feature-name.md`), never inline strings longer than ~100 chars
- Every LLM call must log: model name, token counts in + out, latency, request ID

---

## Architecture

This repo uses a two-level architecture doc system:

- **`architecture.md`** (repo root) — navigation index only, one paragraph per module
- **`docs/architecture/<module>/overview.md`** — full detail per module, read this when working in that module
- **`docs/architecture/decisions/`** — Architecture Decision Records (ADRs) for significant choices

Hook-16 will surface the relevant module doc automatically when you edit files in `packages/` or `apps/`. To update the tree, run `/architecture`. To log a decision, run `/architecture adr`.

## Docs Update Rule

`architecture.md` and any affected `docs/architecture/<module>/overview.md` are living documents. Any commit that adds a service, changes local dev setup, adds env vars, or changes the tech stack must update those files in the same commit. Stale docs = incomplete work.

---

## Planning Rule

Never begin implementation of a plan without a Jira ticket. Use `/plan` — it creates tickets and writes the plan in one step. If a plan exists in conversation with no ticket, ask for the ticket ID before writing any code.

## Branch Context Rule

If already on a branch with a ticket ID, ask the user whether new work belongs to that ticket or needs a new one. Infer from context:
- Bug fix / debugging session → same branch, same ticket
- New feature discussion → new branch, new ticket

Always confirm before acting.

## Skill Invocation Order

For every feature or fix:
1. Implement
2. Run tests (unit + e2e where applicable)
3. `feature-dev:code-reviewer`
4. `code-simplifier`
5. Update `architecture.md` (index) and the relevant `docs/architecture/<module>/overview.md` if the change affects them
6. Commit
7. `/pr`

## Subagent Protocol

- Every subagent response must include a `## Flags` section reporting: scope changes, blockers, code review findings, decisions made
- Never make autonomous decisions that affect shared systems (DB, CI, branches, PRs, emails)
- Before marking any task Done: verify tests pass, update docs if needed, transition Jira ticket

## PR Policy

Always use `/pr` — never open a PR manually. `/pr` confirms tests pass, creates the PR with a standard template, links to Jira, and transitions the ticket to In Review.

---

<!-- VOLATILE CONTENT — put sprint-specific or frequently-changing notes below here.
     This section is not cached and is re-read on every context load. -->
