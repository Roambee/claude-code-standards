# Navigation, Feedback & Data Components

## Table of Contents

1. [Tabs](#tabs)
2. [Pagination](#pagination)
3. [Breadcrumbs](#breadcrumbs)
4. [Sidebar](#sidebar)
5. [Timeline / ProgressIndicator](#timeline)
6. [Toast](#toast)
7. [CommentLogBox](#commentlogbox)
8. [DataTable](#datatable)

---

## Tabs

```tsx
import { Tabs, TabList, Tab, TabPanel } from '@decklar/ui-library';
```

**Tabs props:**

-   `defaultValue`: `string` — initial active tab (uncontrolled)
-   `value`: `string` — controlled active tab
-   `onValueChange`: `(value: string) => void`

**TabList props:**

-   `showAddButton`: `boolean` — shows a + button to add tabs
-   `onAddTab`: `() => void`

**Tab props:**

-   `value`: `string` (required)
-   `disabled`: `boolean`

**TabPanel props:**

-   `value`: `string` (required) — must match its Tab's value

**Examples:**

Uncontrolled:

```tsx
<Tabs defaultValue="overview">
	<TabList>
		<Tab value="overview">Overview</Tab>
		<Tab value="details">Details</Tab>
		<Tab value="settings">Settings</Tab>
	</TabList>
	<TabPanel value="overview">Overview content</TabPanel>
	<TabPanel value="details">Details content</TabPanel>
	<TabPanel value="settings">Settings content</TabPanel>
</Tabs>
```

Controlled:

```tsx
const [active, setActive] = useState('dashboard');

<Tabs value={active} onValueChange={setActive}>
	<TabList>
		<Tab value="dashboard">Dashboard</Tab>
		<Tab value="analytics">Analytics</Tab>
		<Tab value="reports" disabled>
			Reports
		</Tab>
	</TabList>
	<TabPanel value="dashboard">…</TabPanel>
	<TabPanel value="analytics">…</TabPanel>
	<TabPanel value="reports">…</TabPanel>
</Tabs>;
```

---

## Pagination

```tsx
import { Pagination } from '@decklar/ui-library';
```

**Props:**

-   `page`: `number` — current page (1-based, required)
-   `totalPages`: `number` (required)
-   `pageSize`: `number`
-   `totalResults`: `number` — for "X results" display
-   `pageSizeOptions`: `number[]` — dropdown options (default: `[10, 20, 50, 100]`)
-   `onPageChange`: `(page: number) => void`
-   `onPageSizeChange`: `(pageSize: number) => void`
-   `itemsLabel`: `string` — custom label (e.g. `"Shipments"`)
-   `showPageNumbers`: `boolean` — show numbered page buttons

**Example:**

```tsx
const [page, setPage] = useState(1);
const [pageSize, setPageSize] = useState(10);
const totalResults = 248;
const totalPages = Math.ceil(totalResults / pageSize);

<Pagination
	page={page}
	totalPages={totalPages}
	pageSize={pageSize}
	totalResults={totalResults}
	onPageChange={setPage}
	onPageSizeChange={(size) => {
		setPageSize(size);
		setPage(1);
	}}
	showPageNumbers
	itemsLabel="Shipments"
/>;
```

---

## Breadcrumbs

```tsx
import { Breadcrumbs } from '@decklar/ui-library';
import type { BreadcrumbItem } from '@decklar/ui-library';
```

**Props:**

-   `items`: `BreadcrumbItem[]` — `{ label: string; href?: string; onClick?: () => void }` — last item is the current page
-   `maxItems`: `number` — collapses intermediate items with ellipsis
-   `separator`: `string` — custom separator character (default: `"/"`)

**Examples:**

```tsx
// With hrefs
<Breadcrumbs items={[
  { label: "Home", href: "/" },
  { label: "Shipments", href: "/shipments" },
  { label: "SHP-4921" },
]} />

// With onClick (SPA navigation)
<Breadcrumbs items={[
  { label: "Home", onClick: () => router.push("/") },
  { label: "Users", onClick: () => router.push("/users") },
  { label: "John Doe" },
]} />

// Collapsed deep paths
<Breadcrumbs
  items={[{ label: "Home", href: "/" }, { label: "Supply Chain", href: "#" }, { label: "US Ops", href: "#" }, { label: "Shipments", href: "#" }, { label: "SHP-4921" }]}
  maxItems={3}
/>
```

---

## Sidebar

```tsx
import { Sidebar, SidebarSection } from '@decklar/ui-library';
import type { SidebarItem } from '@decklar/ui-library';
```

**Sidebar props:**

-   `items`: `SidebarItem[]`
-   `header`: `React.ReactNode` — logo/title area
-   `footer`: `React.ReactNode` — user info / bottom actions
-   `collapsed`: `boolean` — icon-only mode
-   `onCollapsedChange`: `(collapsed: boolean) => void`
-   `width`: `number` — expanded width in px (default: `240`)
-   `collapsedWidth`: `number` — collapsed width in px (default: `60`)

**SidebarItem shape:**

```ts
{
  id: string;
  label: string;
  icon?: React.ReactNode;       // 16×16 icon
  active?: boolean;
  onClick?: () => void;
  children?: SidebarItem[];     // nested sub-items
  badge?: React.ReactNode;      // count chip
  disabled?: boolean;
}
```

**Example:**

```tsx
const [activeId, setActiveId] = useState('dashboard');
const [collapsed, setCollapsed] = useState(false);

const items: SidebarItem[] = [
	{ id: 'dashboard', label: 'Dashboard', icon: <HomeIcon />, active: activeId === 'dashboard', onClick: () => setActiveId('dashboard') },
	{
		id: 'shipments',
		label: 'Shipments',
		icon: <BoxIcon />,
		active: activeId === 'shipments',
		onClick: () => setActiveId('shipments'),
		badge: <span className="text-xs bg-primary-100 text-primary-700 px-1.5 py-0.5 rounded-full">24</span>,
		children: [
			{ id: 'active-shipments', label: 'Active', active: activeId === 'active-shipments', onClick: () => setActiveId('active-shipments') },
			{ id: 'completed', label: 'Completed', active: activeId === 'completed', onClick: () => setActiveId('completed') }
		]
	},
	{ id: 'settings', label: 'Settings', icon: <SettingsIcon />, active: activeId === 'settings', onClick: () => setActiveId('settings') }
];

<Sidebar
	items={items}
	collapsed={collapsed}
	onCollapsedChange={setCollapsed}
	header={<span className="text-lg font-bold">{collapsed ? 'A' : 'Acme Corp'}</span>}
	footer={
		<div className="flex items-center gap-2">
			<div className="w-7 h-7 rounded-full bg-primary-500 flex items-center justify-center text-xs text-white font-semibold">JD</div>
			{!collapsed && <span className="text-sm truncate">john@acme.com</span>}
		</div>
	}
/>;
```

To group items with a section title, use `<SidebarSection title="Management">` inside the sidebar layout — or pass grouped `items` arrays with sub-sections.

---

## Timeline

```tsx
import { Timeline } from '@decklar/ui-library';
import type { TimelineStep } from '@decklar/ui-library';
```

**Props:**

-   `steps`: `TimelineStep[]` — ordered top-to-bottom (most recent first for `timeline` variant)
-   `variant`: `"timeline"` | `"forms"` (default: `"timeline"`)
-   `size`: `"sm"` | `"default"` (default: `"default"`)
-   `showNumbers`: `boolean` — show step numbers (timeline variant only)
-   `onStepClick`: `(stepId: string, index: number) => void`

**TimelineStep shape:**

```ts
{
  id: string;
  label: string;
  description?: string;
  status: "completed" | "active" | "pending";
  statusTag?: string;  // label shown between steps (timeline variant only)
}
```

**Timeline variant** (e.g. shipment tracking — newest on top):

```tsx
<Timeline
	variant="timeline"
	steps={[
		{ id: '4', label: 'Destination', description: 'Pending arrival', status: 'pending' },
		{ id: '3', label: 'In Transit', description: 'Currently moving', status: 'active' },
		{ id: '2', label: 'Departed Origin', status: 'completed', statusTag: 'Departed 09:30' },
		{ id: '1', label: 'Picked Up', status: 'completed' }
	]}
	showNumbers
/>
```

**Forms variant** (multi-step form navigation):

```tsx
const [activeStep, setActiveStep] = useState('step1');

<Timeline
	variant="forms"
	steps={[
		{ id: 'step1', label: 'Basic Info', status: 'active' },
		{ id: 'step2', label: 'Contact Details', status: 'pending' },
		{ id: 'step3', label: 'Review', status: 'pending' }
	]}
	onStepClick={(id) => setActiveStep(id)}
/>;
```

---

## Toast

```tsx
import { Toast, ToastProvider, ToastContainer, useToast } from '@decklar/ui-library';
```

### Programmatic API (preferred)

Wrap your app (or a subtree) in `<ToastProvider>`, then use the `useToast` hook:

**ToastProvider props:**

-   `position`: `"top-right"` | `"top-center"` | `"top-left"` | `"bottom-right"` | `"bottom-center"` | `"bottom-left"` (default: `"bottom-right"`)
-   `maxToasts`: `number` (default: `5`)

**useToast hook:**

-   `toast(message, options?)` — show a toast, returns its `id`
-   `dismiss(id)` — dismiss a specific toast
-   `dismissAll()` — dismiss all toasts

**ToastOptions:**

-   `variant`: `"default"` | `"success"` | `"warning"` | `"error"` (default: `"default"`)
-   `duration`: `number` — auto-dismiss in ms (default: `5000`, set `0` to disable)

```tsx
// 1. Wrap once near app root
<ToastProvider position="bottom-right" maxToasts={5}>
  <App />
</ToastProvider>

// 2. Use anywhere inside the provider
function SaveButton() {
  const { toast } = useToast();

  const handleSave = async () => {
    try {
      await saveData();
      toast('Shipment saved successfully.', { variant: 'success' });
    } catch {
      toast('Something went wrong.', { variant: 'error', duration: 0 });
    }
  };

  return <Button onClick={handleSave}>Save</Button>;
}
```

### Display-only Toast (manual state)

**Toast props:**

-   `message`: `string` (required)
-   `variant`: `"default"` | `"success"` | `"warning"` | `"error"` (default: `"default"`)
-   `onClose`: `() => void`

```tsx
const [visible, setVisible] = useState(false);

<Button onClick={() => setVisible(true)}>Show notification</Button>;

{
	visible && <Toast variant="success" message="Shipment saved successfully." onClose={() => setVisible(false)} />;
}
```

---

## CommentLogBox

```tsx
import { CommentLogBox } from '@decklar/ui-library';
import type { CommentEntry, HistoryEntry } from '@decklar/ui-library';
```

Tabbed panel with **Comments** and **History** tabs. Users can add new comments.

**Props:**

-   `comments`: `CommentEntry[]` — `{ id: string; author: string; timestamp: string; message: string }`
-   `history`: `HistoryEntry[]` — `{ id: string; author: string; timestamp: string; message: string }`
-   `onAddComment`: `(message: string) => void`
-   `tab`: `"comments"` | `"history"` — controlled active tab
-   `defaultTab`: `"comments"` | `"history"` (default: `"comments"`)
-   `onTabChange`: `(tab: "comments" | "history") => void`
-   `addCommentPlaceholder`: `string` (default: `"Add a comment"`)

```tsx
<CommentLogBox
  comments={[
    { id: '1', author: 'Jane Doe', timestamp: '12.02.2024 / 12:45', message: 'Shipment delayed at origin.' },
    { id: '2', author: 'John Smith', timestamp: '12.02.2024 / 14:30', message: 'Updated ETA to Friday.' },
  ]}
  history={[
    { id: 'h1', author: 'System', timestamp: '11.02.2024 / 09:00', message: 'Status changed to In Transit.' },
  ]}
  onAddComment={(message) => console.log('New comment:', message)}
  defaultTab="comments"
/>
```

---

## DataTable

```tsx
import { DataTable, useDataTableApi } from '@decklar/ui-library';
import type { DataTableProps, TableActionMenuItem } from '@decklar/ui-library';
import type { ColumnDef, Row } from '@tanstack/react-table';
```

DataTable wraps TanStack Table with Decklar styling, built-in sorting, pagination, selection, and row actions.

> **Mandatory:** Always pass `showPageNumbers` on every `DataTable`. This is required so users can see page numbers in the pagination bar.

> **Mandatory:** Always pass `enableColumnResizing` on every `DataTable`. This is required so users can drag column borders to resize columns.

**Key props:**

-   `columns`: `ColumnDef<TData>[]` — TanStack column definitions
-   `data`: `TData[]`
-   `getRowId`: `(row: TData) => string` — stable row key (use when data has an id)
-   `enableColumnResizing`: `boolean` (default: `false`)
-   `columnResizeMode`: `'onChange'` | `'onEnd'` (default: `'onChange'`)
-   `columnResizingTableId`: `string` — when provided, column widths are persisted to localStorage
-   `enableSorting`: `boolean` (default: `true`)
-   `enableRowSelection`: `boolean` (default: `false`)
-   `enablePagination`: `boolean` (default: `true`)
-   `initialPageSize`: `number` (default: `10`)
-   `getRowActions`: `(row: Row<TData>) => TableActionMenuItem[] | null` — row action menu
-   `onRowClick`: `(row: Row<TData>) => void`
-   `isLoading`: `boolean`
-   `emptyMessage`: `ReactNode`
-   `size`: `"default"` | `"compact"`
-   `maxHeight`: `number | string` — enables vertical scroll with sticky header
-   `showPageNumbers`: `boolean`
-   `rowCount`: `number` — for server-side pagination total

**Server-side pagination props:**

-   `rowCount`, `sorting`, `onSortingChange`, `pagination`, `onPaginationChange`

**Basic example:**

```tsx
type Shipment = { id: string; name: string; status: string; date: string };

const columns: ColumnDef<Shipment>[] = [
	{ accessorKey: 'name', header: 'Shipment Name' },
	{ accessorKey: 'status', header: 'Status', cell: ({ getValue }) => <Badge variant="info">{getValue() as string}</Badge> },
	{ accessorKey: 'date', header: 'Date' }
];

<DataTable
	columns={columns}
	data={shipments}
	getRowId={(row) => row.id}
	enableRowSelection
	enableColumnResizing
	showPageNumbers
	initialPageSize={20}
	getRowActions={(row) => [
		{ id: 'view', label: 'View', icon: <Eye size={14} />, onClick: () => openDetail(row.original) },
		{ id: 'delete', label: 'Delete', icon: <Trash2 size={14} />, variant: 'destructive', onClick: () => deleteItem(row.original.id) }
	]}
	onRowClick={(row) => openDetail(row.original)}
/>;
```

**`useDataTableApi`** — hook for server-side data fetching that syncs with table state:

```tsx
const { data, isLoading, rowCount } = useDataTableApi({
	queryFn: ({ page, pageSize, sorting }) => fetchShipments({ page, pageSize, sorting }),
	initialPageSize: 20
});

<DataTable columns={columns} data={data} rowCount={rowCount} isLoading={isLoading} {...data.tableProps} />;
```

**`useColumnSizingPersistence`** — hook to persist column widths to localStorage (300ms debounce):

```tsx
import { useColumnSizingPersistence } from '@decklar/ui-library';

const { columnSizing, onColumnSizingChange, resetColumnSizing } = useColumnSizingPersistence('my-table-id');

<DataTable
  columns={columns}
  data={data}
  enableColumnResizing
  showPageNumbers
  state={{ columnSizing }}
  onColumnSizingChange={onColumnSizingChange}
/>;
```

Pass `undefined` as the table ID to disable persistence. Use `resetColumnSizing()` to clear saved widths.
