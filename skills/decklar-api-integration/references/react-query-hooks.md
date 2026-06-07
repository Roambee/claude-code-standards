# React Query Hooks Reference

## 1 — QueryClient Configuration (one instance, shared globally)

```ts
// src/lib/queryClient.ts
import { QueryClient } from '@tanstack/react-query';

export const queryClient = new QueryClient({
	defaultOptions: {
		queries: {
			staleTime: 30_000, // 30 s — data stays fresh; no refetch on tab switch within 30 s
			gcTime: 5 * 60_000, // 5 min — keep unused cache in memory after unmount
			refetchOnWindowFocus: false,
			retry: 1 // retry a failed request once before showing error
		}
	}
});
```

```tsx
// root.component.tsx — define QueryClient inline and wrap the entire app
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { BrowserRouter } from 'react-router-dom';
import App from './App';

const queryClient = new QueryClient({
	defaultOptions: {
		queries: {
			staleTime: 30_000,
			gcTime: 5 * 60_000,
			refetchOnWindowFocus: false,
			retry: 1
		}
	}
});

export default function Root() {
	return (
		<QueryClientProvider client={queryClient}>
			<BrowserRouter>
				<App />
			</BrowserRouter>
		</QueryClientProvider>
	);
}
```

> **`staleTime` vs `gcTime`:** `staleTime` controls when data is eligible for a background refetch. `gcTime` controls how long unused data stays in memory after unmount. They are independent.

---

## 2 — Endpoint Constants (add to `src/api/endpoints.ts`)

New business data endpoints all use `/v2/`. Define that prefix **once** as `BASE_URL` — never repeat it inside individual path strings.

> **Prefix conventions in this monorepo:**
>
> -   `/v2/` — new business data APIs (bees, shipments, webhooks, integrations, assets, etc.) → use `BASE_URL`
> -   `/v1/` — legacy or service-specific APIs — keep as-is, do not change
> -   `/auth/`, `/account/`, `/admin/`, `/rule/`, `/audit/` — platform management — keep as-is

```ts
// src/api/endpoints.ts
const BASE_URL = '/v2'; // only for new business data endpoints

export const ENDPOINTS = {
	// New business data routes — always /v2/
	ITEMS: {
		LIST: `${BASE_URL}/<your-resource>`,
		DETAIL: (id: string) => `${BASE_URL}/<your-resource>/${id}`
	},

	// Auth — no version prefix
	AUTH: {
		LOGOUT: '/auth/logout'
	},

	// Reference / filter data — may use their own paths
	FILTER_OPTIONS: {
		STATUSES: '/filter-options/statuses'
	}
} as const;
```

**Why `BASE_URL`:** A single declaration means a version bump from `/v2` to `/v3` is one line. No hunt-and-replace across every business endpoint string.

---

## 3 — Query Key Factory

All cache keys live in one file. Never write raw string arrays inside hooks.

```ts
// src/api/queryKeys.ts
export const queryKeys = {
	// Replace 'items' with your resource name
	items: {
		all: ['items'] as const,
		lists: () => [...queryKeys.items.all, 'list'] as const,
		list: (filters: Record<string, unknown>) => [...queryKeys.items.lists(), filters] as const,
		details: () => [...queryKeys.items.all, 'detail'] as const,
		detail: (id: string) => [...queryKeys.items.details(), id] as const
	},

	filterOptions: {
		all: ['filter-options'] as const,
		statuses: () => [...queryKeys.filterOptions.all, 'statuses'] as const,
		categories: () => [...queryKeys.filterOptions.all, 'categories'] as const
	}
} as const;
```

### Surgical cache invalidation using the hierarchy

```ts
const qc = useQueryClient();

qc.invalidateQueries({ queryKey: queryKeys.items.all }); // bust everything for resource
qc.invalidateQueries({ queryKey: queryKeys.items.lists() }); // only lists (not details)
qc.invalidateQueries({ queryKey: queryKeys.items.detail(id) }); // one specific detail
```

