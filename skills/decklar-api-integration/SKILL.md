---
name: decklar-api-integration
description: 'Use when implementing API integration patterns in Decklar microfrontend apps. Covers endpoint constants, Query Key Factory, service layer, React Query hooks with caching, page-level composed hooks, error handling, and loading states.'
---

# Decklar API Integration Skill

Use this skill whenever you are building or editing API integration code in any Decklar microfrontend app. It covers the full layered architecture — from URL constants through to page-level composed hooks — applied consistently across **all modules**.

## When to trigger this skill

Trigger this skill when the user asks to:

-   implement API calls for any feature or module
-   add a new endpoint integration (GET / POST / PUT / DELETE)
-   connect a form or page to backend APIs
-   add caching, deduplication, or React Query to data fetching
-   build or refactor query hooks, service functions, or mutation handlers
-   wire filter state into a paginated table

## Architecture Layers (read in order)

Every API integration follows this strict separation of concerns:

| Layer                  | File location                           | Single responsibility                                                                              |
| ---------------------- | --------------------------------------- | -------------------------------------------------------------------------------------------------- |
| `endpoints.ts`         | `src/api/endpoints.ts`                  | URL strings only                                                                                   |
| `queryKeys.ts`         | `src/api/queryKeys.ts`                  | Cache key shapes only                                                                              |
| `*.service.ts`         | `src/api/services/`                     | Raw API calls — pure async functions                                                               |
| Base query hooks       | `src/api/hooks/use<Resource>.ts`        | Wire service → React Query — no logic                                                              |
| Filter state hooks     | `src/api/hooks/use<Resource>Filters.ts` | **Simple local filter** — `useState` only, no queries. Omit when using `useUrlFilters`.            |
| Page-level hooks       | `src/api/hooks/use<Resource>Page.ts`    | Compose all layers + side effects. **Call `useUrlFilters` here when URL persistence is required.** |
| `utils/validations.ts` | `src/utils/`                            | Pure validation / transform functions                                                              |
| Components             | —                                       | UI only — call one page hook                                                                       |

**Golden rule:** Components call **one** page hook and get back everything they need. No `useEffect` for data fetching. No API calls inside components.

## Canonical Folder Structure

```
src/
├── api/                                # EVERYTHING non-UI lives here
│   ├── endpoints.ts                    # All URL constants (BASE_URL + ENDPOINTS)
│   ├── queryKeys.ts                    # All React Query cache key factories
│   ├── hooks/
│   │   ├── useResource.ts              # Base query + mutation hooks — one file per resource
│   │   ├── useResourceFilters.ts       # Local filter useState only — omit when using useUrlFilters
│   │   └── useResourcePage.ts          # Page-level composed hook — assembles all layers; call useUrlFilters here
│   └── services/
│       ├── resource.service.ts         # Pure async API functions — one file per resource
│       ├── filterOptions.service.ts
│       └── index.ts                    # Re-exports all services
├── components/                         # UI only — import from src/api/hooks/
│   └── <Feature>/
│       ├── index.ts                    # Re-exports
│       ├── types.ts                    # Shared TypeScript types/interfaces for this feature
│       ├── constants.ts                # Static dropdown options, badge maps, status enums
│       └── components/
│           ├── Home/index.tsx
│           ├── Form/index.tsx
│           └── Detail/index.tsx
├── routes/
├── root.component.tsx                  # QueryClient + QueryClientProvider lives here
└── utils/
    └── resource.validations.ts         # Pure validation/transform functions
```

> **`QueryClientProvider` placement:** For Single-SPA microfrontends, define `QueryClient` inline in `root.component.tsx` — no need for a separate `lib/queryClient.ts`. Wrap `<BrowserRouter>` inside `<QueryClientProvider>`.
>
> **`src/api/` is the only non-component folder.** There is no `src/hooks/` or `src/constants/` folder. Local filter hooks (`useResourceFilters.ts`, when not using `useUrlFilters`) and page-level composed hooks (`useResourcePage.ts`) both live in `src/api/hooks/` alongside the base query hooks. Components only import from `src/api/hooks/`.

---

## Reference Files

Load the relevant reference file when implementing each concern:

-   **URL-persisted filters for data tables (3-layer pattern)** — start here when adding filters to any table → [references/url-filter-datatable.md](references/url-filter-datatable.md)
-   **React Query hooks** (QueryClient config, Query Key Factory, service layer, base hooks, mutation hooks, page-level composed hooks, `select` transforms) → [references/react-query-hooks.md](references/react-query-hooks.md)
-   **API integration flow** (endpoint constants, API wrapper, mutations, breadcrumbs) → [references/api-flow.md](references/api-flow.md)
-   **Filter layout** (grid rules, multi-column examples) → [references/filter-layout.md](references/filter-layout.md)
-   **Table & mutation conventions** (shared hooks, table action columns, applied-filter pattern, `useUrlFilters`) → [references/table-conventions.md](references/table-conventions.md)
-   **Advanced patterns** (OData query building, conditional validation, tab routing, route state passing, URL-persisted filters) → [references/advanced-patterns.md](references/advanced-patterns.md)

## Starter Templates

When creating a new resource integration, copy and adapt from `assets/`:

-   **Full resource template** → [assets/query-hook-template.ts](assets/query-hook-template.ts) — endpoints → queryKeys → service → base hooks → page hook
-   **URL-filter page hook** → [assets/url-filter-page-hook-template.ts](assets/url-filter-page-hook-template.ts) — `useResourcePage.ts` ready to copy, with `useUrlFilters` + date bridge
-   **URL-filter service snippet** → [assets/url-filter-service-snippet.ts](assets/url-filter-service-snippet.ts) — `buildFilterQuery()` OData builder ready to copy

