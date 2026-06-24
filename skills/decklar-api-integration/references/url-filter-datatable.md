# URL-Persisted Filter Pattern for Data Tables

> **3-layer pattern.** Any developer can add fully URL-persisted, bookmarkable filters to any data table in 4 files. Follow this guide top-to-bottom.

---

## The 3 layers

| Layer                | Owner                                  | Job                                                                                                                 |
| -------------------- | -------------------------------------- | ------------------------------------------------------------------------------------------------------------------- |
| `useUrlFilters`      | `@decklar/client-utility`              | Reads/writes filter state to URL search params. Manages draft vs applied split. Never write yourself — just import. |
| `useResourcePage.ts` | `src/api/hooks/`                       | Calls `useUrlFilters`, composes it with the base query hook. **One file per table page.**                           |
| `buildFilterQuery()` | `src/api/services/resource.service.ts` | Converts the applied filter object into an OData/query-string for the API. Pure function.                           |

---

## Step-by-step implementation

### Step 1 — Define your filter interface + defaults (inside `useResourcePage.ts`)

```ts
// What filters does the table have?
interface ResourceFilters {
	search: string;
	status: string;
	account: string;
	dateFrom: string; // ms timestamp as string, '' = not set
	dateTo: string;
}

const DEFAULT_FILTERS: ResourceFilters = {
	search: '',
	status: 'all',
	account: '',
	dateFrom: '',
	dateTo: ''
};

// List every key you want persisted in the URL
const FILTER_KEYS: (keyof ResourceFilters)[] = ['search', 'status', 'account', 'dateFrom', 'dateTo'];
```

**Rules:**

-   Every filter the user can set goes in `ResourceFilters`
-   `DEFAULT_FILTERS` is also the "cleared" state
-   Only keys in `FILTER_KEYS` are read/written from the URL — list them all

---

### Step 2 — Call `useUrlFilters` in the page hook

```ts
// src/api/hooks/useResourcePage.ts
import { useState, useEffect, useCallback } from 'react';
import { useSearchParams } from 'react-router-dom';
import { useUrlFilters } from '@decklar/client-utility';
import { useResourceList } from './useResource';

export const useResourcePage = () => {
	const [searchParams, setSearchParams] = useSearchParams();

	const {
		filters, // draft — what's in the input boxes right now
		appliedFilters, // committed — what's in the URL and what the API sees
		page,
		updateFilter, // (key, value) => void — update ONE draft field, no URL write
		applyFilters, // () => void — push draft → URL → triggers refetch
		clearFilters, // () => void — reset all to defaults, remove URL params
		setPage // (n) => void — write page number to URL
	} = useUrlFilters<ResourceFilters>(searchParams, setSearchParams, {
		defaults: DEFAULT_FILTERS,
		keys: FILTER_KEYS
	});

	// ── Date picker UI bridge (only needed when you have date filters) ────────
	const [dateRange, setDateRangeState] = useState({
		from: appliedFilters.dateFrom ? new Date(Number(appliedFilters.dateFrom)) : undefined,
		to: appliedFilters.dateTo ? new Date(Number(appliedFilters.dateTo)) : undefined
	});

	// Sync when URL changes (browser back/forward)
	useEffect(() => {
		setDateRangeState({
			from: appliedFilters.dateFrom ? new Date(Number(appliedFilters.dateFrom)) : undefined,
			to: appliedFilters.dateTo ? new Date(Number(appliedFilters.dateTo)) : undefined
		});
	}, [appliedFilters.dateFrom, appliedFilters.dateTo]);

	const setDateRange = useCallback(
		(range: { from?: Date; to?: Date }) => {
			setDateRangeState(range);
			updateFilter('dateFrom', range.from ? String(range.from.getTime()) : '');
			updateFilter('dateTo', range.to ? String(range.to.getTime()) : '');
		},
		[updateFilter]
	);
	// ─────────────────────────────────────────────────────────────────────────

	// CRITICAL: pass appliedFilters to the query — never filters (draft)
	const query = useResourceList({ ...appliedFilters, page });

	return {
		filters, // bind to input values
		updateFilter, // call onChange
		applyFilters, // call on Apply button
		clearFilters, // call on Clear button
		page,
		setPage,
		dateRange,
		setDateRange, // only when using date filters
		items: query.data ?? [],
		isLoading: query.isLoading,
		isFetching: query.isFetching,
		isError: query.isError
	};
};
```

> **No date filters?** Delete the entire "Date picker UI bridge" block and remove `dateFrom`/`dateTo` from the interface.

---

### Step 3 — Build the API query string in the service

```ts
// src/api/services/resource.service.ts
import { API } from '@decklar/client-utility';
import { ENDPOINTS } from '../endpoints';

const PAGE_SIZE = 10;

export const buildFilterQuery = (filters: ResourceFilters & { page: number }): string => {
	const params = new URLSearchParams();

	// Pagination
	params.set('$size', String(PAGE_SIZE));
	params.set('$offset', String((filters.page - 1) * PAGE_SIZE));
	params.set('$orderBy', 'createdAt desc');

	// Dynamic filter predicates — only add non-empty values
	const parts: string[] = [];

	if (filters.status && filters.status !== 'all') parts.push(`status eq '${filters.status}'`);

	if (filters.search?.trim())
		// Always escape single quotes in user input
		parts.push(`name eq '${filters.search.trim().replace(/'/g, "''")}'`);

	if (filters.account && filters.account !== 'all') parts.push(`accountId eq '${filters.account}'`);

	if (filters.dateFrom) parts.push(`createdAt ge '${filters.dateFrom}'`);

	if (filters.dateTo) parts.push(`createdAt le '${filters.dateTo}'`);

	if (parts.length) params.set('$filter', parts.join(' and '));

	return params.toString();
};

