# Overlay Components

## Modal

```tsx
import { Modal } from "@decklar/ui-library";
```

**Props:**

- `open`: `boolean`
- `onOpenChange`: `(open: boolean) => void`
- `title`: `string` — modal heading (omit for no-title modals)
- `showClose`: `boolean` — show × close button (default: `false`)
- `size`: `"xs"` | `"sm"` | `"md"` | `"lg"` (default: `"md"`)
- `footer`: `React.ReactNode` — action buttons rendered in the footer
- `preventClose`: `boolean` — disables closing on backdrop click / Esc
- `children`: body content

**Basic example:**

```tsx
const [open, setOpen] = useState(false);

<Button onClick={() => setOpen(true)}>Open</Button>

<Modal
  open={open}
  onOpenChange={setOpen}
  title="Save Workflow"
  showClose
  footer={
    <>
      <Button variant="secondary" onClick={() => setOpen(false)}>Cancel</Button>
      <Button variant="primary" onClick={handleSave}>Save</Button>
    </>
  }
>
  <p>Modal body content goes here.</p>
</Modal>
```

**Confirmation / destructive dialog:**

```tsx
<Modal
    open={open}
    onOpenChange={setOpen}
    title="Delete Item"
    showClose
    size="xs"
    footer={
        <>
            <Button variant="secondary" onClick={() => setOpen(false)}>
                No
            </Button>
            <Button variant="destructive" onClick={handleDelete}>
                Yes, delete
            </Button>
        </>
    }
>
    <p>Are you sure you want to delete this item? This action cannot be undone.</p>
</Modal>
```

**Scrollable modal with prevent-close:**

```tsx
<Modal
    open={open}
    onOpenChange={setOpen}
    title="Terms and Conditions"
    preventClose
    size="lg"
    footer={
        <Button variant="primary" onClick={() => setOpen(false)}>
            Accept
        </Button>
    }
>
    {/* Long content */}
</Modal>
```

---

## Tooltip

```tsx
import { Tooltip, TooltipProvider } from "@decklar/ui-library";
```

Wrap `<TooltipProvider>` once near the root of the component tree (or layout). Do **not** wrap every Tooltip individually.

**TooltipProvider props:**

- `delayDuration`: `number` (ms) — hover delay before showing tooltip (default: `700`)

**Tooltip props:**

- `content`: `string` — tooltip text (required for both variants)
- `side`: `"top"` | `"bottom"` | `"left"` | `"right"` (default: `"top"`)
- `variant`: `"definition"` | `"interactive"` (default: `"definition"`)
- `title`: `string` — header text (**interactive** variant only)
- `linkText`: `string` — "learn more" link label (**interactive** variant only)
- `onLinkClick`: `() => void` (**interactive** variant only)
- `actionText`: `string` — primary action button label (**interactive** variant only)
- `onAction`: `() => void` (**interactive** variant only)
- `children`: the trigger element (must be a single element, e.g. `<button>`)

**Definition tooltip (simple hover label):**

```tsx
<TooltipProvider delayDuration={100}>
    <Tooltip content="Total revenue before deductions." side="top">
        <button type="button" className="underline decoration-dotted">
            Gross Revenue
        </button>
    </Tooltip>
</TooltipProvider>
```

**Interactive tooltip (onboarding / contextual help):**

```tsx
<TooltipProvider>
    <Tooltip
        variant="interactive"
        title="What is a shipment?"
        content="A shipment tracks goods movement from origin to destination with real-time monitoring."
        linkText="Learn more"
        onLinkClick={() => router.push("/docs/shipments")}
        actionText="Got it"
        onAction={() => setDismissed(true)}
        side="bottom"
    >
        <button type="button" className="rounded-full w-5 h-5 bg-surface-hover text-xs">
            ?
        </button>
    </Tooltip>
</TooltipProvider>
```
