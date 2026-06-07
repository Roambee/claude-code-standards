---
name: decklar-ui-library
description: 'Use when building UI components in this project. @decklar/ui-library is the custom component library. Use this skill whenever creating or editing React components that need buttons, inputs, selects, forms, modals, tooltips, tabs, pagination, tables, badges, cards, tags, or any other UI element — always prefer @decklar/ui-library over native HTML elements or other libraries. Never use raw button, input, select, dialog, textarea, or label elements when a Decklar component exists.'
---

# @decklar/ui-library

Custom Decklar component library. Always import from `@decklar/ui-library`.

## Setup

This project is a **Vite** app. Styles are imported once in the entry file (`src/demo.tsx`):

```tsx
import '@decklar/ui-library/styles';
```

## Component Categories

| Category                    | Components                                                                                                                                                                                                     |
| --------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Core**                    | `Button`, `Badge`, `Card` (+sub-parts), `Tag`                                                                                                                                                                  |
| **Forms (standalone)**      | `Input`, `Textarea`, `Label`, `Checkbox`, `Switch`, `Slider`, `RadioButton` / `RadioButtonItem`, `Select` (+sub-parts), `MultiSelect`, `DatePicker`, `DateRangePicker`, `Calendar`, `FileUpload`, `DraggableList` |
| **Forms (react-hook-form)** | `Form`, `FormInput`, `FormTextarea`, `FormSelect`, `FormMultiSelect`, `FormCheckbox`, `FormSwitch`, `FormRadioGroup`, `FormSlider`, `FormDatePicker`, `FormDateRangePicker`, `FormFileUpload`, `useFormValues` |
| **Overlay**                 | `Modal`, `Tooltip`, `TooltipProvider`                                                                                                                                                                          |
| **Navigation**              | `Tabs` / `TabList` / `Tab` / `TabPanel`, `Pagination`, `Breadcrumbs`, `Sidebar` / `SidebarSection`, `Timeline`, `ProgressIndicator`, `GlobalSearchHeader` / `AppHeader`                                        |
| **Feedback**                | `Toast`, `ToastProvider`, `ToastContainer`, `useToast`, `CommentLogBox`                                                                                                                                        |
| **Data**                    | `DataTable`, `useDataTableApi`, `useColumnSizingPersistence`                                                                                                                                                   |
| **Charts**                  | `Chart` (bar, line, area, ring, pie, radar, funnel, scatter, composed, themeriver, listcard)                                                                                                                   |
| **Maps**                    | `Map`, `MapCore`, `ArcLayer`, `GeoJsonLayer`, `IconLayer`, `LineLayer`, `PathLayer`, `PolygonLayer`, `ScatterplotLayer`, `TextLayer`, `useMapLibreCluster`, `useRouteAnimation`, `useAlertSimulation`          |

## Reference Files

Load the relevant reference file when implementing a component:

-   **Core components** (Button, Badge, Card, Tag) → [references/core-components.md](references/core-components.md)
-   **Form components** (inputs, selects, checkboxes, etc.) → [references/form-components.md](references/form-components.md)
-   **Overlay components** (Modal, Tooltip) → [references/overlay-components.md](references/overlay-components.md)
-   **Navigation & feedback & data** (Tabs, Pagination, Sidebar, Toast, DataTable…) → [references/navigation-feedback-data.md](references/navigation-feedback-data.md)
-   **Charts & Maps** (Chart, Map, MapCore, layers…) → [references/chart-map-components.md](references/chart-map-components.md)
-   **Header integration** (GlobalSearchHeader, useGlobalSearchHeader) → see **decklar-header-integration** skill

## Starter Templates

When creating a new page or component, copy and adapt the relevant template from `assets/`:

-   **Basic page** → [assets/page-template.tsx](assets/page-template.tsx) — layout scaffold with header + action button
-   **Form page** → [assets/form-page-template.tsx](assets/form-page-template.tsx) — Form + Zod schema + submit handler
-   **Data table page** → [assets/data-table-page-template.tsx](assets/data-table-page-template.tsx) — Breadcrumbs + **page header (title + Export/Add)** + **filter row** (search + `Select` with `SelectTrigger` width) + DataTable + row actions. Matches **Page layout: data-table pages** below.

## ⚠️ Known Issues & Confirmed Bugs

These are **confirmed build errors** in this project's version of `@decklar/ui-library`. Always apply the fix — never use the broken pattern.

### 1 — `Tag` is NOT exported

`Tag` does not exist as a standalone export. Importing it causes a build error.

