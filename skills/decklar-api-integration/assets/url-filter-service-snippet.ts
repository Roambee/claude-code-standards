/**
 * buildFilterQuery template — converts applied filter state to an OData query string.
 *
 * Search-replace:
 *   Resource / resource  → your entity name
 *
 * This snippet belongs in: src/api/services/resource.service.ts
 *
 * Add / remove filter predicates to match your API's supported $filter expressions.
 */

import { API } from '@decklar/client-utility';
// Import ENDPOINTS from your endpoints.ts
// import { ENDPOINTS } from '../endpoints';

// ─── Filter interface (mirrors useResourcePage.ts) ────────────────────────
interface ResourceFilters {
	search: string;
	status: string;
	account: string;
	dateFrom: string; // ms timestamp string — convert to ISO before sending if API requires it
	dateTo: string;
}

const PAGE_SIZE = 10;

// ─── Query builder ────────────────────────────────────────────────────────
// Pure function — no hooks, no side effects.
// Called from the service function below; never called from hooks or components.
export const buildFilterQuery = (filters: ResourceFilters & { page: number }): string => {
	const params = new URLSearchParams();

	// Pagination
	params.set('$size', String(PAGE_SIZE));
	params.set('$offset', String((filters.page - 1) * PAGE_SIZE));
	params.set('$orderBy', 'createdAt desc');

	// OData $filter predicates — only add non-empty values
	const parts: string[] = [];

	if (filters.status && filters.status !== 'all') parts.push(`status eq '${filters.status}'`);

	if (filters.search?.trim()) {
		// Always escape single quotes in user input
		const safe = filters.search.trim().replace(/'/g, "''");
		parts.push(`name eq '${safe}'`);
	}

	if (filters.account && filters.account !== 'all') parts.push(`accountId eq '${filters.account}'`);

	// Date filters — stored as ms timestamp strings, convert to ISO for the API
	if (filters.dateFrom) {
		const iso = new Date(Number(filters.dateFrom)).toISOString();
		parts.push(`createdAt ge '${iso}'`);
	}
	if (filters.dateTo) {
		const iso = new Date(Number(filters.dateTo)).toISOString();
		parts.push(`createdAt le '${iso}'`);
	}

	if (parts.length) params.set('$filter', parts.join(' and '));

	return params.toString();
};

// ─── Service function ─────────────────────────────────────────────────────
// Used by the base query hook (useResourceList) in src/api/hooks/useResource.ts
export const getResourceList = (filters: ResourceFilters & { page: number }) => API('GET', `/v2/resource?${buildFilterQuery(filters)}`);
// Replace /v2/resource with ENDPOINTS.RESOURCE.LIST