> **Why `as const`:** TypeScript infers the exact tuple type, not `string[]`. Prevents silent key mismatches on invalidation.

---

## 4 — Service Layer (pure async — no React, no hooks)

```ts
// src/api/services/items.service.ts
// @ts-ignore
import { API, getAuthUser } from '@roambee/client-utility';
import { ENDPOINTS } from '../endpoints';
import type { Item, CreateItemPayload, UpdateItemPayload } from '@/types/item';

export interface ItemListParams {
	page?: number;
	limit?: number;
	search?: string;
	status?: string;
}

export const itemsService = {
	getList: (params?: ItemListParams): Promise<Item[]> => {
		const user = getAuthUser();
		return API('GET', `${ENDPOINTS.ITEMS.LIST}?account_id=${encodeURIComponent(user.account.uuid)}`, params);
	},

	getById: (id: string): Promise<Item> => API('GET', ENDPOINTS.ITEMS.DETAIL(id)),

	create: (data: CreateItemPayload): Promise<Item> => API('POST', ENDPOINTS.ITEMS.LIST, data),

	update: (id: string, data: UpdateItemPayload): Promise<Item> => API('PUT', ENDPOINTS.ITEMS.DETAIL(id), data),

	delete: (id: string): Promise<void> => API('DELETE', ENDPOINTS.ITEMS.DETAIL(id), {})
};

// src/api/services/index.ts — re-export all services
export * from './items.service';
export * from './filterOptions.service';
```

**Rules:**

-   Never import React or call hooks inside a service file
-   Each function does exactly one API call
-   Return the typed response directly — no transforms here

---

## 5 — Base Query Hooks

Thin wrappers that connect service functions to React Query. No business logic. Accept a `select` option for per-callsite data transforms.

```ts
// src/api/hooks/useItems.ts
import { useQuery, keepPreviousData, type UseQueryOptions } from '@tanstack/react-query';
import { itemsService, type ItemListParams } from '../services/items.service';
import { queryKeys } from '../queryKeys';
import type { Item } from '@/types/item';

// Generic TData lets each callsite transform via `select` without splitting the cache
export const useItemsList = <TData = Item[]>(params?: ItemListParams, options?: Omit<UseQueryOptions<Item[], Error, TData>, 'queryKey' | 'queryFn'>) =>
	useQuery({
		queryKey: queryKeys.items.list(params ?? {}),
		queryFn: () => itemsService.getList(params),
		placeholderData: keepPreviousData, // prevents flicker when filters change
		...options
	});

export const useItem = (id: string) =>
	useQuery({
		queryKey: queryKeys.items.detail(id),
		queryFn: () => itemsService.getById(id),
		enabled: !!id // don't fire if id is empty
	});
```

### Using `select` for per-page transforms (no extra fetch)

```ts
// Component A — only active items, sorted
const { data: activeItems } = useItemsList(
  {},
  { select: (items) => items.filter((i) => i.status === 'active').sort(...) }
);

// Component B — items grouped by category
const { data: byCategory } = useItemsList(
  {},
  { select: (items) => items.reduce((acc, item) => { ... }, {}) }
);
// Both share ONE cache entry — one network request
```

> **`select` vs page hook:** Use `select` for simple transforms (filter, sort, map). Use a page-level hook when you need `useEffect`, derived flags, or validation logic.

---

## 6 — Filter Options from API (long cache)

Filter dropdowns (statuses, categories, roles) rarely change mid-session. Fetch once, cache indefinitely.

