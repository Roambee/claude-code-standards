# Table & Mutation Conventions

> These conventions apply to **every module** in the monorepo — not specific to any single app.

---

## Shared hooks — one per resource, shared across pages

| Pattern                     | Location                              | Purpose                                                                                              |
| --------------------------- | ------------------------------------- | ---------------------------------------------------------------------------------------------------- |
| `useResourceList()`         | `src/api/hooks/useResource.ts`        | All pages that display this resource share one cached fetch                                          |
| `useResource(id)`           | `src/api/hooks/useResource.ts`        | Detail page — enabled only when `id` is truthy                                                       |
| `useCreateResource()`       | `src/api/hooks/useResource.ts`        | Mutation hook — invalidates lists on success                                                         |
| `useUpdateResource()`       | `src/api/hooks/useResource.ts`        | Mutation hook — writes to detail cache + invalidates lists                                           |
| `useDeleteResource()`       | `src/api/hooks/useResource.ts`        | Mutation hook — removes detail entry + invalidates lists                                             |
| `useStatusOptions()`        | `src/api/hooks/useFilterOptions.ts`   | Dropdown data — `staleTime: Infinity`                                                                |
| `useResourceTableFilters()` | `src/api/hooks/useResourceFilters.ts` | **Local** filter state — no queries inside. Omit when using `useUrlFilters`.                         |
| `useUrlFilters<T>(...)`     | called inside `useResourcePage.ts`    | **URL-persisted** filter state — preferred for paginated tables with shareable/bookmarkable filters. |
| `useResourcePage()`         | `src/api/hooks/useResourcePage.ts`    | Page-level composed hook — components call this                                                      |

**Never duplicate fetch logic** — if two components need the same data, they both call the same hook. React Query deduplicates the request automatically.

---

## Filter state — two patterns, pick one

### Pattern A: URL-persisted filters with `useUrlFilters` (preferred for paginated tables)

Use `useUrlFilters` from `@decklar/client-utility` when filters should survive page refresh, browser back/forward navigation, and be shareable via URL. **No separate `useResourceFilters.ts` file is needed** — call the hook directly in the page hook.

```ts
// src/api/hooks/useResourcePage.ts
import { useSearchParams } from 'react-router-dom';
import { useUrlFilters } from '@decklar/client-utility';
import type { UrlFiltersConfig } from '@decklar/client-utility';
import { useResourceList } from './useResource';

interface ResourceFilters {
	status: string;
	search: string;
	account: string;
}

const DEFAULT_FILTERS: ResourceFilters = { status: 'all', search: '', account: '' };
const FILTER_KEYS: (keyof ResourceFilters)[] = ['status', 'search', 'account'];

export const useResourcePage = () => {
	const [searchParams, setSearchParams] = useSearchParams();

	const { filters, appliedFilters, page, updateFilter, applyFilters, clearFilters, setPage } = useUrlFilters<ResourceFilters>(searchParams, setSearchParams, {
		defaults: DEFAULT_FILTERS,
		keys: FILTER_KEYS
		// pageKey: 'page'  ← optional, defaults to 'page'
	});

	// appliedFilters drives the query — only updates when user clicks Apply
	const query = useResourceList({ ...appliedFilters, page });

	return {
		filters, // draft (input field state)
		appliedFilters, // committed to URL — passed to API
		page,
		updateFilter, // update draft without committing
		applyFilters, // commit draft → URL → triggers refetch
		clearFilters, // reset all to defaults + clear URL params
		setPage,
		items: query.data ?? [],
		isLoading: query.isLoading,
		isFetching: query.isFetching,
		isError: query.isError
	};
};
```

**`useUrlFilters` contract:**

