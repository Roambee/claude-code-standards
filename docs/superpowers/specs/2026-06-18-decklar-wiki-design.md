# Decklar Wiki — Design Spec

**Date:** 2026-06-18
**Status:** Approved
**Owner:** Heet Shah

---

## Overview

A company-wide LLM knowledge base ("the wiki") that lets anyone at Decklar — engineers, sales, support, product — ask Claude about internal entities (products, people, teams, customers, integrations, processes, terms, competitors, decisions) and get rich, role-appropriate answers.

The wiki grows in two ways: organically from conversations (silently, no user interruption) and deliberately via explicit save commands. It is accessible from both Claude Code (engineers) and Claude.ai / Claude Cowork (non-engineers) through a unified backend called **graphify**.

This design covers two sequential builds:
1. **graphify** — the backend (REST API + MCP server)
2. **decklar-claude wiki layer** — plugin additions (hooks, background agent, `/wiki` skill, config)

Non-Claude integrations (e.g. Slack, CRM) are explicitly out of scope for this version.

---

## System Architecture

```
┌─────────────────────────────────────┐    ┌──────────────────────────────────┐
│  Engineers (Claude Code)            │    │  Non-Engineers (Claude.ai/Cowork) │
│                                     │    │                                   │
│  hook-18-wiki-inject (session start)│    │  Project Instructions:            │
│  → injects wiki context snippet     │    │  "Check wiki at conversation start"│
│                                     │    │                                   │
│  hook-17-wiki-capture (session end) │    │  wiki_save called mid-convo       │
│  → background Claude agent          │    │  when Claude learns entity info    │
│  → reads transcript                 │    │                                   │
│  → extracts entity facts            │    │                                   │
│  → POST to graphify REST API        │    │                                   │
│                                     │    │                                   │
│  /wiki skill (explicit lookup/save) │    │  wiki_search (natural MCP use)    │
└──────────────┬──────────────────────┘    └──────────────┬───────────────────┘
               │                                          │
               ▼                                          ▼
        ┌─────────────────────────────────────────────────────────┐
        │                        graphify                          │
        │                                                          │
        │     REST API              ←→         MCP Server          │
        │     (write-heavy,                    (query/save at      │
        │      background agent)               runtime)            │
        │                                                          │
        │     Entity store: 9 types, facts per dimension, graph    │
        └─────────────────────────────────────────────────────────┘
```

---

## Entity Schema

All wiki entries share a common envelope. Facts are organized by audience dimension so the same entity answers differently depending on who's asking.

```json
{
  "id": "uuid",
  "type": "product | person | team | customer | integration | process | glossary | competitor | decision",
  "name": "Radar",
  "aliases": ["radar", "Radar tool"],
  "dimensions": {
    "general":   { "summary": "...", "facts": [] },
    "sales":     { "positioning": "...", "pricing": "...", "facts": [] },
    "technical": { "stack": "...", "apis": "...", "facts": [] },
    "support":   { "common_issues": "...", "escalation": "...", "facts": [] }
  },
  "relationships": [
    { "entity_id": "uuid-of-team", "type": "owned_by" },
    { "entity_id": "uuid-of-integration", "type": "integrates_with" }
  ],
  "tags": ["tracking", "supply-chain", "iot"],
  "source": "organic | deliberate",
  "confidence": 0.85,
  "author": "heet.shah@decklar.com",
  "created_at": "...",
  "updated_at": "..."
}
```

**Design decisions:**
- **Dimensions** let the same entity surface different facts by role. A salesperson asking about Radar gets `sales` dimension. An engineer gets `technical`. Claude infers which to use from conversation context and the user's configured role.
- **Aliases** resolve natural language variation — "radar", "Radar", "the Radar tool" all hit the same entry.
- **Relationships** make the wiki a traversable graph — "who works on Radar" traverses `owned_by` → Team → `has_member` → People.
- **Confidence** scores organically-captured facts lower than deliberate ones so Claude can hedge when appropriate.
- **Upsert-by-name+type** is the default write behavior — repeated extraction of the same entity across many sessions merges facts rather than creating duplicates.