```ts
// src/api/hooks/useFilterOptions.ts
import { useQuery } from '@tanstack/react-query';
import { filterOptionsService } from '../services/filterOptions.service';
import { queryKeys } from '../queryKeys';

export const useStatusOptions = () =>
	useQuery({
		queryKey: queryKeys.filterOptions.statuses(),
		queryFn: filterOptionsService.getStatuses,
		staleTime: Infinity, // fetched once per session
		gcTime: 1000 * 60 * 30 // keep in memory for 30 min
	});

export const useCategoryOptions = () =>
	useQuery({
		queryKey: queryKeys.filterOptions.categories(),
		queryFn: filterOptionsService.getCategories,
		staleTime: Infinity,
		gcTime: 1000 * 60 * 30
	});
```

> If `useStatusOptions()` is called on 10 different pages, only one network request is ever made.

---

## 7 — Mutation Hooks (POST / PUT / DELETE)

Always invalidate or update the cache in `onSuccess`.

```ts
// src/api/hooks/useItems.ts (continued)
import { useMutation, useQueryClient } from '@tanstack/react-query';
// @ts-ignore
import { EventEmitter } from '@roambee/client-utility';
import { itemsService } from '../services/items.service';
import { queryKeys } from '../queryKeys';

export const useCreateItem = () => {
	const qc = useQueryClient();
	return useMutation({
		mutationFn: itemsService.create,
		onSuccess: () => {
			qc.invalidateQueries({ queryKey: queryKeys.items.lists() });
			EventEmitter.emit('showSnackbar', { variant: 'success', message: 'Created successfully.' });
		},
		onError: (err: unknown) => {
			EventEmitter.emit('showSnackbar', { variant: 'error', message: (err as Error)?.message || 'Create failed.' });
		}
	});
};

export const useUpdateItem = () => {
	const qc = useQueryClient();
	return useMutation({
		mutationFn: ({ id, data }: { id: string; data: UpdateItemPayload }) => itemsService.update(id, data),
		onSuccess: (updatedItem) => {
			qc.setQueryData(queryKeys.items.detail(updatedItem.id), updatedItem); // instant update
			qc.invalidateQueries({ queryKey: queryKeys.items.lists() });
			EventEmitter.emit('showSnackbar', { variant: 'success', message: 'Updated successfully.' });
		},
		onError: (err: unknown) => {
			EventEmitter.emit('showSnackbar', { variant: 'error', message: (err as Error)?.message || 'Update failed.' });
		}
	});
};

export const useDeleteItem = () => {
	const qc = useQueryClient();
	return useMutation({
		mutationFn: itemsService.delete,
		onSuccess: (_, deletedId) => {
			qc.removeQueries({ queryKey: queryKeys.items.detail(deletedId) });
			qc.invalidateQueries({ queryKey: queryKeys.items.lists() });
			EventEmitter.emit('showSnackbar', { variant: 'success', message: 'Deleted successfully.' });
		},
		onError: (err: unknown) => {
			EventEmitter.emit('showSnackbar', { variant: 'error', message: (err as Error)?.message || 'Delete failed.' });
		}
	});
};
```

### Cache strategy at a glance

| After mutation  | Strategy                                                     |
| --------------- | ------------------------------------------------------------ |
| Created an item | `invalidateQueries` on lists key                             |
| Updated an item | `setQueryData` on detail key + `invalidateQueries` on lists  |
| Deleted an item | `removeQueries` on detail key + `invalidateQueries` on lists |
| Bulk action     | `invalidateQueries` on `all` key for the resource            |

---

## 8 — Validation & Transformation Utilities

Pure functions — no React, no hooks, no side effects. Live in `src/utils/`. Reusable across multiple page hooks with zero duplication.

```ts
// src/utils/resource.validations.ts
import type { ResourceType } from '@/types/resource';

export interface ResourceListValidation {
	hasInvalidItems: boolean;
	isHealthy: boolean;
	totalCount: number;
}

// Pure function — same input always gives same output
export const validateResourceList = (items: ResourceType[]): ResourceListValidation => ({
	hasInvalidItems: items.some((i) => !i.isValid),
	isHealthy: items.every((i) => i.isValid),
	totalCount: items.length
});

// Another pure util — filtering for export
export const getExportableItems = (items: ResourceType[]): ResourceType[] => items.filter((i) => i.isExportable === true);
```

