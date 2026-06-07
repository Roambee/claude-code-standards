# Form Components

## Table of Contents

1. [Label](#label)
2. [Input](#input)
3. [Textarea](#textarea)
4. [Checkbox](#checkbox)
5. [Switch](#switch)
6. [Slider](#slider)
7. [RadioButton / RadioButtonItem](#radiobutton)
8. [Select](#select)
9. [MultiSelect](#multiselect)
10. [DatePicker / DateRangePicker](#datepicker)
11. [Calendar](#calendar)
12. [FileUpload](#fileupload)
13. [DraggableList](#draggablelist)
14. [Form (react-hook-form integration)](#form-react-hook-form-integration)

---

## Label

```tsx
import { Label } from "@decklar/ui-library";
```

Always pair with a form field using `htmlFor` / `id`:

```tsx
<Label htmlFor="email">Email address</Label>
<Input id="email" type="email" />
```

---

## Input

```tsx
import { Input } from "@decklar/ui-library";
```

**Props:**

- `error`: `boolean` — red/error styling
- `disabled`: `boolean`
- `type`: any HTML input type (`"text"` | `"email"` | `"password"` | `"number"` | …)
- All native `<input>` props

**Examples:**

```tsx
<Input placeholder="Enter text" />
<Input type="email" placeholder="you@example.com" />
<Input type="password" placeholder="••••••••" />
<Input error placeholder="Invalid value" />
<Input disabled placeholder="Disabled" />
<Input value={value} onChange={(e) => setValue(e.target.value)} />

// With icon (wrap in a relative div)
<div className="relative">
  <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-text-secondary" size={16} />
  <Input className="pl-9" placeholder="Search…" />
</div>
```

---

## Textarea

```tsx
import { Textarea } from "@decklar/ui-library";
```

**Props:**

- `error`: `boolean`
- `disabled`: `boolean`
- `rows`: `number`
- All native `<textarea>` props

**Examples:**

```tsx
<Textarea placeholder="Enter message" />
<Textarea rows={5} placeholder="Long description…" />
<Textarea error placeholder="Required" />
<Textarea value={value} onChange={(e) => setValue(e.target.value)} />
```

---

## Checkbox

```tsx
import { Checkbox } from "@decklar/ui-library";
```

**Props:**

- `checked`: `boolean | "indeterminate"`
- `defaultChecked`: `boolean`
- `onCheckedChange`: `(checked: boolean | "indeterminate") => void`
- `disabled`: `boolean`

**Examples:**

```tsx
<Checkbox />
<Checkbox defaultChecked />
<Checkbox checked="indeterminate" />
<Checkbox disabled />

// With label
<div className="flex items-center gap-2">
  <Checkbox id="terms" checked={checked} onCheckedChange={(v) => setChecked(v === true)} />
  <Label htmlFor="terms" className="cursor-pointer font-normal">Accept terms</Label>
</div>
```

---

## Switch

```tsx
import { Switch } from "@decklar/ui-library";
```

**Props:**

- `checked`: `boolean`
- `defaultChecked`: `boolean`
- `onCheckedChange`: `(checked: boolean) => void`
- `disabled`: `boolean`

**Examples:**

```tsx
<Switch />
<Switch defaultChecked />
<Switch checked={enabled} onCheckedChange={setEnabled} />

// With label
<div className="flex items-center gap-3">
  <Switch id="notifications" checked={on} onCheckedChange={setOn} />
  <Label htmlFor="notifications">Email notifications</Label>
</div>
```

---

## Slider

```tsx
import { Slider } from "@decklar/ui-library";
```

**Props:**

- `value`: `number[]`
- `defaultValue`: `number[]`
- `onValueChange`: `(value: number[]) => void`
- `min`, `max`, `step`: `number`
- `disabled`: `boolean`

**Examples:**

```tsx
<Slider defaultValue={[50]} min={0} max={100} />
<Slider value={[years]} onValueChange={([v]) => setYears(v)} min={0} max={50} step={1} />
```

---

## RadioButton

```tsx
import { RadioButton, RadioButtonItem } from "@decklar/ui-library";
```

**RadioButton props:**

- `value`: `string` — controlled value
- `defaultValue`: `string`
- `onValueChange`: `(value: string) => void`
- `orientation`: `"horizontal"` | `"vertical"` (default: `"vertical"`)
- `disabled`: `boolean`

**Examples:**

```tsx
<RadioButton defaultValue="email">
  <RadioButtonItem value="email">Email</RadioButtonItem>
  <RadioButtonItem value="phone">Phone</RadioButtonItem>
  <RadioButtonItem value="sms">SMS</RadioButtonItem>
</RadioButton>

<RadioButton orientation="horizontal" value={method} onValueChange={setMethod}>
  <RadioButtonItem value="a">Option A</RadioButtonItem>
  <RadioButtonItem value="b">Option B</RadioButtonItem>
</RadioButton>
```

---

## Select

```tsx
import { Select, SelectTrigger, SelectValue, SelectContent, SelectItem, SelectGroup, SelectLabel, SelectSeparator, SelectSearch } from "@decklar/ui-library";
```

**Examples:**

Basic:

```tsx
<Select>
    <SelectTrigger>
        <SelectValue placeholder="Select option" />
    </SelectTrigger>
    <SelectContent>
        <SelectItem value="1">Option 1</SelectItem>
        <SelectItem value="2">Option 2</SelectItem>
    </SelectContent>
</Select>
```

Controlled:

```tsx
<Select value={value} onValueChange={setValue}>
    <SelectTrigger>
        <SelectValue placeholder="Choose…" />
    </SelectTrigger>
    <SelectContent>
        <SelectItem value="a">Option A</SelectItem>
        <SelectItem value="b">Option B</SelectItem>
    </SelectContent>
</Select>
```

With search and groups:

```tsx
<Select>
    <SelectTrigger>
        <SelectValue placeholder="Select country" />
    </SelectTrigger>
    <SelectContent>
        <SelectSearch placeholder="Search…" />
        <SelectGroup>
            <SelectLabel>Europe</SelectLabel>
            <SelectItem value="de">Germany</SelectItem>
            <SelectItem value="fr">France</SelectItem>
        </SelectGroup>
        <SelectSeparator />
        <SelectGroup>
            <SelectLabel>Asia</SelectLabel>
            <SelectItem value="jp">Japan</SelectItem>
        </SelectGroup>
    </SelectContent>
</Select>
```

---

## MultiSelect

```tsx
import { MultiSelect } from "@decklar/ui-library";
import type { MultiSelectOption } from "@decklar/ui-library";
```

**Props:**

- `options`: `MultiSelectOption[]` — `{ value: string; label: string }`
- `value`: `string[]`
- `onValueChange`: `(values: string[]) => void`
- `placeholder`: `string`
- `disabled`: `boolean`

**Example:**

```tsx
const skillOptions: MultiSelectOption[] = [
    { value: "react", label: "React" },
    { value: "ts", label: "TypeScript" },
    { value: "node", label: "Node.js" },
];

<MultiSelect options={skillOptions} value={selected} onValueChange={setSelected} placeholder="Select skills…" />;
```

---

## DatePicker

```tsx
import { DatePicker, DateRangePicker } from "@decklar/ui-library";
```

**DatePicker props:**

- `value`: `Date | undefined`
- `onChange`: `(date: Date | undefined) => void`
- `placeholder`: `string`
- `disabled`: `boolean`

**DateRangePicker additional props:**

- `value`: `DateRange | undefined` — `{ from: Date; to?: Date }`
- `presets`: `DatePreset[]` — `{ label: string; from: Date; to: Date }`

**Examples:**

```tsx
<DatePicker value={date} onChange={setDate} placeholder="Select date" />

<DateRangePicker value={range} onChange={setRange} placeholder="Select range" />
```

---

## Calendar

```tsx
import { Calendar } from '@decklar/ui-library';
```

Standalone calendar component (wraps `react-day-picker`'s `DayPicker`). Accepts all `DayPickerProps`.

Use `Calendar` when you need an always-visible inline calendar. For popup date selection, use `DatePicker` instead.

```tsx
const [selected, setSelected] = useState<Date | undefined>();

<Calendar
  mode="single"
  selected={selected}
  onSelect={setSelected}
  disabled={{ before: new Date() }} // disable past dates
/>
```

**Range selection:**

```tsx
const [range, setRange] = useState<DateRange | undefined>();

<Calendar
  mode="range"
  selected={range}
  onSelect={setRange}
  numberOfMonths={2}
/>
```

---

## FileUpload

```tsx
import { FileUpload } from "@decklar/ui-library";
import type { FileUploadFile } from "@decklar/ui-library";
```

**Props:**

- `value`: `FileUploadFile[]`
- `onChange`: `(files: FileUploadFile[]) => void`
- `accept`: `string` — MIME types (e.g. `"image/*,.pdf"`)
- `maxSize`: `number` — bytes
- `multiple`: `boolean`
- `disabled`: `boolean`

**Example:**

```tsx
<FileUpload value={files} onChange={setFiles} accept=".pdf,.docx" maxSize={5 * 1024 * 1024} multiple />
```

---

## DraggableList

```tsx
import { DraggableList } from "@decklar/ui-library";
import type { DraggableListItem } from "@decklar/ui-library";
```

**Props:**

- `items`: `DraggableListItem[]` — `{ id: string; content: React.ReactNode }`
- `onReorder`: `(items: DraggableListItem[]) => void`
- `disabled`: `boolean`

**Example:**

```tsx
const [items, setItems] = useState<DraggableListItem[]>([
    { id: "1", content: <span>Step 1</span> },
    { id: "2", content: <span>Step 2</span> },
]);

<DraggableList items={items} onReorder={setItems} />;
```

---

## Form (react-hook-form integration)

Use `Form` with `Form*` wrappers for any form with validation. The library integrates react-hook-form + Zod internally.

```tsx
import { z } from "zod";
import { Form, useFormValues, FormInput, FormTextarea, FormSelect, FormMultiSelect, FormCheckbox, FormSwitch, FormRadioGroup, FormSlider, FormDatePicker, FormDateRangePicker, FormFileUpload } from "@decklar/ui-library";
import { SelectItem, RadioButtonItem, Label } from "@decklar/ui-library";
import { Button } from "@decklar/ui-library";
```

> ⚠️ **Always `import { z } from 'zod'`** — never from `'zod/v3'`.
> `'zod/v3'` is the legacy compatibility shim. The `Form` component requires Zod v4 types from `'zod'`.

---

### ⚠️ Known Zod API Limitations in This Project

The installed Zod v4 build has broken TypeScript types for several functions. The table below shows what works and what to use instead:

| Zod API | Status | Fix |
|---|---|---|
| `z.string()`, `.min()`, `.email()`, `.optional()` | ✅ Works | — |
| `z.boolean()`, `.optional()` | ✅ Works | — |
| `z.date()`, `.optional()` | ✅ Works | — |
| `z.number()` | ✅ Works | — |
| `z.array(z.string())` | ✅ Works | — |
| `z.enum(['a', 'b'])` | ❌ `TS2554: Expected 0 arguments` | Use `z.string()` + type cast |
| `z.literal('value')` | ❌ `TS2554: Expected 0 arguments` | Use `z.string()` + type cast |
| `z.union([schemaA, schemaB])` | ❌ `TS2554: Expected 0 arguments` | Use `z.string()` + type cast |

**Pattern for select / enum fields:**

```tsx
// ❌ WRONG — causes TS2554 error
const schema = z.object({
    status: z.enum(['active', 'draft', 'archived']),
    mode: z.union([z.literal('air'), z.literal('sea')]),
});

// ✅ CORRECT — use z.string() and type-cast when saving
type Status = 'active' | 'draft' | 'archived';
type Mode = 'air' | 'sea';

const schema = z.object({
    status: z.string().min(1, 'Status is required'),
    mode:   z.string().min(1, 'Mode is required'),
});

// In your submit handler, cast back to your TS type:
function handleSubmit(values: z.infer<typeof schema>) {
    const status = values.status as Status;
    const mode   = values.mode as Mode;
}
```

---

### ⚠️ `FormDatePicker` — No `label` Prop

`FormDatePicker` does **not** accept a `label` prop. Add a `<Label>` manually above it:

```tsx
// ❌ WRONG — label prop does not exist on FormDatePicker
<FormDatePicker name="startDate" label="Start date" placeholder="Pick a date" />

// ✅ CORRECT — use Label component above it
import { Label } from "@decklar/ui-library";

<div style={{ display: 'flex', flexDirection: 'column', gap: '6px' }}>
    <Label>Start date</Label>
    <FormDatePicker name="startDate" placeholder="Pick a date" />
</div>
```

All other `Form*` components (`FormInput`, `FormSelect`, `FormTextarea`, `FormMultiSelect`, `FormSwitch`, `FormCheckbox`, `FormRadioGroup`, `FormSlider`) **do** accept `label` as a prop normally.

### Required fields — red asterisk on the label

`FormInput`, `FormSelect`, and `FormMultiSelect` accept **`required?: boolean`**. When `required` is true, the library appends a red **`*`** next to the label (`text-error-500`). Zod validation does **not** set this automatically — pass `required` on each mandatory field:

```tsx
<FormInput name="name" label="Name" placeholder="…" required />
<FormSelect name="role" label="Role" placeholder="Choose…" required>
  <SelectItem value="admin">Admin</SelectItem>
</FormSelect>
```

---

**Form props:**

- `schema`: Zod schema — defines field types and validation rules
- `defaultValues`: object matching schema
- `onSubmit`: `(values: z.infer<typeof schema>) => Promise<void> | void`
- `disabled`: `boolean` — disables all fields

**`useFormValues()`** — access form state inside `<Form>`:

- Returns `{ watch, formState: { errors, touchedFields, isSubmitting, isSubmitSuccessful }, setValue, … }`

**Full working example (uses only safe Zod APIs):**

```tsx
import { z } from "zod"; // ← always from 'zod', never 'zod/v3'
import { Label } from "@decklar/ui-library";

type UserRole = 'admin' | 'editor' | 'viewer';

const schema = z.object({
    name:        z.string().min(2, "Name must be at least 2 characters"),
    email:       z.string().email("Invalid email"),
    role:        z.string().min(1, "Role is required"),   // ← z.string(), NOT z.enum()
    skills:      z.array(z.string()).optional(),
    experience:  z.number().min(0).max(50),
    startDate:   z.date().optional(),                     // ← no label prop on FormDatePicker
    acceptTerms: z.boolean(),
    newsletter:  z.boolean().optional(),
});

const skillOptions = [
    { value: "react", label: "React" },
    { value: "ts", label: "TypeScript" },
];

<Form
    schema={schema}
    defaultValues={{ name: "", email: "", role: "", skills: [], experience: 0, acceptTerms: false, newsletter: false, startDate: undefined }}
    onSubmit={async (values) => {
        const role = values.role as UserRole; // ← type cast here
        await api.save({ ...values, role });
    }}
>
    <FormInput name="name" label="Name" placeholder="Jane Doe" />
    <FormInput name="email" label="Email" type="email" placeholder="jane@example.com" />
    <FormTextarea name="bio" label="Bio" placeholder="About you…" />

    <FormSelect name="role" label="Role" placeholder="Choose role">
        <SelectItem value="admin">Admin</SelectItem>
        <SelectItem value="editor">Editor</SelectItem>
        <SelectItem value="viewer">Viewer</SelectItem>
    </FormSelect>

    <FormMultiSelect name="skills" label="Skills" options={skillOptions} placeholder="Select skills" />
    <FormSlider name="experience" label="Years of experience" min={0} max={50} />

    {/* FormDatePicker has no label prop — use Label manually */}
    <div style={{ display: 'flex', flexDirection: 'column', gap: '6px' }}>
        <Label>Start date</Label>
        <FormDatePicker name="startDate" placeholder="Pick a date" />
    </div>

    <FormCheckbox name="acceptTerms" label="I accept the terms and conditions" />
    <FormSwitch name="newsletter" label="Subscribe to newsletter" />

    <FormRadioGroup name="contactMethod" label="Preferred contact">
        <RadioButtonItem value="email">Email</RadioButtonItem>
        <RadioButtonItem value="phone">Phone</RadioButtonItem>
        <RadioButtonItem value="sms">SMS</RadioButtonItem>
    </FormRadioGroup>

    <Button type="submit">Submit</Button>
</Form>;
```

Each `Form*` component automatically handles error display, touched state, and disabled-during-submit behaviour. Always use these instead of standalone fields when building validated forms.