```tsx
// ❌ BUILD ERROR
import { Tag } from '@decklar/ui-library';

// ✅ USE Badge INSTEAD — 5 variants: primary | success | warning | error | info
import { Badge } from '@decklar/ui-library';
<Badge variant="primary">express</Badge>
<Badge variant="success">Active</Badge>
```

`CardTag` exists but **only works inside `<Card>`**. For standalone chips/pills/tags in tables or anywhere else, always use `Badge`.

---

### 2 — `z.enum()`, `z.literal()`, `z.union()` all fail (`TS2554: Expected 0 arguments`)

The installed Zod v4 build has broken TypeScript signatures for these three functions. **Always use `z.string()` for select/enum fields** and type-cast the value in the submit handler.

```tsx
// ❌ BROKEN — TS2554 error on all three
z.enum(['active', 'draft']);
z.literal('air');
z.union([z.literal('a'), z.literal('b')]);

// ✅ CORRECT PATTERN
type Status = 'active' | 'draft' | 'archived';

const schema = z.object({
	status: z.string().min(1, 'Status is required') // ← z.string()
});

function handleSubmit(values: z.infer<typeof schema>) {
	const status = values.status as Status; // ← cast here
}
```

**Safe Zod APIs** (always work): `z.string()`, `z.boolean()`, `z.date()`, `z.number()`, `z.array()`, `.min()`, `.max()`, `.email()`, `.optional()`, `.refine()`.

---

### 3 — `FormDatePicker` has no `label` prop

```tsx
// ❌ TS ERROR — label prop does not exist
<FormDatePicker name="date" label="Pick a date" />;

// ✅ USE Label manually above it
import { Label } from '@decklar/ui-library';

<div style={{ display: 'flex', flexDirection: 'column', gap: '6px' }}>
	<Label>Pick a date</Label>
	<FormDatePicker name="date" placeholder="Select date" />
</div>;
```

All other `Form*` components (`FormInput`, `FormSelect`, `FormTextarea`, `FormMultiSelect`, `FormSwitch`, `FormCheckbox`) accept `label` normally.

---

### 4 — Always import Zod from `'zod'`, never `'zod/v3'`

```tsx
// ❌ WRONG — zod/v3 types are incompatible with the Form component
import { z } from 'zod/v3';

// ✅ CORRECT
import { z } from 'zod';
```

---

## Page layout: data-table pages (toolbars & primary actions)

Micro-frontend content areas are often **narrow**. These patterns avoid **invisible primary actions** and **inconsistent Select** styling (validated on data-table pages across multiple apps).

### Do not put primary CTAs only at the end of one nowrap row

A single toolbar row with **search + many filters + Export + Add** using `flex-wrap: nowrap` and horizontal overflow **pushes Export / Add off-screen** on typical widths. Users only see search and filters.

**Preferred pattern** (all apps, e.g. any data-table page):

1. **Page header row:** `display: flex; justify-content: space-between; align-items: center; gap: 1rem` — **title left**, **primary actions right** (Export, Add, Refresh, etc.). Use `flex-shrink: 0` on the actions group so buttons never compress away.
2. **Filter row below:** search + filter `Select`s with **gap** and **`flex-wrap: wrap`** so filters wrap on small widths instead of hiding actions.

If the product spec truly requires **one** horizontal row for everything, document that trade-off; otherwise default to header + filter row.

### `SelectTrigger` width on toolbar filters

Set an **explicit width** on **`SelectTrigger`** for every toolbar filter (e.g. Tailwind `className="w-40"` or `w-44"`). Without it, adjacent selects can render **inconsistently** (one with full chevron/border, one looking borderless or clipped).

### Search field in the filter row

Use a **flexible** search wrapper (e.g. `flex: 1; max-width: 320px; min-width: 180px`) with icon **`absolute left-3 top-1/2 -translate-y-1/2`** and **`Input` with `pl-9`**. Avoid a fixed wide search box that steals space from filters on narrow layouts.

**See also:** [assets/data-table-page-template.tsx](assets/data-table-page-template.tsx) — header + actions + filter row + table.

### Compact multi-filter layouts (many filters on one page)

Use **CSS grid with inline styles** for filter rows — NOT flex-wrap. Grid guarantees every column is the same height and all controls align perfectly.

#### Filter control sizing — ALWAYS apply to every control

| Control                      | Required className                           |
| ---------------------------- | -------------------------------------------- |
| `Input`                      | `className="w-full h-9 text-sm"`             |
| `SelectTrigger`              | `className="w-full h-9 text-sm"`             |
| `DatePicker`                 | `className="w-full h-9 text-sm"`             |
| `DateRangePicker`            | `className="w-full h-9 text-sm"`             |
| `Label` (above every filter) | `className="mb-1 block text-xs font-medium"` |

