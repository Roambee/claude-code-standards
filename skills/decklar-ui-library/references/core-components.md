# Core Components

## Button

```tsx
import { Button } from "@decklar/ui-library";
```

**Props:**

- `variant`: `"primary"` | `"secondary"` | `"outline"` | `"floating"` | `"destructive"` (default: `"primary"`)
- `size`: `"default"` | `"field"` | `"sm"` | `"tiny"`
- `loading`: `boolean` — shows spinner, disables interaction
- `disabled`: `boolean`
- All native `<button>` props

**Examples:**

```tsx
<Button variant="primary">Save</Button>
<Button variant="secondary">Cancel</Button>
<Button variant="outline">Outline</Button>
<Button variant="destructive">Delete</Button>
<Button variant="floating" size="tiny" aria-label="Add"><Plus /></Button>
<Button variant="primary" loading>Saving…</Button>
<Button variant="primary" onClick={() => handleSave()}>
  <Plus size={20} /> Add Item
</Button>
```

Use `variant="floating"` with `size="tiny"` for icon-only action buttons. Always include `aria-label` for icon-only buttons.

---

## Badge

```tsx
import { Badge } from "@decklar/ui-library";
```

**Props:**

- `variant`: `"primary"` | `"success"` | `"warning"` | `"error"` | `"info"`

**Examples:**

```tsx
<Badge variant="success">Delivered</Badge>
<Badge variant="warning">In Transit</Badge>
<Badge variant="error">Urgent</Badge>
<Badge variant="info">Pending</Badge>
<Badge variant="primary">Normal</Badge>
```

Use for status indicators in tables, lists, and detail views.

---

## Card

```tsx
import { Card, CardContent, CardTitle, CardDescription, CardLabel, CardTags, CardTag } from "@decklar/ui-library";
```

**Card props:**

- `variant`: `"elevated"` | `"outlined"` | `"ghost"`
- `onClick`: optional — makes the card interactive/clickable

**CardTag props:**

- `variant`: `"success"` | `"warning"` | `"error"` | `"info"` | `"primary"`

**Example:**

```tsx
<Card variant="elevated">
    <CardContent>
        <CardLabel>Category</CardLabel>
        <CardTitle>Card title goes here</CardTitle>
        <CardDescription>Supporting description text.</CardDescription>
        <CardTags>
            <CardTag variant="success">Active</CardTag>
            <CardTag variant="info">Q1</CardTag>
        </CardTags>
    </CardContent>
</Card>
```

Use `variant="elevated"` for dashboard items, `variant="outlined"` for list items, `variant="ghost"` for subtle containers.

---

## Tag

> ⚠️ **`Tag` is NOT exported from `@decklar/ui-library`** — importing it causes a build error:
> `export 'Tag' was not found in '@decklar/ui-library'`
>
> **Use `Badge` instead** for all inline pills, chips, and category labels.

```tsx
// ❌ WRONG — Tag does not exist as a standalone export
import { Tag } from "@decklar/ui-library"; // BUILD ERROR

// ✅ CORRECT — use Badge for inline chips/pills
import { Badge } from "@decklar/ui-library";
```

**Badge is the correct replacement for Tag:**

```tsx
// Status chips in table cells
<Badge variant="success">Active</Badge>
<Badge variant="info">Draft</Badge>
<Badge variant="warning">Archived</Badge>
<Badge variant="primary">express</Badge>
<Badge variant="error">hazardous</Badge>

// Tag list in a table cell
<div style={{ display: 'flex', flexWrap: 'wrap', gap: '4px' }}>
    {tags.map((tag) => (
        <Badge key={tag} variant="primary">{tag}</Badge>
    ))}
</div>
```

**`CardTag`** is a different component — it only works **inside** a `<Card>`:

```tsx
import { Card, CardContent, CardTags, CardTag } from "@decklar/ui-library";

// ✅ CardTag inside Card — fine
<Card><CardContent><CardTags><CardTag variant="info">Q1</CardTag></CardTags></CardContent></Card>

// ❌ CardTag outside Card — incorrect usage
<CardTag variant="info">Q1</CardTag>
```

Use `Badge` for all standalone chips — it has 5 variants: `"primary"` | `"success"` | `"warning"` | `"error"` | `"info"`.