| Value / function | Type                   | Description                                                    |
| ---------------- | ---------------------- | -------------------------------------------------------------- |
| `filters`        | `T`                    | Draft input state — changes as user types                      |
| `appliedFilters` | `T`                    | Committed state synced with URL — drives the API query         |
| `page`           | `number`               | Current page from URL (defaults to `1`)                        |
| `updateFilter`   | `(key, value) => void` | Update one draft field — does NOT commit to URL                |
| `applyFilters`   | `() => void`           | Push `filters` → URL, reset page to 1, update `appliedFilters` |
| `clearFilters`   | `() => void`           | Reset all to defaults and remove all filter URL params         |
| `setPage`        | `(p: number) => void`  | Update page param in URL                                       |

**Date fields in `useUrlFilters`:** store dates as millisecond timestamp strings in the filter type. Convert `Date ↔ string` in the page hook:

```ts
interface ResourceFilters {
	dateFrom: string; // ms timestamp as string, '' = not set
	dateTo: string;
}

// In page hook: keep a local Date state for the picker UI only
const [dateRange, setDateRangeState] = useState<{ from?: Date; to?: Date }>({...});

const setDateRange = useCallback((range: { from?: Date; to?: Date }) => {
	setDateRangeState(range);
	updateFilter('dateFrom', range.from ? String(range.from.getTime()) : '');
	updateFilter('dateTo', range.to ? String(range.to.getTime()) : '');
}, [updateFilter]);

// Sync date state when URL changes (back/forward)
useEffect(() => {
	setDateRangeState({
		from: appliedFilters.dateFrom ? new Date(Number(appliedFilters.dateFrom)) : undefined,
		to: appliedFilters.dateTo ? new Date(Number(appliedFilters.dateTo)) : undefined
	});
}, [appliedFilters.dateFrom, appliedFilters.dateTo]);
```

---

### Pattern B: Local-only filter state (simple forms, non-navigable state)

Use plain `useState` in a separate file **only** when URL persistence is not needed (e.g., modal-based filters, simple non-paginated lists).

```ts
// src/api/hooks/useResourceFilters.ts — owns ONLY useState for filters
import { useState, useCallback } from 'react';

export interface ResourceFilters {
	search: string;
	status: string;
}

const DEFAULT_FILTERS: ResourceFilters = { search: '', status: 'all' };

export const useResourceTableFilters = () => {
	const [filters, setFilters] = useState<ResourceFilters>(DEFAULT_FILTERS);

	const updateFilter = useCallback(<K extends keyof ResourceFilters>(key: K, value: ResourceFilters[K]) => {
		setFilters((prev) => ({ ...prev, [key]: value }));
	}, []);

	const resetFilters = useCallback(() => setFilters(DEFAULT_FILTERS), []);

	return { filters, updateFilter, resetFilters };
};
```

Then the page hook composes it:

```ts
// src/api/hooks/useResourcePage.ts
import { useResourceTableFilters } from './useResourceFilters';
import { useResourceList } from './useResource';

export const useResourcePage = () => {
	const { filters, updateFilter, resetFilters } = useResourceTableFilters();
	const query = useResourceList(filters);

	return { filters, updateFilter, resetFilters, items: query.data ?? [], isLoading: query.isLoading };
};
```

---

## Mutation via useMutation (ALL modules)

**Always** use `useMutation` for POST / PUT / DELETE. Never manage mutation loading state manually with `useState(false)`.

```ts
// ✅ Correct
const createItem = useCreateItem();
<Button disabled={createItem.isPending} onClick={() => createItem.mutate(payload)}>Save</Button>

// ❌ Wrong — manual state for a mutation
const [loading, setLoading] = useState(false);
const handleSave = async () => { setLoading(true); await API(...); setLoading(false); };
```

---

## Applied-filters pattern (ALL paginated tables)

Only update the active query when the user clicks "Apply" — not on every keystroke.

**When using `useUrlFilters` (preferred):** the draft/applied separation is built-in:

-   `filters` = draft state (updates while user types)
-   `appliedFilters` = committed state (written to URL and used by the API query)
-   Call `applyFilters()` on the Apply button — it pushes `filters` to URL and updates `appliedFilters`
-   Call `clearFilters()` on the Clear button — resets to defaults and removes URL params