### Supported Entity Types

| Type | Description |
|------|-------------|
| `product` | Tools and products Decklar sells (e.g. Radar) |
| `person` | Employees — role, team, expertise |
| `team` | Squads, their ownership areas, leads |
| `customer` | Named accounts, use cases, tier |
| `integration` | Third-party systems Decklar connects to |
| `process` | Cross-functional workflows (onboarding, release, escalation) |
| `glossary` | Company-specific terms and acronyms |
| `competitor` | Competitive landscape, positioning vs Decklar |
| `decision` | Important choices made and why — prevents relitigating settled things |

---

## graphify — Build 1

### REST API

Used primarily by the background capture agent for writes. Also available for admin tooling.

```
POST   /v1/entities              — create or upsert by name+type
POST   /v1/entities/:id/facts    — append facts to an existing entity
GET    /v1/entities/:id          — fetch full entity
GET    /v1/entities/search       — ?q=radar&type=product&dimension=sales&limit=10
PUT    /v1/entities/:id          — full update (deliberate, high-confidence)
DELETE /v1/entities/:id/facts/:fact_id  — remove a bad organic fact
```

**Auth:** Bearer token (API key). Never hardcoded — stored in `~/.claude/decklar-config.json` as `wiki.graphify.apiKey: "env:GRAPHIFY_API_KEY"`.

**Upsert behavior:** `POST /v1/entities` matches on `name` + `type` (case-insensitive, aliases checked). If a match exists, new facts are merged and `updated_at` refreshed. Duplicate-safe by design.

### MCP Server Tools

Used by Claude at runtime on both Claude Code and Claude.ai. graphify publishes this as a standard MCP server that any Claude instance can connect to.

```
wiki_search(query, entity_type?, dimension?, limit?)
  → [{id, name, type, summary, confidence}]

wiki_get(id, dimension?)
  → full entity object, optionally filtered to one dimension

wiki_save(type, name, facts, tags?, source="organic", confidence?)
  → upserts entity, returns {id, merged: bool}

wiki_relate(from_id, to_id, relationship_type)
  → links two entities bidirectionally
```

---

## Organic Capture Pipeline

### Claude Code users (engineers)

`hook-17-wiki-capture.sh` fires at session end. It spawns a background Claude agent with the full session transcript and this prompt:

```
Review this conversation. Extract facts about Decklar entities: products,
people, teams, customers, integrations, processes, glossary terms,
competitors, or decisions. For each fact, call wiki_save with entity type,
name, facts, and a confidence score (0.0–1.0). Skip vague or already
well-known facts. Do not output anything — this runs silently.
```

The agent calls `wiki_save` via the graphify MCP server. No output shown to the user.

### Claude.ai / Cowork users (non-engineers)

The graphify MCP server is connected to their Claude instance (once, by IT or self-serve). Their Project Instructions include:

```
When you learn something new about a Decklar entity (product, person,
team, customer, integration, process, term, competitor, or decision)
during this conversation, silently call wiki_save to record it.
Set source="organic" and confidence based on how explicit the information was.
```

Claude calls `wiki_save` naturally mid-conversation. No prompt to the user.

### Deliberate capture (both platforms)

- **Claude Code:** `/wiki save` — guided flow asking for entity type, name, dimension, and facts. Sets `source="deliberate"` and `confidence=1.0`.
- **Claude.ai:** User says "save this to the wiki" and Claude calls `wiki_save` with the relevant facts. Same result.

---

## Automatic Context Injection

### Claude Code users

`hook-18-wiki-inject.sh` fires at session start. It reads `wiki.graphify.role` from `~/.claude/decklar-config.json`, calls `wiki_search` with role-appropriate defaults, and injects a compact context block into the session (top 3–5 entries):