`h-9` (36px) is the canonical filter control height. **All controls in a filter row must use `h-9 text-sm`** — without it, date pickers and inputs render at different heights.

#### Two-row pattern (7+ filters across two rows)

**Row 1 — equal columns:**

```tsx
<div style={{ display: 'grid', gridTemplateColumns: 'repeat(6, minmax(0, 1fr))', gap: '12px', marginBottom: '12px' }}>
  <div>
    <Label className="mb-1 block text-xs font-medium">Field</Label>
    <Input className="w-full h-9 text-sm" placeholder="..." />
  </div>
  <div>
    <Label className="mb-1 block text-xs font-medium">Status</Label>
    <Select ...>
      <SelectTrigger className="w-full h-9 text-sm"><SelectValue /></SelectTrigger>
      <SelectContent position="popper" className="z-[9999]">...</SelectContent>
    </Select>
  </div>
  {/* repeat — no buttons in row 1 */}
</div>
```

**Row 2 — proportional columns + buttons inline:**

```tsx
{/* Use fr units to size columns proportionally: wide ones get 2fr, narrow get 1fr, buttons get auto */}
<div style={{ display: 'grid', gridTemplateColumns: '2fr 1fr 2fr 1fr auto', gap: '12px', marginBottom: '16px', alignItems: 'end' }}>
  <div>
    <Label className="mb-1 block text-xs font-medium">Date Range</Label>
    <DateRangePicker className="w-full h-9 text-sm" showPresets presets={['thisWeek','lastWeek','thisMonth','lastMonth']} onChange={...} />
  </div>
  <div>
    <Label className="mb-1 block text-xs font-medium">UUID / IMEI</Label>
    <Input className="w-full h-9 text-sm" placeholder="Enter UUID or IMEI" />
  </div>
  <div>
    <Label className="mb-1 block text-xs font-medium">Timezone</Label>
    <Select ...>
      <SelectTrigger className="w-full h-9 text-sm"><SelectValue /></SelectTrigger>
      <SelectContent position="popper" className="z-[9999]">...</SelectContent>
    </Select>
  </div>
  <div>
    <Label className="mb-1 block text-xs font-medium">Type</Label>
    <Select ...>
      <SelectTrigger className="w-full h-9 text-sm"><SelectValue /></SelectTrigger>
      <SelectContent position="popper" className="z-[9999]">...</SelectContent>
    </Select>
  </div>
  {/* buttons in the auto column, aligned to bottom via alignItems: 'end' on the grid */}
  <div style={{ display: 'flex', gap: '8px', alignItems: 'flex-end' }}>
    <Button variant="outline" size="sm">Clear</Button>
    <Button variant="primary" size="sm">Search</Button>
  </div>
</div>
```

#### Single-row pattern (5 or fewer filters)

```tsx
{/* All filters + buttons in one row; last column is auto for the button group */}
<div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr 1fr 1fr auto', gap: '12px', marginBottom: '16px', alignItems: 'end' }}>
  <div>
    <Label className="mb-1 block text-xs font-medium">Alert Type <span className="text-red-500">*</span></Label>
    <Select ...>
      <SelectTrigger className="w-full h-9 text-sm"><SelectValue /></SelectTrigger>
      <SelectContent position="popper" className="z-[9999]">...</SelectContent>
    </Select>
  </div>
  <div>
    <Label className="mb-1 block text-xs font-medium">UUID / IMEI</Label>
    <Input className="w-full h-9 text-sm" placeholder="Enter UUID or IMEI" />
  </div>
  <div>
    <Label className="mb-1 block text-xs font-medium">Start Date</Label>
    <DatePicker className="w-full h-9 text-sm" placeholder="Select start date" showTime onChange={...} />
  </div>
  <div>
    <Label className="mb-1 block text-xs font-medium">End Date</Label>
    <DatePicker className="w-full h-9 text-sm" placeholder="Select end date" showTime onChange={...} />
  </div>
  <div>
    <Label className="mb-1 block text-xs font-medium">Category</Label>
    <Select ...>
      <SelectTrigger className="w-full h-9 text-sm"><SelectValue /></SelectTrigger>
      <SelectContent position="popper" className="z-[9999]">...</SelectContent>
    </Select>
  </div>
  <div style={{ display: 'flex', gap: '8px', alignItems: 'flex-end' }}>
    <Button variant="outline" size="sm">Clear</Button>
    <Button variant="primary" size="sm">Search</Button>
  </div>
</div>
```

**Rules:**