Calling the same util from multiple page hooks — no duplication:

```ts
// Page Hook A
const validation = data ? validateResourceList(data) : null;

// Page Hook B — same function, totally different page context
const validation = data ? validateResourceList(data) : null;
const exportable = data ? getExportableItems(data) : [];
```

> **Rule:** If you write an `if (items.some(...))` directly inside a page hook, that logic belongs in a `utils/` file instead. Page hooks compose — they don't contain business rules.

---

## 9 — Page-Level Composed Hook

One hook per page. Composes **filter state hook** + base query hooks + validation utils + side effects.
**Components call only this hook.**

> **Filter state as a separate file (preferred for complex pages):** The architecture allows extracting filter state into its own `useResourceTableFilters.ts` hook. This keeps the page hook focused on data composition, and the filter hook focused on UI state. See Section 9b below.

### 9a — Page hook (all-in-one, suitable for simpler pages)

```ts
// src/api/hooks/useItemsPage.ts
import { useState, useCallback, useEffect } from 'react';
import { useItemsList } from './useItems';
import { useStatusOptions, useCategoryOptions } from './useFilterOptions';
import { keepPreviousData } from '@tanstack/react-query';

interface ItemFilters {
	search: string;
	status: string;
	page: number;
	limit: number;
}

const DEFAULT_FILTERS: ItemFilters = { search: '', status: 'all', page: 1, limit: 20 };

export const useItemsPage = () => {
	// Applied-filters pattern — query only updates when user clicks "Apply"
	const [draftFilters, setDraftFilters] = useState<ItemFilters>(DEFAULT_FILTERS);
	const [appliedFilters, setAppliedFilters] = useState<ItemFilters>(DEFAULT_FILTERS);

	const listQuery = useItemsList(appliedFilters);
	const statusOptions = useStatusOptions();
	const categoryOptions = useCategoryOptions();

	// Side effects on first load — not possible with `select`
	useEffect(() => {
		if (!listQuery.data) return;
		if (listQuery.data.length === 0) {
			console.warn('[useItemsPage] No items returned for current filters');
		}
	}, [listQuery.data]);

	const isInitialLoading = listQuery.isLoading || statusOptions.isLoading || categoryOptions.isLoading;

	const updateDraft = useCallback(<K extends keyof ItemFilters>(key: K, value: ItemFilters[K]) => setDraftFilters((prev) => ({ ...prev, [key]: value, ...(key !== 'page' ? { page: 1 } : {}) })), []);

	const applyFilters = useCallback(() => {
		setAppliedFilters({ ...draftFilters, page: 1 });
	}, [draftFilters]);

	const resetFilters = useCallback(() => {
		setDraftFilters(DEFAULT_FILTERS);
		setAppliedFilters(DEFAULT_FILTERS);
	}, []);

	return {
		// Filter state
		draftFilters,
		appliedFilters,
		updateDraft,
		applyFilters,
		resetFilters,
		// Table data
		items: listQuery.data ?? [],
		isLoading: isInitialLoading, // full-page skeleton — first load only
		isFetching: listQuery.isFetching, // inline overlay — background refetches
		isError: listQuery.isError,
		error: listQuery.error,
		// Dropdown options
		statusOptions: statusOptions.data ?? [],
		categoryOptions: categoryOptions.data ?? []
	};
};
```

