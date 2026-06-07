/**
 * Full resource API integration template — copy and adapt for each new resource.
 *
 * Search-replace:
 *   Resource / resource / RESOURCE  → your entity name (e.g. Shipment / shipment / SHIPMENT)
 *   /v2/<your-resource>             → actual API path
 *
 * Files to create per resource:
 *   src/api/endpoints.ts                    ← add RESOURCE block
 *   src/api/queryKeys.ts                     ← add resource block
 *   src/api/services/resource.service.ts     ← new file
 *   src/api/hooks/useResource.ts             ← new file
 *   src/api/hooks/useResourcePage.ts         ← new file (one per page)
 */

// ─── 1. ENDPOINTS (add to src/api/endpoints.ts) ───────────────────────────
// New business data endpoints use /v2/ — define BASE_URL once.
// Auth (/auth/), account/admin/rule/audit routes keep their own prefix as-is.
const BASE_URL = '/v2';

export const ENDPOINTS = {
	// Business data resource — always /v2/
	RESOURCE: {
		LIST: `${BASE_URL}/<your-resource>`,
		DETAIL: (id: string) => `${BASE_URL}/<your-resource>/${id}`
	},
	// Auth — no version prefix
	AUTH: {
		LOGOUT: '/auth/logout'
	},
	// Filter/reference data — may use their own paths
	FILTER_OPTIONS: {
		STATUSES: '/filter-options/statuses'
	}
} as const;

// ─── 2. QUERY KEYS (add to src/api/queryKeys.ts) ─────────────────────────
export const queryKeys = {
	resource: {
		all: ['resource'] as const,
		lists: () => [...queryKeys.resource.all, 'list'] as const,
		list: (filters: Record<string, unknown>) => [...queryKeys.resource.lists(), filters] as const,
		details: () => [...queryKeys.resource.all, 'detail'] as const,
		detail: (id: string) => [...queryKeys.resource.details(), id] as const
	},
	filterOptions: {
		all: ['filter-options'] as const,
		statuses: () => [...queryKeys.filterOptions.all, 'statuses'] as const
	}
} as const;

// ─── 3. SERVICE (src/api/services/resource.service.ts) ────────────────────
// @ts-ignore
import { API, getAuthUser } from '@roambee/client-utility';
// Replace ResourceType / CreateResourcePayload / UpdateResourcePayload with your real types
type ResourceType = Record<string, unknown>;
type CreateResourcePayload = Record<string, unknown>;
type UpdateResourcePayload = Record<string, unknown>;

export interface ResourceListParams {
	page?: number;
	limit?: number;
	search?: string;
	status?: string;
	[key: string]: unknown; // required for queryKeys factory (Record<string, unknown>)
}

export const resourceService = {
	getList: (params?: ResourceListParams): Promise<ResourceType[]> => {
		const user = getAuthUser();
		if (!user?.account?.uuid) return Promise.resolve([]);
		return API('GET', `${ENDPOINTS.RESOURCE.LIST}?account_id=${encodeURIComponent(user.account.uuid)}`, params);
	},

	getById: (id: string): Promise<ResourceType> => API('GET', ENDPOINTS.RESOURCE.DETAIL(id)),

	create: (data: CreateResourcePayload): Promise<ResourceType> => API('POST', ENDPOINTS.RESOURCE.LIST, data),

	update: (id: string, data: UpdateResourcePayload): Promise<ResourceType> => API('PUT', ENDPOINTS.RESOURCE.DETAIL(id), data),

	delete: (id: string): Promise<void> => API('DELETE', ENDPOINTS.RESOURCE.DETAIL(id), {})
};

// ─── 4. BASE QUERY HOOKS (src/api/hooks/useResource.ts) ─────────────────
import { useQuery, useMutation, useQueryClient, keepPreviousData, type UseQueryOptions } from '@tanstack/react-query';
// @ts-ignore
import { EventEmitter } from '@roambee/client-utility';

// List — accepts select for per-page transforms without splitting the cache
export const useResourceList = <TData = ResourceType[]>(params?: ResourceListParams, options?: Omit<UseQueryOptions<ResourceType[], Error, TData>, 'queryKey' | 'queryFn'>) =>
	useQuery({
		queryKey: queryKeys.resource.list(params ?? {}),
		queryFn: () => resourceService.getList(params),
		placeholderData: keepPreviousData, // no blank flash on filter change
		...options
	});

