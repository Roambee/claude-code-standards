/**
 * URL-persisted filter page hook template — copy and adapt for each data table.
 *
 * Search-replace:
 *   Resource / resource  → your entity name (e.g. Shipment / shipment)
 *
 * Delete the "Date picker UI bridge" block if the table has no date range filter.
 * Remove dateFrom / dateTo from the interface and DEFAULT_FILTERS / FILTER_KEYS too.
 *
 * This file → src/api/hooks/useResourcePage.ts
 */

import { useState, useEffect, useCallback } from 'react';
import { useSearchParams } from 'react-router-dom';
import { useUrlFilters } from '@roambee/client-utility';
import { useResourceList } from './useResource';

// ─── 1. Filter shape ──────────────────────────────────────────────────────
interface ResourceFilters {
	search: string;
	status: string;
	account: string;
	dateFrom: string; // ms timestamp as string, '' = not set
	dateTo: string; // ms timestamp as string, '' = not set
}

const DEFAULT_FILTERS: ResourceFilters = {
	search: '',
	status: 'all',
	account: '',
	dateFrom: '',
	dateTo: ''
};

// Every key you want read from / written to the URL
const FILTER_KEYS: (keyof ResourceFilters)[] = ['search', 'status', 'account', 'dateFrom', 'dateTo'];

// ─── 2. Page hook ─────────────────────────────────────────────────────────
export const useResourcePage = () => {
	const [searchParams, setSearchParams] = useSearchParams();

	const {
		filters, // draft — what is in the input boxes right now
		appliedFilters, // committed — written to URL + passed to API
		page,
		updateFilter, // (key, value) => void — update ONE draft field
		applyFilters, // () => void — push draft → URL → triggers refetch
		clearFilters, // () => void — reset to defaults, remove URL params
		setPage // (n: number) => void
	} = useUrlFilters<ResourceFilters>(searchParams, setSearchParams, {
		defaults: DEFAULT_FILTERS,
		keys: FILTER_KEYS
	});

	// ── Date picker UI bridge ─────────────────────────────────────────────
	// Keeps a Date-object pair in sync with the ms-timestamp strings in the URL.
	// DELETE this block when no date range filter is needed.
	const [dateRange, setDateRangeState] = useState<{ from?: Date; to?: Date }>({
		from: appliedFilters.dateFrom ? new Date(Number(appliedFilters.dateFrom)) : undefined,
		to: appliedFilters.dateTo ? new Date(Number(appliedFilters.dateTo)) : undefined
	});

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
	// ─────────────────────────────────────────────────────────────────────

	// CRITICAL: pass appliedFilters to the query — never the draft `filters`
	const query = useResourceList({ ...appliedFilters, page });

	return {
		filters, // bind to input `value` props
		updateFilter, // call in `onChange` handlers
		applyFilters, // call on Apply button onClick
		clearFilters, // call on Clear button onClick
		page,
		setPage, // pass to DataTable onPageChange
		dateRange, // pass to DateRangePicker value — DELETE if no dates
		setDateRange, // pass to DateRangePicker onChange — DELETE if no dates
		items: query.data ?? [],
		isLoading: query.isLoading,
		isFetching: query.isFetching,
		isError: query.isError
	};
};