```tsx
// Component — zero API logic
function ItemsPage() {
	const { draftFilters, updateDraft, applyFilters, resetFilters, items, isLoading, isFetching, isError, statusOptions } = useItemsPage();

	if (isLoading) return <Spinner />;
	if (isError) return <ErrorState />;

	return (
		<div>
			{/* Filter controls */}
			<div className="grid grid-cols-3 gap-6 mb-3">
				<Input label="Search" value={draftFilters.search} onChange={(e) => updateDraft('search', e.target.value)} />
				<Select value={draftFilters.status} onValueChange={(v) => updateDraft('status', v)}>
					{statusOptions.map((s) => (
						<SelectItem key={s.value} value={s.value}>
							{s.label}
						</SelectItem>
					))}
				</Select>
			</div>
			<div className="flex gap-2 justify-end mb-4">
				<Button variant="outline" size="sm" onClick={resetFilters}>
					Clear
				</Button>
				<Button variant="primary" size="sm" onClick={applyFilters}>
					Apply
				</Button>
			</div>

			{/* Loading overlay — subtle, old data stays visible */}
			<div className="relative">
				{isFetching && (
					<div className="absolute inset-0 bg-white/60 flex items-center justify-center z-10 rounded-lg">
						<span className="animate-spin h-6 w-6 border-4 border-primary border-t-transparent rounded-full" />
					</div>
				)}
				<DataTable columns={columns} data={items} enableSorting enablePagination showPageNumbers enableColumnResizing />
			</div>
		</div>
	);
}
```

> **`isLoading` vs `isFetching`:** Use `isLoading` for full-page skeletons (first load only). Use `isFetching` for subtle inline overlays (subsequent filter changes). Never show a full spinner every time a filter changes.

### 9b — Separate filter state hook (preferred for complex pages)

For pages with many filter fields, extract filter state into its own file. This is the pattern from the architecture guide.

```ts
// src/api/hooks/useResourceFilters.ts — owns ONLY filter state
import { useState, useCallback } from 'react';

export interface ResourceFilters {
	search: string;
	status: string;
	page: number;
	limit: number;
}

const DEFAULT_FILTERS: ResourceFilters = { search: '', status: 'all', page: 1, limit: 20 };

export const useResourceTableFilters = () => {
	const [filters, setFilters] = useState<ResourceFilters>(DEFAULT_FILTERS);

	const updateFilter = useCallback(<K extends keyof ResourceFilters>(key: K, value: ResourceFilters[K]) => {
		setFilters((prev) => ({
			...prev,
			[key]: value,
			...(key !== 'page' ? { page: 1 } : {}) // reset page on every filter change
		}));
	}, []);

	const resetFilters = useCallback(() => setFilters(DEFAULT_FILTERS), []);

	return { filters, updateFilter, resetFilters };
};
```

```ts
// src/api/hooks/useResourcePage.ts — composed page hook using the separate filter hook
import { useResourceTableFilters } from './useResourceFilters';
import { useResourceList } from './useResource';
import { validateResourceList } from '@/utils/resource.validations';

export const useResourcePage = () => {
	const { filters, updateFilter, resetFilters } = useResourceTableFilters();

	// filters flows directly into query key → filter change → new fetch automatically
	const query = useResourceList(filters);

	const validation = query.data ? validateResourceList(query.data) : null;

	return {
		filters,
		updateFilter,
		resetFilters,
		items: query.data ?? [],
		isLoading: query.isLoading,
		isFetching: query.isFetching,
		isError: query.isError,
		// Derived validation flags from utils
		hisHealthy: validation?.isHealthy ?? true,
		totalCount: validation?.totalCount ?? 0
	};
};
```

> **File split rule:** One `useXTableFilters.ts` per resource (filter state only). One `useXPage.ts` per page (data composition only). Components call the page hook and get everything.

---

## 10 — `staleTime` Guide

| Data type                                 | Recommended `staleTime`                   |
| ----------------------------------------- | ----------------------------------------- |
| Real-time / frequently updated            | `0` (default)                             |
| Normal business data                      | `5 minutes`                               |
| Current user (`/me`)                      | `Infinity` — refetch on login/logout only |
| Reference / config data (roles, statuses) | `Infinity`                                |
| Dashboard aggregates                      | `1–2 minutes`                             |