```ts
// from useUrlFilters — no manual useState needed
const { filters, appliedFilters, updateFilter, applyFilters, clearFilters } = useUrlFilters(...);
const query = useResourceList(appliedFilters); // appliedFilters only changes on Apply
```

**When using local `useState` (Pattern B only):**

```ts
const [draftFilters, setDraftFilters] = useState(DEFAULT_FILTERS);
const [appliedFilters, setAppliedFilters] = useState(DEFAULT_FILTERS);

// Query uses applied — stable, no refetch on typing
const { data, isFetching } = useResourceList(appliedFilters);

// Only commit when user clicks Apply — reset page to 1
const handleApply = () => setAppliedFilters({ ...draftFilters, page: 1 });
const handleClear = () => {
	setDraftFilters(DEFAULT_FILTERS);
	setAppliedFilters(DEFAULT_FILTERS);
};
```

---

## Table row actions pattern (ALL tables with row actions)

**Never** place inline `<Button>` inside a cell renderer for row actions.  
**Always** use `getRowActions` on `DataTable` with `TableActionMenuItem[]`.

```tsx
import type { TableActionMenuItem } from '@decklar/ui-library';
import type { Row } from '@tanstack/react-table';
import { Edit, TrashCan, View } from '@carbon/icons-react';

<DataTable
	columns={columns}
	data={rows}
	enableSorting
	enablePagination
	showPageNumbers
	enableColumnResizing
	getRowActions={(row: Row<YourType>) => {
		const items: TableActionMenuItem[] = [];

		// Always-present actions
		items.push({
			id: 'edit',
			label: 'Edit',
			icon: <Edit size={14} />,
			onClick: () => navigate(`/your-resource/${row.original.id}/edit`)
		});

		// Conditional actions — only push when field is populated
		if (row.original.detailUrl) {
			items.push({
				id: 'view',
				label: 'View Details',
				icon: <View size={14} />,
				onClick: () => openModal(row.original)
			});
		}

		items.push({
			id: 'delete',
			label: 'Delete',
			icon: <TrashCan size={14} />,
			onClick: () => openDeleteConfirm(row.original.id)
		});

		return items.length > 0 ? items : null;
	}}
/>;
```

---

## Loading states in tables

```tsx
// Full-page skeleton — first load only (isLoading)
if (isLoading) return <Spinner />;

// Inline overlay — subsequent filter/page changes (isFetching)
<div className="relative">
	{isFetching && (
		<div className="absolute inset-0 bg-white/60 flex items-center justify-center z-10 rounded-lg">
			<span className="animate-spin h-6 w-6 border-4 border-primary border-t-transparent rounded-full" />
		</div>
	)}
	<DataTable columns={columns} data={rows} enableSorting enablePagination showPageNumbers enableColumnResizing />
</div>;
```

---

## Decision cheat sheet — where does this code belong?

| "I need to..."                      | Where                                                        |
| ----------------------------------- | ------------------------------------------------------------ |
| Add a new API URL                   | `src/api/endpoints.ts`                                       |
| Add a new cache key                 | `src/api/queryKeys.ts`                                       |
| Make a new API call                 | `src/api/services/<resource>.service.ts`                     |
| Fetch data in a component           | Base query hook in `src/api/hooks/`                          |
| POST / PUT / DELETE                 | Mutation hook in `src/api/hooks/`                            |
| Transform data differently per page | `select` option on base hook                                 |
| Run `useEffect` when data loads     | Page-level hook in `src/api/hooks/`                          |
| Add a validation/derived flag       | `src/utils/<resource>.validations.ts` + page hook            |
| Filter a table (URL-persisted)      | `useUrlFilters` inside page hook (`use<Resource>Page.ts`)    |
| Filter a table (local only)         | Applied-filters state in `useResourceFilters.ts` + page hook |
| Populate a dropdown from API        | Separate query hook with `staleTime: Infinity`               |
| Combine queries for one page        | Page-level hook                                              |