// Single detail — disabled until id is provided
export const useResource = (id: string) =>
	useQuery({
		queryKey: queryKeys.resource.detail(id),
		queryFn: () => resourceService.getById(id),
		enabled: !!id
	});

// CREATE
export const useCreateResource = () => {
	const qc = useQueryClient();
	return useMutation({
		mutationFn: resourceService.create,
		onSuccess: () => {
			qc.invalidateQueries({ queryKey: queryKeys.resource.lists() });
			EventEmitter.emit('showSnackbar', { variant: 'success', message: 'Created successfully.' });
		},
		onError: (err: unknown) => {
			EventEmitter.emit('showSnackbar', { variant: 'error', message: (err as Error)?.message || 'Create failed.' });
		}
	});
};

// UPDATE
export const useUpdateResource = () => {
	const qc = useQueryClient();
	return useMutation({
		mutationFn: ({ id, data }: { id: string; data: UpdateResourcePayload }) => resourceService.update(id, data),
		onSuccess: (updated) => {
			qc.setQueryData(queryKeys.resource.detail(String((updated as any).id)), updated); // instant cache write
			qc.invalidateQueries({ queryKey: queryKeys.resource.lists() });
			EventEmitter.emit('showSnackbar', { variant: 'success', message: 'Updated successfully.' });
		},
		onError: (err: unknown) => {
			EventEmitter.emit('showSnackbar', { variant: 'error', message: (err as Error)?.message || 'Update failed.' });
		}
	});
};

// DELETE
export const useDeleteResource = () => {
	const qc = useQueryClient();
	return useMutation({
		mutationFn: resourceService.delete,
		onSuccess: (_, deletedId) => {
			qc.removeQueries({ queryKey: queryKeys.resource.detail(deletedId) });
			qc.invalidateQueries({ queryKey: queryKeys.resource.lists() });
			EventEmitter.emit('showSnackbar', { variant: 'success', message: 'Deleted successfully.' });
		},
		onError: (err: unknown) => {
			EventEmitter.emit('showSnackbar', { variant: 'error', message: (err as Error)?.message || 'Delete failed.' });
		}
	});
};

// ─── 5. PAGE-LEVEL COMPOSED HOOK (src/api/hooks/useResourcePage.ts) ──────
// One hook per page. Components call ONLY this — zero API logic in the component.
import { useState, useCallback } from 'react';

interface ResourceFilters {
	search: string;
	status: string;
	page: number;
	limit: number;
	[key: string]: unknown; // required for queryKeys factory (Record<string, unknown>)
}

const DEFAULT_FILTERS: ResourceFilters = { search: '', status: 'all', page: 1, limit: 20 };

export const useResourcePage = () => {
	// Applied-filters pattern: draft ← UI state, applied ← what the query uses
	const [draftFilters, setDraftFilters] = useState<ResourceFilters>(DEFAULT_FILTERS);
	const [appliedFilters, setAppliedFilters] = useState<ResourceFilters>(DEFAULT_FILTERS);

	const listQuery = useResourceList(appliedFilters);

	const updateDraft = useCallback(
		<K extends keyof ResourceFilters>(key: K, value: ResourceFilters[K]) =>
			setDraftFilters((prev) => ({
				...prev,
				[key]: value,
				...(key !== 'page' ? { page: 1 } : {}) // reset page on any filter change
			})),
		[]
	);

	const applyFilters = useCallback(() => setAppliedFilters({ ...draftFilters, page: 1 }), [draftFilters]);

	const resetFilters = useCallback(() => {
		setDraftFilters(DEFAULT_FILTERS);
		setAppliedFilters(DEFAULT_FILTERS);
	}, []);

	return {
		draftFilters,
		updateDraft,
		applyFilters,
		resetFilters,
		items: listQuery.data ?? [],
		isLoading: listQuery.isLoading, // full-page skeleton — first load only
		isFetching: listQuery.isFetching, // inline overlay — background refetches
		isError: listQuery.isError,
		error: listQuery.error
	};
};
