# Advanced Patterns Reference

> Generic patterns applicable to **any** module — not specific to any single app.

## Table of Contents

1. [OData-style query string building](#1--odata-style-query-string-building)
2. [Conditional Zod refinements](#2--conditional-zod-refinements)
3. [Tab-based routing with URL search params](#3--tab-based-routing-with-url-search-params)
4. [Route state passing between pages](#4--route-state-passing-between-pages)
5. [Toast portal for loading indicators](#5--toast-portal-for-loading-indicators)
6. [Multi-select rows in DataTable](#6--multi-select-rows-in-datatable)
7. [Timezone auto-detection](#7--timezone-auto-detection)
8. [Types and constants files per module](#8--types-and-constants-files-per-module)
9. [Dynamic form fields based on selection](#9--dynamic-form-fields-based-on-selection)
10. [Payload builder with dynamic keys](#10--payload-builder-with-dynamic-keys)
11. [URL-persisted filter state with `useUrlFilters`](#11--url-persisted-filter-state-with-useurlfilters)

---

## 1 — OData-style query string building

When the backend uses OData-like parameters (`$filter`, `$fields`, `$orderBy`, `$size`, `$offset`), build the query string dynamically in the **service layer** — never in hooks or components.

```ts
// src/api/services/resource.service.ts
export const buildFilterQuery = (filters: ResourceFilters): string => {
	const params = new URLSearchParams();

	// Selection
	params.set('$fields', 'id,name,status,createdAt');
	params.set('$orderBy', 'createdAt desc');

	// Pagination
	params.set('$size', String(filters.limit));
	params.set('$offset', String((filters.page - 1) * filters.limit));

	// Dynamic filters — only add non-empty values
	const filterParts: string[] = [];

	if (filters.status && filters.status !== 'all') {
		filterParts.push(`status eq '${filters.status}'`);
	}
	if (filters.search?.trim()) {
		// Escape single quotes in user input
		const escaped = filters.search.trim().replace(/'/g, "''");
		filterParts.push(`name eq '${escaped}'`);
	}
	if (filters.dateFrom) {
		filterParts.push(`createdAt ge '${filters.dateFrom}'`);
	}
	if (filters.dateTo) {
		filterParts.push(`createdAt le '${filters.dateTo}'`);
	}

	if (filterParts.length > 0) {
		params.set('$filter', filterParts.join(' and '));
	}

	return params.toString();
};
```

**Rules:**

-   Always escape single quotes in user input: `.replace(/'/g, "''")`
-   Only add filter params when the value is non-empty
-   Pagination offset is `(page - 1) * limit`
-   Service function returns `API('GET', \`\${ENDPOINTS.RESOURCE.LIST}?\${queryString}\`)`

---

## 2 — Conditional Zod refinements

For complex forms where required fields depend on other field values, use chained `.refine()` calls on the **object schema** (not on individual fields).

```ts
import { z } from 'zod';

const resourceSchema = z
	.object({
		name: z.string().min(1, 'Name is required'),
		type: z.string().min(1, 'Type is required'),
		endpoint: z.string().optional(),
		accessKey: z.string().optional(),
		region: z.string().optional(),
		authType: z.string().optional(),
		username: z.string().optional(),
		password: z.string().optional()
	})
	// Conditional: if type === 'HTTP', endpoint is required
	.refine((d) => d.type !== 'HTTP' || !!d.endpoint?.trim(), {
		message: 'Endpoint is required for HTTP type',
		path: ['endpoint']
	})
	// Conditional: if type === 'SQS', accessKey and region are required
	.refine((d) => d.type !== 'SQS' || !!d.accessKey?.trim(), {
		message: 'Access Key is required for SQS type',
		path: ['accessKey']
	})
	.refine((d) => d.type !== 'SQS' || !!d.region?.trim(), {
		message: 'Region is required for SQS type',
		path: ['region']
	})
	// Conditional: if authType === 'basic', username and password are required
	.refine((d) => d.authType !== 'basic' || !!d.username?.trim(), {
		message: 'Username is required for basic auth',
		path: ['username']
	})
	.refine((d) => d.authType !== 'basic' || !!d.password?.trim(), {
		message: 'Password is required for basic auth',
		path: ['password']
	});
```

**Pattern:** `d.field !== 'VALUE' || !!d.dependentField?.trim()` — reads as "if field IS this value, then dependentField must be non-empty."

**Virtual error paths** — for checkbox groups or multi-select validation where no single field maps to the error:

```ts
.refine((d) => d.events.length > 0, {
    message: 'Select at least one event',
    path: ['_eventsRequired']  // virtual path — show via formState.errors._eventsRequired
})
```

---

## 3 — Tab-based routing with URL search params

Use `useSearchParams` for tab state instead of component-level `useState`. This makes tabs shareable via URL.

```tsx
import { useSearchParams, useNavigate } from 'react-router-dom';

function ResourceLayout() {
	const [searchParams] = useSearchParams();
	const navigate = useNavigate();
	const activeTab = searchParams.get('tab') || 'overview';

	const tabs = [
		{ id: 'overview', label: 'Overview', icon: <Dashboard size={16} /> },
		{ id: 'events', label: 'Events', icon: <Activity size={16} /> },
		{ id: 'settings', label: 'Settings', icon: <Settings size={16} /> }
	];

	const handleTabChange = (tabId: string) => {
		navigate(`?tab=${tabId}`, { replace: true });
	};

	return (
		<div style={{ display: 'flex', gap: '1rem' }}>
			<nav>
				{tabs.map((tab) => (
					<button key={tab.id} onClick={() => handleTabChange(tab.id)} className={activeTab === tab.id ? 'active' : ''}>
						{tab.icon} {tab.label}
					</button>
				))}
			</nav>
			<main style={{ flex: 1 }}>
				{activeTab === 'overview' && <OverviewTab />}
				{activeTab === 'events' && <EventsTab />}
				{activeTab === 'settings' && <SettingsTab />}
			</main>
		</div>
	);
}
```

**Rules:**

-   Use `{ replace: true }` on navigate to avoid polluting browser history with every tab switch
-   Default tab is the first one (fallback when no `?tab=` param exists)
-   Tabs should load different components, not just show/hide sections

---

## 4 — Route state passing between pages

Pass data between pages via `useNavigate` state + `useLocation` — avoids redundant API calls when navigating from list to edit.

```tsx
// List page — navigate with state
const navigate = useNavigate();
const handleEdit = (item: Resource) => {
	navigate('/resource/edit', { state: { editData: item } });
};

// Edit page — receive state
import { useLocation, useNavigate } from 'react-router-dom';

function EditPage() {
	const location = useLocation();
	const navigate = useNavigate();
	const editData = location.state?.editData as Resource | undefined;

	// If no state (direct URL access), redirect back
	if (!editData) {
		navigate('/resource');
		return null;
	}

	return <ResourceForm defaultValues={editData} />;
}
```

**When to use:**

-   Edit forms pre-populated from the list row data
-   Detail pages that already have the data from the parent
-   Redirect params carrying context (e.g., filters, source page)

**When NOT to use:**

-   When the user might bookmark or share the URL (state is lost on refresh)
-   When the data must be the latest from the server

---

## 5 — Toast portal for loading indicators

When refetching data in the background (`isFetching` is true but `isLoading` is false), show a subtle Toast notification via `createPortal` instead of blocking the UI.

```tsx
import { createPortal } from 'react-dom';
import { Toast } from '@decklar/ui-library';

function ResourcePage() {
	const { data, isFetching, isLoading } = useResourcePage();

	return (
		<>
			{/* Normal UI */}
			<DataTable columns={columns} data={data} />

			{/* Background loading toast — only when refetching existing data */}
			{isFetching &&
				!isLoading &&
				createPortal(
					<div style={{ position: 'fixed', bottom: 24, right: 24, zIndex: 9999 }}>
						<Toast variant="default" message="Loading records..." />
					</div>,
					document.body
				)}
		</>
	);
}
```

**Rules:**

-   Only show when `isFetching && !isLoading` — never on first load
-   Use `createPortal` to `document.body` for proper z-index stacking
-   Position: fixed bottom-right, z-index 9999
-   Use `Toast` from `@decklar/ui-library`

---

## 6 — Multi-select rows in DataTable

For operations that act on multiple rows (bulk delete, bulk export, bulk replay), track selection with a `Set<string>`.

```tsx
import { useState } from 'react';
import { DataTable, Checkbox, Button } from '@decklar/ui-library';

function BulkActionPage() {
	const [selectedIds, setSelectedIds] = useState<Set<string>>(new Set());

	const toggleSelection = (id: string) => {
		setSelectedIds((prev) => {
			const next = new Set(prev);
			if (next.has(id)) next.delete(id);
			else next.add(id);
			return next;
		});
	};

	const toggleAll = (allIds: string[]) => {
		setSelectedIds((prev) => {
			if (prev.size === allIds.length) return new Set(); // deselect all
			return new Set(allIds);
		});
	};

	const columns = [
		{
			id: 'select',
			header: () => <Checkbox checked={selectedIds.size === data.length && data.length > 0} onCheckedChange={() => toggleAll(data.map((d) => d.id))} />,
			cell: ({ row }) => <Checkbox checked={selectedIds.has(row.original.id)} onCheckedChange={() => toggleSelection(row.original.id)} />,
			size: 40
		}
		// ... other columns
	];

	return (
		<>
			{selectedIds.size > 0 && (
				<div className="flex items-center gap-2 mb-2">
					<span>{selectedIds.size} selected</span>
					<Button variant="primary" size="sm" onClick={() => handleBulkAction(selectedIds)}>
						Process Selected
					</Button>
				</div>
			)}
			<DataTable columns={columns} data={data} enablePagination showPageNumbers />
		</>
	);
}
```

**Rules:**

-   Use `Set<string>` for O(1) add/delete/has — never an array
-   Show selection count and bulk action buttons above the table
-   Disable bulk action button when `selectedIds.size === 0`
-   Clear selection after successful bulk operation

---

## 7 — Timezone auto-detection

Auto-detect the user's timezone for date-related filters and displays:

```ts
const getUserTimezone = (): string => {
	try {
		return Intl.DateTimeFormat().resolvedOptions().timeZone;
	} catch {
		return 'GMT';
	}
};
```

Use in filter hooks:

```ts
const [timezone, setTimezone] = useState(() => getUserTimezone());
```

**Rules:**

-   Detect once at component/hook mount — don't re-detect on every render
-   Always provide a fallback (`'GMT'`)
-   Timezone is a UI-only concern — don't include it in the filter state sent to the API unless the API specifically requires it

---

## 8 — Types and constants files per module

Every feature module should have a `types.ts` and `constants.ts` file for shared definitions.

```
src/components/<Module>/
├── index.ts                    # Re-exports from components/
├── types.ts                    # All TypeScript types/interfaces for this module
├── constants.ts                # All constants (dropdown options, status maps, etc.)
└── components/
    ├── Home/index.tsx
    ├── Form/index.tsx
    └── Detail/index.tsx
```

**`types.ts`:**

```ts
export interface Resource {
	id: string;
	name: string;
	status: ResourceStatus;
	createdAt: string;
}

export type ResourceStatus = 'active' | 'inactive' | 'archived';

export interface ResourceFormData {
	name: string;
	type: string;
	endpoint?: string;
}
```

**`constants.ts`:**

```ts
export const STATUS_OPTIONS = [
	{ label: 'Active', value: 'active' },
	{ label: 'Inactive', value: 'inactive' },
	{ label: 'Archived', value: 'archived' }
] as const;

export const TYPE_OPTIONS = [
	{ label: 'HTTP', value: 'HTTP' },
	{ label: 'MQTT', value: 'MQTT' },
	{ label: 'SQS', value: 'SQS' }
] as const;

export const STATUS_BADGE_MAP: Record<string, 'success' | 'error' | 'warning' | 'info'> = {
	active: 'success',
	inactive: 'error',
	pending: 'warning',
	archived: 'info'
};
```

**Rules:**

-   Types/interfaces used by multiple components go in `types.ts`
-   Static dropdown options, badge variant maps, and status enums go in `constants.ts`
-   Import from the module's own `types.ts` and `constants.ts` — never define inline
-   `STATUS_BADGE_MAP` pattern maps API values to `Badge` variant names

---

## 9 — Dynamic form fields based on selection

When a form field's value determines which other fields are visible, use `watch()` from react-hook-form inside `<Form>`.

```tsx
import { Form, FormInput, FormSelect, useFormValues } from '@decklar/ui-library';
import { SelectItem } from '@decklar/ui-library';

function FormContent() {
	const { type, authType } = useFormValues(); // watches all form values

	return (
		<>
			<FormSelect name="type" label="Type">
				<SelectItem value="HTTP">HTTP</SelectItem>
				<SelectItem value="MQTT">MQTT</SelectItem>
				<SelectItem value="SQS">SQS</SelectItem>
			</FormSelect>

			{/* Show only for HTTP */}
			{type === 'HTTP' && <FormInput name="endpoint" label="Endpoint URL" />}

			{/* Show only for SQS */}
			{type === 'SQS' && (
				<>
					<FormInput name="accessKey" label="Access Key" />
					<FormInput name="region" label="Region" />
				</>
			)}

			{/* Auth type section — show for HTTP and MQTT */}
			{(type === 'HTTP' || type === 'MQTT') && (
				<>
					<FormSelect name="authType" label="Auth Type">
						<SelectItem value="none">None</SelectItem>
						<SelectItem value="basic">Basic Auth</SelectItem>
						<SelectItem value="bearer">Bearer Token</SelectItem>
					</FormSelect>

					{authType === 'basic' && (
						<>
							<FormInput name="username" label="Username" />
							<FormInput name="password" label="Password" type="password" />
						</>
					)}
					{authType === 'bearer' && <FormInput name="token" label="Bearer Token" />}
				</>
			)}
		</>
	);
}

// Wrapper with Form
function ResourceForm({ defaultValues, onSubmit }) {
	return (
		<Form schema={resourceSchema} defaultValues={defaultValues} onSubmit={onSubmit}>
			<FormContent />
			<Button type="submit">Save</Button>
		</Form>
	);
}
```

**Rules:**

-   Use `useFormValues()` from `@decklar/ui-library` inside `<Form>` to watch all values
-   Conditional sections are rendered/unmounted based on watched values
-   Pair with conditional Zod `.refine()` — fields that are hidden should be `.optional()` in the schema

---

## 10 — Payload builder with dynamic keys

When the API requires different keys based on a form value (e.g., `imei` vs `uuid` based on alert type), build the payload in a dedicated function.

```ts
const buildPayload = (formData: FormData, accountId: string) => {
	const payload: Record<string, unknown> = {
		account_id: accountId,
		name: formData.name.trim(),
		type: formData.type
	};

	// Dynamic key based on type
	if (formData.type === 'DEVICE') {
		payload.imei = formData.identifier;
	} else {
		payload.uuid = formData.identifier;
	}

	// Conditional fields
	if (formData.type === 'HTTP') {
		payload.endpoint = formData.endpoint;
		payload.auth_type = formData.authType;
	}

	return payload;
};
```

**Rules:**

-   `buildPayload` is a pure function — no hooks, no side effects
-   Can live in the form component file or in `src/utils/`
-   Map UI field names to API field names explicitly — never pass form state directly to the API
-   Always `.trim()` string inputs

---

## 11 — URL-persisted filter state with `useUrlFilters`

`useUrlFilters` from `@roambee/client-utility` replaces the separate `useResourceFilters.ts` file when filters need to survive page refresh, browser back/forward navigation, and be shareable via URL. It manages the draft/applied split internally and writes committed state to `URLSearchParams`.

### Import

```ts
import { useUrlFilters } from '@roambee/client-utility';
import type { UrlFiltersConfig } from '@roambee/client-utility';
```

### Signature

```ts
function useUrlFilters<T extends Record<string, any>>(
	searchParams: URLSearchParams,
	setSearchParams: SetSearchParams,
	config: UrlFiltersConfig<T>
): {
	filters: T; // draft — updates as user types
	appliedFilters: T; // committed to URL — drives API queries
	page: number; // current page from URL (1-based)
	updateFilter: <K extends keyof T>(key: K, value: T[K]) => void;
	applyFilters: () => void; // push filters → URL, reset page to 1
	clearFilters: () => void; // reset to defaults, remove URL params
	setPage: (p: number) => void;
};
```

`UrlFiltersConfig<T>`:

```ts
type UrlFiltersConfig<T> = {
	defaults: T; // initial values (also used on clear)
	keys: (keyof T)[]; // which keys to read/write from URL
	pageKey?: string; // URL param name for the page number (default: 'page')
};
```

### Full example — page hook with URL-persisted filters

```ts
// src/api/hooks/useResourcePage.ts
import { useState, useCallback, useEffect } from 'react';
import { useSearchParams } from 'react-router-dom';
import { useUrlFilters } from '@roambee/client-utility';
import { useResourceList } from './useResource';

interface ResourceFilters {
	status: string;
	search: string;
	dateFrom: string; // ms timestamp string, '' = not set
	dateTo: string;
}

const DEFAULT_FILTERS: ResourceFilters = {
	status: 'all',
	search: '',
	dateFrom: '',
	dateTo: ''
};

const FILTER_KEYS: (keyof ResourceFilters)[] = ['status', 'search', 'dateFrom', 'dateTo'];

export const useResourcePage = () => {
	const [searchParams, setSearchParams] = useSearchParams();

	const { filters, appliedFilters, page, updateFilter, applyFilters, clearFilters, setPage } = useUrlFilters<ResourceFilters>(searchParams, setSearchParams, {
		defaults: DEFAULT_FILTERS,
		keys: FILTER_KEYS
	});

	// Date picker UI state — mirrors appliedFilters date strings as Date objects
	const [dateRange, setDateRangeState] = useState<{ from?: Date; to?: Date }>({
		from: appliedFilters.dateFrom ? new Date(Number(appliedFilters.dateFrom)) : undefined,
		to: appliedFilters.dateTo ? new Date(Number(appliedFilters.dateTo)) : undefined
	});

	// Sync date UI state when URL changes (back/forward)
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

	// appliedFilters drives the query — stable, no refetch on typing
	const query = useResourceList({ ...appliedFilters, page });

	return {
		filters,
		appliedFilters,
		page,
		updateFilter,
		applyFilters,
		clearFilters,
		setPage,
		dateRange,
		setDateRange,
		items: query.data ?? [],
		isLoading: query.isLoading,
		isFetching: query.isFetching,
		isError: query.isError
	};
};
```

### Handling redirect params (pre-fill filters from navigation state)

When navigating from another page with pre-set filters (e.g., "show alerts for this device"), initialize the draft but only when no URL state is already present:

```ts
export const useResourcePage = (redirectParams?: Record<string, string>) => {
	const [searchParams, setSearchParams] = useSearchParams();
	const { filters, appliedFilters, page, updateFilter, applyFilters, clearFilters, setPage } = useUrlFilters<ResourceFilters>(searchParams, setSearchParams, { defaults: DEFAULT_FILTERS, keys: FILTER_KEYS });

	// Detect existing URL state before applying redirect params
	const hasUrlState = FILTER_KEYS.some((k) => searchParams.has(String(k)));

	useEffect(() => {
		if (redirectParams && !hasUrlState) {
			if (redirectParams.status) updateFilter('status', redirectParams.status);
			if (redirectParams.search) updateFilter('search', redirectParams.search);
		}
		// eslint-disable-next-line react-hooks/exhaustive-deps
	}, []);
	// ...
};
```

### When to use `useUrlFilters` vs local `useState`

| Scenario                                         | Pattern                          |
| ------------------------------------------------ | -------------------------------- |
| Paginated table — filters should survive refresh | `useUrlFilters` in page hook     |
| Filters shareable via URL (support, deep links)  | `useUrlFilters` in page hook     |
| Browser back/forward should restore filter state | `useUrlFilters` in page hook     |
| Modal-based filter (ephemeral, never in URL)     | Local `useState` in Filters file |
| Simple list with no pagination                   | Local `useState` in Filters file |

**Rules:**

-   Always call `useUrlFilters` inside the **page hook** — never inside a component
-   `useSearchParams()` is called in the page hook and passed down to `useUrlFilters`
-   When URL filters are used, skip creating a separate `useResourceFilters.ts` file
-   Values excluded from the URL (empty string, `'all'`, `null`, `undefined`) are automatically removed from params on `applyFilters`
-   `pageKey` defaults to `'page'` — only override when multiple paginated lists share the same URL