---

## Quick API integration checklist

-   [ ] URL constant added to `src/api/endpoints.ts` using `BASE_URL` for `/v2/` routes — never write URL strings in hooks
-   [ ] Cache key added to `src/api/queryKeys.ts` using the hierarchical factory pattern (`.all` / `.lists()` / `.list(filters)` / `.detail(id)`)
-   [ ] Service function created in `src/api/services/<resource>.service.ts` — pure async, no React, no hooks
-   [ ] Base query/mutation hooks created in `src/api/hooks/use<Resource>.ts` — wire service → React Query, no business logic
-   [ ] Filter state: choose one approach:
    -   **URL-persisted (preferred for paginated tables):** call `useUrlFilters<T>(searchParams, setSearchParams, { defaults, keys })` from `@roambee/client-utility` **inside the page hook** — no separate `Filters.ts` file needed
    -   **Local only (simple forms / non-navigable state):** create `src/api/hooks/use<Resource>Filters.ts` with plain `useState` — no queries inside
-   [ ] Page-level composed hook created in `src/api/hooks/use<Resource>Page.ts` — assembles base hooks + filters + side effects
-   [ ] GET data fetching uses `useQuery` in `src/api/hooks/` — NOT a raw `useEffect` in any component
-   [ ] Multiple components sharing the same data use the same query key (no duplicate fetches)
-   [ ] `QueryClientProvider` is present in `root.component.tsx`
-   [ ] Mutations (POST/PUT/DELETE) use `useMutation` and call `invalidateQueries` / `setQueryData` in `onSuccess`
-   [ ] `isFetching` used for inline overlay spinner; `isLoading` only for full-page skeleton (first load)
-   [ ] Paginated tables use `placeholderData: keepPreviousData` to prevent blank-flash on page change
-   [ ] Filter inputs use "applied filters" pattern — query only updates on "Apply" click, not on every keystroke
-   [ ] Filter state lives in `src/api/hooks/use<Resource>Filters.ts` — not inline in the component
-   [ ] Validation/transform logic lives in `src/utils/resource.validations.ts` — pure functions, called from page hooks
-   [ ] Error handling uses `EventEmitter.emit('showSnackbar', {...})` or Modal
-   [ ] UI uses `@decklar/ui-library` components only — no raw HTML primitives
-   [ ] Submit button is `disabled={isPending}` while mutation is in flight
-   [ ] Table row actions use `getRowActions` + `TableActionMenuItem[]` — never inline `<Button>` cell
-   [ ] Filter dropdown options (roles, statuses, categories) are their own query with `staleTime: Infinity`
-   [ ] Page components call **one** page-level hook — zero API logic in the component body
-   [ ] TypeScript types/interfaces for the feature live in `components/<Feature>/types.ts`
-   [ ] Static constants (dropdown options, badge maps, status enums) live in `components/<Feature>/constants.ts`

## Common Mistakes to Avoid

| ❌ Wrong                                                                         | ✅ Correct                                                                                              |
| -------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------- |
| `useEffect(() => { fetch('/v2/items').then(...) }, [])` in a component           | Base query hook in `src/api/hooks/`                                                                     |
| URL string `/v2/items` written directly in a hook                                | `ENDPOINTS.ITEMS.LIST` from `src/api/endpoints.ts`                                                      |
| API call logic (`API()`, `getAuthUser()`, URL building) inline in `queryFn`      | Move all of that to `src/api/services/*.service.ts`                                                     |
| `API_PATH` or any legacy URL config file alongside `endpoints.ts`                | Delete the old file — one source of truth: `endpoints.ts`                                               |
| Business logic (`if data.length === 0 navigate(...)`) inside a base query hook   | Move to `src/api/hooks/use<Resource>Page.ts`                                                            |
| `useQuery({ queryKey: ['items', 'list'] })` as a raw string array                | `queryKeys.items.lists()` from `src/api/queryKeys.ts`                                                   |
| Any hook (`useQuery`, `useMutation`, filter `useState`) in `src/hooks/` directly | Move to `src/api/hooks/` — `src/hooks/` folder must not exist                                           |
| Filter `useState` inline in a component                                          | `src/api/hooks/use<Resource>Filters.ts` (local) or `useUrlFilters` inside the page hook (URL-persisted) |
| `useUrlFilters` called directly in a component                                   | Move `useSearchParams()` + `useUrlFilters()` to `src/api/hooks/use<Resource>Page.ts`                    |
| Page hook in `src/hooks/` importing from `src/api/hooks/`                        | Put it directly in `src/api/hooks/use<Resource>Page.ts`                                                 |
| `const [loading, setLoading] = useState(false)` + manual try/catch for mutations | `useMutation` with `isPending`                                                                          |
| Validation logic (`items.some(...)`) inside a component or page hook             | Move to `src/utils/resource.validations.ts`                                                             |

---

## When to use this skill vs decklar-ui-library

-   Use `decklar-ui-library` for component selection, form layout, and UI details.
-   Use `decklar-api-integration` when wiring backend APIs, building payloads, and handling network flow.

## Trigger phrases for this skill

-   "Add API integration for [any module/page]"
-   "Implement POST / PUT / DELETE API call"
-   "Connect form submit to backend API"
-   "Load list from API in a page"
-   "Add caching to API calls"
-   "Use React Query for data fetching"
-   "Table data loading is slow, add caching"
-   "Add filter state to a paginated table" / "persist filters in URL"
-   "Create a service layer for [resource]"
-   "Add a query key factory for [resource]"