-   **Always use CSS grid (`display: 'grid'`) with inline styles** — never `flex-wrap` for filter bars
-   **Always `h-9 text-sm`** on every `Input`, `SelectTrigger`, `DatePicker`, `DateRangePicker` in a filter row — this is the only way to guarantee uniform height
-   **`alignItems: 'end'`** on the grid container so labels + controls align and buttons sit at the bottom
-   **Button column is always `auto`** — it sizes to the content and doesn't stretch
-   Use **`fr` units** for proportional sizing: `2fr` for wide fields (Date Range, Timezone), `1fr` for narrow fields
-   Use `text-xs` labels (`mb-1 block text-xs font-medium`) — never `text-sm` labels in filter rows
-   Never put action buttons in a separate row below — always inline in the last `auto` column
-   Don't wrap each filter col in `<div className="space-y-1">` — use `mb-1` on the Label only

### SelectContent — required props in filter bars

The default `position="item-aligned"` (Radix UI default) aligns the dropdown so the **selected option sits at the same level as the trigger**. In horizontal filter bars this causes dropdowns to appear **overlapping adjacent triggers**. Always use `position="popper"` to ensure the dropdown opens **below** the trigger like a standard dropdown.

Also always add `className="z-[9999]"` to prevent the open dropdown list from appearing behind other elements in micro-frontend / scroll containers.

```tsx
// ✅ ALWAYS — both props required in filter bars
<SelectContent position="popper" className="z-[9999]">
  ...
</SelectContent>

// ❌ NEVER — item-aligned causes visible overlap in horizontal filter rows
<SelectContent>
  ...
</SelectContent>
```

---

## Key Rules

1. **Never use raw HTML** for UI primitives — no `<button>`, `<input>`, `<select>`, `<dialog>`, `<textarea>`, `<label>` when a Decklar equivalent exists.
2. **Use `Form` + `Form*` wrappers** (not standalone fields) when building forms that need validation — they integrate with react-hook-form + Zod internally.
3. **Wrap Tooltip children** in `<TooltipProvider>` once near the tree root.
4. **Card sub-components** (`CardContent`, `CardTitle`, `CardDescription`, `CardLabel`, `CardTags`, `CardTag`) must always be used inside `<Card>`.
5. **Every `DataTable` MUST include `showPageNumbers`** — always pass `showPageNumbers` so users can see page numbers in the pagination bar. This is mandatory for all tables across every app.
6. **Every `DataTable` MUST include `enableColumnResizing`** — always pass `enableColumnResizing` so users can drag column borders to resize. This is mandatory for all tables across every app.
7. **Every page MUST include `Breadcrumbs`** — all pages in every app must render a `<Breadcrumbs>` component at the top of the page content, showing the navigation path (e.g., Home > Section > Current Page). Import `Breadcrumbs` and `BreadcrumbItem` from `@decklar/ui-library`. Use `onClick` handlers with `useNavigate()` for SPA navigation. The last item (current page) has no `onClick`/`href`.
8. **`Tag` does not exist** — use `Badge` for all standalone chips/pills. See Known Issues above.
9. **Never use `z.enum()`, `z.literal()`, or `z.union()`** — use `z.string()` with a type cast instead. See Known Issues above.
10. **`FormDatePicker` has no `label` prop** — wrap it with a manual `<Label>` component. See Known Issues above.
11. **Required field indicator** — pass **`required`** on `FormInput`, `FormSelect`, and `FormMultiSelect` so the library shows the red **`*`** on the label. Zod does not enable this automatically.
12. **Table pages: primary actions in the page header** — put Export / Add (and similar CTAs) on the **same row as the page title** (title left, actions right). Do not rely on a single nowrap toolbar row that scrolls actions off-screen in narrow micro-frontend layouts.
13. **Toolbar `SelectTrigger` width** — every filter `Select` in a toolbar must use an explicit width on `SelectTrigger` (e.g. `className="w-40"` or `w-44"`).
14. **Filter toolbar** — use `flex-wrap: wrap` and consistent gap for the search + filters row so layout degrades gracefully on narrow viewports.
15. **Compact filter layout** — when a page has 7+ filters, use a `grid grid-cols-N gap-3` first row + `flex items-end gap-3` second row with buttons inline. For 5 or fewer filters, use a single `flex items-end gap-3 flex-wrap` row with buttons at the end. Use `gap-3` (not `gap-6`) and `text-xs` labels.
16. **SelectContent position + z-index** — always add `position="popper" className="z-[9999]"` to every `SelectContent` in filter bars. The default `item-aligned` mode causes dropdowns to overlap adjacent triggers in horizontal layouts.