```markdown
## Decklar Wiki Context
- **Radar** (product): Real-time shipment tracking. Owned by Logistics Team.
  Sales: Per-device subscription pricing, enterprise supply chain focus.
  Technical: REST API, webhook events, IoT sensor integration.
- **Logistics Team**: Lead — Priya Mehta. 6 engineers. Slack: #team-logistics.
```

Dimension filtering: the hook passes the user's `role` as the `dimension` param. Sales users automatically get `sales` dimension facts; engineers get `technical`. No manual switching needed.

If the conversation goes deeper on a specific entity, `/wiki <name>` fetches the full entry on demand.

### Claude.ai / Cowork users

Project Instructions contain a standing instruction:

```
At the start of every conversation, call wiki_search with the user's
first message to fetch relevant Decklar wiki context before responding.
Use dimension matching the user's role (sales/support/technical/general).
```

Claude proactively queries graphify before its first response — same outcome as the hook, different trigger mechanism.

---

## Plugin Additions (decklar-claude) — Build 2

### New files

```
skills/wiki/wiki.md               — /wiki skill
hooks/hook-17-wiki-capture.sh     — session-end transcript extraction
hooks/hook-18-wiki-inject.sh      — session-start context injection
```

### `/wiki` skill

```
/wiki <query>              — search wiki, return top result for user's role
/wiki <type> <query>       — type-scoped search (e.g. /wiki product radar)
/wiki save                 — guided deliberate capture flow
/wiki relate               — link two entities
```

### Config schema additions (`decklar-config-schema.json`)

```json
"wiki": {
  "type": "object",
  "description": "Decklar Wiki config used by /wiki, hook-17, and hook-18.",
  "properties": {
    "role": {
      "type": "string",
      "enum": ["engineer", "sales", "support", "product"],
      "description": "User role — determines which dimension is injected at session start."
    },
    "graphify": {
      "type": "object",
      "properties": {
        "endpoint": {
          "type": "string",
          "description": "graphify base URL, e.g. https://graphify.decklar.com"
        },
        "apiKey": {
          "type": "string",
          "description": "Env var holding the API key, e.g. env:GRAPHIFY_API_KEY"
        }
      }
    }
  }
}
```

### `/init` skill update

When a new user runs `/init`, it now asks for their role and writes `wiki.graphify.role` to `~/.claude/decklar-config.json`. Existing users can re-run `/init` or set it manually.

---

## Non-Engineer Setup (Claude.ai / Cowork)

1. IT or the user adds the graphify MCP server to their Claude.ai MCP settings once.
2. Create a Claude Project called "Decklar" with Project Instructions (template provided in `docs/wiki-project-instructions.md`).
3. All Decklar-related conversations happen inside that project — wiki injection and capture work automatically.

---

## Coexistence with `/remember` and `/recall`

`/remember` and `/recall` continue working unchanged for engineering session learnings. They use the `memory.backend` config (claude-mem or graphify) and are a separate namespace. The wiki is not a replacement — it's complementary. Engineering learnings (bugs, patterns, decisions) stay in `/remember`. Company entity knowledge goes in the wiki.

When graphify is ready, `/remember` and `/recall` can optionally migrate to use it as their backend (already anticipated in the config schema), but that is a separate migration and not part of this spec.

---

## Build Sequence

```
Phase 1: graphify REST API + entity store
Phase 2: graphify MCP server
Phase 3: hook-17 (session-end capture agent)
Phase 4: hook-18 (session-start injection)
Phase 5: /wiki skill
Phase 6: /init update + config schema additions
Phase 7: Claude.ai Project Instructions template
```

Phases 1–2 must be complete before any plugin work begins.

---

## Out of Scope

- Non-Claude integrations (Slack, CRM, etc.) — future version
- Public-facing wiki UI
- Wiki entry versioning / audit log (can be added to graphify later)
- Automatic role detection (role is configured manually via `/init`)
