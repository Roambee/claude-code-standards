# Filter Section Layout Pattern

**Always use CSS grid** — never `flex-wrap` with hardcoded `w-XX` widths.  
`flex-wrap` packs items to the left at only their explicit pixel width; items look cramped and uneven.  
CSS `grid` auto-distributes all available width evenly so every field gets an equal column.

## Rules

-   Use `grid grid-cols-N gap-6` on the filter container (N = number of fields per row)
-   Drop ALL explicit `w-XX` wrapper divs — grid columns handle sizing
-   `SelectTrigger` and `DatePicker`/`DateRangePicker` need no width class (they fill the grid cell)
-   Put action buttons (Clear / Apply / Search) in a **separate** `<div className="flex gap-2">` below the grid
-   All `Label` components must have `font-medium` to match `Input`'s built-in bold label
-   No `border` card wrapper around filters — keep the page clean and open

## Example — 4-column filter (Events / Audit page style)

```tsx
{/* Row 1: 4 dropdowns */}
<div className="grid grid-cols-4 gap-6 mb-3">
	<div>
		<Label className="mb-1 block text-sm font-medium">Alert Type</Label>
		<Select value={alertType} onValueChange={setAlertType}>
			<SelectTrigger className="w-full"><SelectValue /></SelectTrigger>
			<SelectContent>...</SelectContent>
		</Select>
	</div>
	{/* repeat for other dropdowns */}
</div>

{/* Row 2: text inputs + date range */}
<div className="grid grid-cols-4 gap-6 mb-2">
	<Input label="HTTP Code" placeholder="e.g. 200" value={httpCode} onChange={...} />
	<Input label="Resource Name" placeholder="Search name" value={resourceName} onChange={...} />
	<Input label="UUID / IMEI" placeholder="Enter UUID or IMEI" value={uuidImei} onChange={...} />
	<div>
		<Label className="mb-1 block text-sm font-medium">Date Range</Label>
		<DateRangePicker showPresets onChange={...} />
	</div>
</div>

{/* Buttons — always separate from grid */}
<div className="flex gap-2 justify-end mb-4">
	<Button variant="outline" size="sm" onClick={handleClear}>Clear</Button>
	<Button variant="primary" size="sm" onClick={handleApply}>Apply</Button>
</div>
```

## Example — 5-column single-row filter (Action / Resend page style)

```tsx
<div className="grid grid-cols-5 gap-6 mb-2">
	<div>
		<Label className="mb-1 block text-sm font-medium">Alert Type *</Label>
		<Select value={alertType} onValueChange={setAlertType}>
			<SelectTrigger className="w-full"><SelectValue placeholder="Select type" /></SelectTrigger>
			<SelectContent>...</SelectContent>
		</Select>
	</div>
	<Input label="UUID / IMEI" placeholder="Enter UUID or IMEI" value={uuidImei} onChange={...} />
	<div>
		<Label className="mb-1 block text-sm font-medium">Start Date</Label>
		<DatePicker value={startDate} onChange={setStartDate} showTime />
	</div>
	<div>
		<Label className="mb-1 block text-sm font-medium">End Date</Label>
		<DatePicker value={endDate} onChange={setEndDate} showTime />
	</div>
	<div>
		<Label className="mb-1 block text-sm font-medium">Category</Label>
		<Select value={selectedCategoryId || '__all__'} onValueChange={...}>
			<SelectTrigger className="w-full"><SelectValue placeholder="All" /></SelectTrigger>
			<SelectContent>...</SelectContent>
		</Select>
	</div>
</div>

<div className="flex gap-2 mb-2">
	<Button variant="outline" size="sm" onClick={handleClear}>Clear</Button>
	<Button variant="primary" size="sm" onClick={handleSearch} disabled={!alertType}>Search</Button>
</div>
```
