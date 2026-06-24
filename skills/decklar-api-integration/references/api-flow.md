# Standard API Integration Flow

## 1) Add URL constants (endpoints.ts)

All URL strings live in one file — never write them inside hooks or components.

### API prefix conventions in this monorepo

| Prefix                                      | Used for                                                                           |
| ------------------------------------------- | ---------------------------------------------------------------------------------- |
| `/v2/`                                      | Primary business data APIs (bees, shipments, assets, webhooks, integrations, etc.) |
| `/v1/`                                      | Legacy or service-specific APIs (some assets, user-management service)             |
| `/auth/`                                    | Authentication only (`/auth/logout`)                                               |
| `/account/`, `/admin/`, `/rule/`, `/audit/` | Platform management endpoints                                                      |

For **new business data endpoints**, always use `/v2/`. Define the prefix once as `BASE_URL` so a version bump is a single edit.

```ts
// src/api/endpoints.ts
const BASE_URL = '/v2'; // used for all new business data endpoints

export const ENDPOINTS = {
	// Business data routes — always /v2/
	ITEMS: {
		LIST: `${BASE_URL}/<your-resource>`,
		DETAIL: (id: string) => `${BASE_URL}/<your-resource>/${id}`
	},

	// Auth routes — no version prefix (applies to all apps)
	AUTH: {
		LOGOUT: '/auth/logout'
	},

	// Filter / reference data — may use their own paths
	FILTER_OPTIONS: {
		STATUSES: '/filter-options/statuses',
		CATEGORIES: '/filter-options/categories'
	}
} as const;
```

**Rules:**

-   `BASE_URL` is declared once at the top — never repeat `/v2` inside individual path strings
-   Only apply `BASE_URL` to new business data routes — do NOT change existing `/auth/`, `/account/`, `/admin/`, `/rule/` routes
-   Never write a URL string directly in a hook, service, or component — always reference `ENDPOINTS`

## 2) Add cache key constants (queryKeys.ts)

```ts
// src/api/queryKeys.ts
export const queryKeys = {
	items: {
		all: ['items'] as const,
		lists: () => [...queryKeys.items.all, 'list'] as const,
		list: (filters: Record<string, unknown>) => [...queryKeys.items.lists(), filters] as const,
		detail: (id: string) => [...queryKeys.items.all, 'detail', id] as const
	}
} as const;
```

## 3) Create the service layer

Pure async functions — no React, no hooks. One file per resource.

```ts
// src/api/services/items.service.ts
// @ts-ignore
import { API, getAuthUser } from '@decklar/client-utility';
import { ENDPOINTS } from '../endpoints';

export const itemsService = {
	getList: (params?: ItemListParams) => {
		const user = getAuthUser();
		return API('GET', `${ENDPOINTS.ITEMS.LIST}?account_id=${encodeURIComponent(user.account.uuid)}`, params);
	},
	getById: (id: string) => API('GET', ENDPOINTS.ITEMS.DETAIL(id)),
	create: (data: CreateItemPayload) => API('POST', ENDPOINTS.ITEMS.LIST, data),
	update: (id: string, data: UpdateItemPayload) => API('PUT', ENDPOINTS.ITEMS.DETAIL(id), data),
	delete: (id: string) => API('DELETE', ENDPOINTS.ITEMS.DETAIL(id), {})
};
```

## 4) Use API wrapper from client-utility

```ts
// @ts-ignore
import { API, getAuthUser, EventEmitter } from '@decklar/client-utility';

// GET — always via service function, consumed by a useQuery hook
// POST / PUT / DELETE — via service function, called in useMutation
```

**Never** call `API()` directly in a component body. All calls go through service functions.

## 5) Mutations (POST / PUT / DELETE) via useMutation

Use `useMutation` — never manage loading state manually for mutations.

```ts
// src/api/hooks/useItems.ts
export const useCreateItem = () => {
	const qc = useQueryClient();
	return useMutation({
		mutationFn: itemsService.create,
		onSuccess: () => {
			qc.invalidateQueries({ queryKey: queryKeys.items.lists() });
			EventEmitter.emit('showSnackbar', { variant: 'success', message: 'Created successfully.' });
		},
		onError: (err: unknown) => {
			EventEmitter.emit('showSnackbar', { variant: 'error', message: (err as Error)?.message || 'Failed.' });
		}
	});
};
```

```tsx
// In a form component:
const createItem = useCreateItem();

const handleSave = (formData: CreateItemPayload) => {
	createItem.mutate(formData, {
		onSuccess: () => navigate('/items')
	});
};

<Button onClick={handleSave} disabled={createItem.isPending}>
	{createItem.isPending ? 'Saving...' : 'Save'}
</Button>;
```

## 6) Payload builder

Create a separate `buildPayload()` helper to map UI state → API payload. Keeps field names consistent with backend expectations and is easier to test.

```ts
// In the form file or a utils file
const buildItemPayload = (formState: ItemFormState, accountId: string): CreateItemPayload => ({
	account_id: accountId,
	name: formState.name.trim(),
	status: formState.status
	// ... map all fields explicitly
});
```

## 7) Form + loading rules

-   `useMutation` → use `isPending` for button disabled state — **never** manual `useState(false)` for mutations
-   `useQuery` → use `isLoading` / `isFetching` — **never** manual loading state for reads
-   Use `@decklar/ui-library` components (`Button`, `Input`, `Select`, `Modal`) — no raw HTML
-   On error → `EventEmitter.emit('showSnackbar', { variant: 'error', message: ... })`
-   Submit button must be `disabled={isPending}` while mutation is in flight

## 8) Navigation after success

```ts
import { useNavigate } from 'react-router-dom';
const navigate = useNavigate();

// After successful create/update — navigate to the list or detail page
navigate('/your-resource');
```

## 9) Breadcrumb pattern (required on every page)

```tsx
import { Breadcrumbs } from '@decklar/ui-library';
import type { BreadcrumbItem } from '@decklar/ui-library';

const breadcrumbs: BreadcrumbItem[] = [{ label: 'Home', onClick: () => navigate('/') }, { label: 'Your Resource', onClick: () => navigate('/your-resource') }, { label: 'Detail' }];

<Breadcrumbs items={breadcrumbs} className="mb-4" />;
```
