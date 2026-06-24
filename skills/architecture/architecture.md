# /architecture — Architecture Doc Tree Manager

Use when setting up or updating the architecture documentation for a repo. Converts a flat `architecture.md` into an indexed tree with per-module deep files, TL;DR sections, and ADRs.

**Announce at start:** "Loading architecture. Building the doc tree."

---

## When to Run

- After `/new-repo` — to split the generated `architecture.md` into the full tree
- When `architecture.md` has grown beyond ~100 lines
- When adding a new module/service that needs its own deep file
- When capturing an architecture decision (`/architecture adr`)

---

## Step 1: Read the Project Structure

```bash
ls docs/architecture/ 2>/dev/null || echo "TREE_NOT_YET_CREATED"
cat architecture.md 2>/dev/null | head -20
ls packages/ apps/ src/ 2>/dev/null
```

If `docs/architecture/` already exists, go to whichever step is relevant (adding a module → Step 4, adding an ADR → Step 6).

---

## Step 2: Create the Tree Skeleton

```bash
mkdir -p docs/architecture/decisions
```

For each top-level module found in Step 1 (e.g. `auth`, `shipments`, `ai`, `web`):

```bash
mkdir -p docs/architecture/<module>
```

---

## Step 3: Convert `architecture.md` to an Index

Rewrite `architecture.md` at the repo root to be a **navigation index only** — one paragraph per module + a link to its deep file. No detailed content lives here.

Use this exact structure:

```markdown
# [Repo Name] — Architecture Index

> Index only. For detail, follow the links. Updated by `/architecture`.

## Modules

### [Module Name] (`packages/<module>/`)
[One sentence: what this module does and who calls it.]
[→ Deep dive](docs/architecture/<module>/overview.md)

### [Next Module]
...

## Architecture Decisions
Significant decisions are logged in [`docs/architecture/decisions/`](docs/architecture/decisions/).

| ADR | Decision |
|-----|----------|
| [001](docs/architecture/decisions/001-example.md) | [Short title] |
```

Commit:
```bash
git add architecture.md
git commit -m "docs: convert architecture.md to index, move detail to docs/architecture/"
```

---

## Step 4: Create Per-Module Deep Files

For each module, create `docs/architecture/<module>/overview.md` using this template:

```markdown
# [Module Name] — Architecture

## TL;DR
[Three sentences maximum: what this module does, what its main DB/storage is, and what it calls externally. Read the rest only if you're changing the module's structure or debugging a systemic issue.]

---

## Responsibilities
[What this module owns. Bullet list.]

## Tech Stack
| Layer | Technology |
|-------|-----------|
| Language | |
| Framework | |
| Database | |
| Key libraries | |

## Key Files
| Path | Purpose |
|------|---------|
| `src/main.ts` | |
| `src/modules/<name>/` | |

## External Calls
| System | Why | How |
|--------|-----|-----|
| [Auth Service] | [validate JWT] | [HTTP GET /verify] |

## Data Flow
[Optional: short narrative or ASCII diagram for the main request path]

## Known Constraints
[Deliberate limitations, scaling bottlenecks, or non-obvious invariants worth knowing before editing]
```

---

## Step 5: Scaffold Nested `CLAUDE.md` Files

For each package, create a scoped `CLAUDE.md` so Claude loads only the relevant context when editing that module. Detect the package type from its `package.json`/`pyproject.toml` and scaffold the appropriate file:

**For NestJS backend packages** (`packages/api/`, `packages/backend/`, etc.):

```markdown
# [Package Name] — Claude Context

## Standards
- Use `ResponseHandlerService` for all responses — never `res.json()`
- All endpoints need `@ApiOperation` + `@ApiResponse` Swagger decorators
- Auth is handled by CAS middleware — do not implement auth logic here
- Use `Logger` from `@nestjs/common` — never `console.log`

## Architecture
See [../../docs/architecture/<module>/overview.md](../../docs/architecture/<module>/overview.md) for module context.
```

**For React microfrontend packages** (`packages/client/`, `packages/web/`):

```markdown
# [Package Name] — Claude Context

## Standards
- User-facing errors use `EventEmitter.emit('showSnackbar', ...)` — never `console.error`
- No imports from other MFE packages except `@decklar/client-utility` and `@decklar/shared`
- State: React Query for server state, local `useState` for UI state only

## Architecture
See [../../docs/architecture/<module>/overview.md](../../docs/architecture/<module>/overview.md) for module context.
```

**For Python AI packages** (`packages/ai/`):

```markdown
# [Package Name] — Claude Context

## Standards
- All LLM calls via OpenRouter through `LLMProvider` — no direct Anthropic/OpenAI SDK
- Use `async/await` for all LLM calls — never blocking HTTP
- Prompts live in `prompts/<feature-name>.md` — never inline strings > 100 chars
- Log every LLM call: model, tokens_in, tokens_out, latency_ms, request_id

## Architecture
See [../../docs/architecture/<module>/overview.md](../../docs/architecture/<module>/overview.md) for module context.
```

Commit after creating all package CLAUDE.md files:
```bash
git add packages/*/CLAUDE.md
git commit -m "docs: add scoped CLAUDE.md files for context management"
```

---

## Step 6: Add an Architecture Decision Record (ADR)

Run when: a significant decision was made (choosing a library, defining a protocol, establishing a constraint).

Ask the developer:
1. "Short title for this decision? (e.g. `use-openrouter-for-llm-calls`)"
2. "What was decided and why?"
3. "What alternatives were considered and why were they rejected?"
4. "Any consequences or constraints this introduces?"

Determine the next ADR number:
```bash
ls docs/architecture/decisions/ | grep -oE '^[0-9]+' | sort -n | tail -1
```

Create `docs/architecture/decisions/<NNN>-<title>.md`:

```markdown
# ADR <NNN>: <Title>

**Date:** <YYYY-MM-DD>
**Status:** Accepted

## Decision
[What was decided — one clear sentence.]

## Context
[Why this decision was needed. What problem it solves.]

## Alternatives Considered
| Option | Why Rejected |
|--------|-------------|
| [Option A] | [Reason] |
| [Option B] | [Reason] |

## Consequences
[What this decision constrains or enables going forward. Non-obvious side effects.]
```

Add a row to the ADR table in `architecture.md`, then commit:
```bash
git add docs/architecture/decisions/<NNN>-<title>.md architecture.md
git commit -m "docs: add ADR <NNN> — <title>"
```

---

## Step 7: Verify the Tree

```bash
find docs/architecture -name "*.md" | sort
echo "---"
head -5 architecture.md
```

Tell the developer: "Architecture tree is set up. Claude will now load only the relevant module doc when working in a specific package, via hook-16. Use `/architecture adr` to log future decisions."