// Service function uses the query builder
export const getResourceList = (filters: ResourceFilters & { page: number }) => API('GET', `${ENDPOINTS.RESOURCE.LIST}?${buildFilterQuery(filters)}`);
```

---

### Step 4 — Wire in the component (one hook call)

```tsx
// src/components/Resource/components/Home/index.tsx
import { Input, Select, SelectTrigger, SelectValue, SelectContent, SelectItem, Button, DataTable } from '@decklar/ui-library';
import { DateRangePicker } from '@decklar/ui-library';
import { useResourcePage } from '../../../../api/hooks/useResourcePage';
import { STATUS_OPTIONS } from '../../constants';
import { columns } from './columns';

export default function ResourceHome() {
	const { filters, updateFilter, applyFilters, clearFilters, dateRange, setDateRange, items, isLoading, isFetching, page, setPage } = useResourcePage();

	return (
		<div>
			{/* Filter row */}
			<div style={{ display: 'flex', gap: 8, marginBottom: 12 }}>
				<Input value={filters.search} onChange={(e) => updateFilter('search', e.target.value)} onKeyDown={(e) => e.key === 'Enter' && applyFilters()} placeholder="Search..." />

				<Select value={filters.status} onValueChange={(v) => updateFilter('status', v)}>
					<SelectTrigger style={{ width: 160 }}>
						<SelectValue placeholder="Status" />
					</SelectTrigger>
					<SelectContent>
						<SelectItem value="all">All</SelectItem>
						{STATUS_OPTIONS.map((o) => (
							<SelectItem key={o.value} value={o.value}>
								{o.label}
							</SelectItem>
						))}
					</SelectContent>
				</Select>

				<DateRangePicker value={dateRange} onChange={setDateRange} />

				<Button variant="primary" onClick={applyFilters}>
					Apply
				</Button>
				<Button variant="secondary" onClick={clearFilters}>
					Clear
				</Button>
			</div>

			{/* Table */}
			<div style={{ position: 'relative' }}>
				{isFetching && !isLoading && (
					<div style={{ position: 'absolute', inset: 0, background: 'rgba(255,255,255,0.6)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 10 }}>
						<span className="animate-spin h-6 w-6 border-4 border-primary border-t-transparent rounded-full" />
					</div>
				)}
				<DataTable columns={columns} data={items} isLoading={isLoading} enableSorting enablePagination showPageNumbers enableColumnResizing currentPage={page} onPageChange={setPage} />
			</div>
		</div>
	);
}
```

---

## What happens in the URL

| User action         | URL effect                                     |
| ------------------- | ---------------------------------------------- |
| Types in a filter   | `filters` draft updates — URL unchanged        |
| Clicks **Apply**    | URL becomes `?status=active&search=abc&page=1` |
| Clicks **Clear**    | All params removed, defaults restored          |
| Browser **Back**    | `useUrlFilters` reads URL and syncs state      |
| Copies & shares URL | Recipient lands on exact same filtered view    |

---

## Draft vs applied — the core rule

```
filters         →  what is in the input boxes right now
appliedFilters  →  what is written to the URL and what the API sees
```

**Always pass `appliedFilters` to the query, never `filters`.** This prevents a refetch on every keystroke.

---

## No date filters? Minimal template

When the table has no date range picker, the page hook reduces to:

```ts
export const useResourcePage = () => {
	const [searchParams, setSearchParams] = useSearchParams();

	const { filters, appliedFilters, page, updateFilter, applyFilters, clearFilters, setPage } = useUrlFilters<ResourceFilters>(searchParams, setSearchParams, {
		defaults: DEFAULT_FILTERS,
		keys: FILTER_KEYS
	});

	const query = useResourceList({ ...appliedFilters, page });

	return {
		filters,
		updateFilter,
		applyFilters,
		clearFilters,
		page,
		setPage,
		items: query.data ?? [],
		isLoading: query.isLoading,
		isFetching: query.isFetching
	};
};
```

---

## Checklist

-   [ ] `ResourceFilters` interface defined with all filter keys
-   [ ] `DEFAULT_FILTERS` covers every key in the interface
-   [ ] `FILTER_KEYS` array lists every key to persist in URL
-   [ ] `useUrlFilters` called in `useResourcePage.ts` — not in the component
-   [ ] Query receives `appliedFilters` — not `filters`
-   [ ] `buildFilterQuery` lives in the service file — no query building in hooks
-   [ ] Component calls `useResourcePage()` — no other hooks for data fetching
-   [ ] Apply button calls `applyFilters()`, Clear button calls `clearFilters()`

---

## Real-world example in this repo

[packages/client/webhook/src/api/hooks/useWebhookEventsPage.ts](../../../../../packages/client/webhook/src/api/hooks/useWebhookEventsPage.ts)

10 filters + date range + pagination — full implementation to copy from.
