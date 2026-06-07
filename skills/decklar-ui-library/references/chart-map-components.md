# Chart & Map Components

## Table of Contents

1. [Chart](#chart)
2. [Map / MapCore](#map)

---

## Chart

```tsx
import { Chart } from '@decklar/ui-library';
```

`Chart` is a **discriminated union** — the `type` prop determines which chart renders and which additional props are available. All chart types share these base props:

**Base props (all types):**

-   `title`: `string` — card title
-   `description`: `ReactNode` — subtitle/description
-   `height`: `number` — chart height in px

**Available chart types:** `"bar"` | `"line"` | `"area"` | `"ring"` | `"pie"` | `"radar"` | `"funnel"` | `"scatter"` | `"composed"` | `"themeriver"` | `"listcard"`

**Series color palette:** `"violet"` | `"blue"` | `"yellow"` | `"green"` | `"red"`

### Bar Chart

```tsx
<Chart
  type="bar"
  title="Monthly Shipments"
  height={300}
  data={[
    { month: 'Jan', count: 120, revenue: 45000 },
    { month: 'Feb', count: 150, revenue: 52000 },
  ]}
  xKey="month"
  series={[
    { key: 'count', name: 'Shipments', color: 'blue' },
    { key: 'revenue', name: 'Revenue', color: 'green' },
  ]}
  layout="vertical" // optional: "vertical" | "horizontal"
  actionLabel="View All"
  onAction={() => navigate('/shipments')}
/>
```

### Line Chart

```tsx
<Chart
  type="line"
  title="Temperature Over Time"
  height={250}
  data={tempData}
  xKey="timestamp"
  series={[{ key: 'temp', name: 'Temperature (°C)', color: 'red' }]}
/>
```

### Area Chart

```tsx
<Chart
  type="area"
  title="Network Traffic"
  height={250}
  data={trafficData}
  xKey="time"
  series={[{ key: 'inbound', name: 'Inbound', color: 'blue' }]}
  gradient // enables gradient fill
/>
```

### Ring / Donut (progress indicator)

```tsx
<Chart
  type="ring"
  value={72}
  max={100}      // default: 100
  unit="%"       // default: "%"
  color="green"
  size={104}     // default: 104
  title="Completion"
/>
```

### Pie Chart

```tsx
<Chart
  type="pie"
  title="Shipment Distribution"
  height={300}
  data={[
    { name: 'Air', value: 340 },
    { name: 'Ground', value: 580 },
    { name: 'Sea', value: 220 },
  ]}
  showLabel // show percentage labels
/>
```

### Radar Chart

```tsx
<Chart
  type="radar"
  title="Performance Metrics"
  height={300}
  data={[
    { metric: 'Speed', teamA: 80, teamB: 65 },
    { metric: 'Accuracy', teamA: 90, teamB: 85 },
  ]}
  angleKey="metric"
  keys={[
    { key: 'teamA', name: 'Team A', color: 'blue' },
    { key: 'teamB', name: 'Team B', color: 'violet' },
  ]}
/>
```

### Funnel Chart

```tsx
<Chart
  type="funnel"
  title="Conversion Funnel"
  height={300}
  data={[
    { name: 'Visits', value: 5000 },
    { name: 'Signups', value: 3200 },
    { name: 'Trials', value: 1800 },
    { name: 'Paid', value: 900 },
  ]}
  showConversion // show conversion % between steps
/>
```

### Scatter Chart

```tsx
<Chart
  type="scatter"
  title="Weight vs. Cost"
  height={300}
  xLabel="Weight (kg)"
  yLabel="Cost ($)"
  series={[
    { name: 'Domestic', color: 'blue', data: [{ x: 5, y: 120 }, { x: 12, y: 280 }] },
    { name: 'International', color: 'red', data: [{ x: 8, y: 450 }, { x: 20, y: 800 }] },
  ]}
/>
```

### Composed Chart (bar + line overlay)

```tsx
<Chart
  type="composed"
  title="Revenue & Growth"
  height={300}
  data={revenueData}
  xKey="month"
  series={[
    { key: 'revenue', name: 'Revenue', type: 'bar', color: 'blue' },
    { key: 'growth', name: 'Growth %', type: 'line', color: 'green' },
  ]}
/>
```

### ThemeRiver (flow over time)

```tsx
<Chart
  type="themeriver"
  title="Topic Trends"
  height={300}
  data={[
    // [timestamp, value, category]
    ['2024-01', 120, 'Alerts'],
    ['2024-01', 80, 'Shipments'],
    ['2024-02', 150, 'Alerts'],
    ['2024-02', 95, 'Shipments'],
  ]}
/>
```

### ListCard (stat summary)

```tsx
<Chart
  type="listcard"
  title="Fleet Summary"
  value={1234}
  valueDelta={12.5} // percentage change
  items={[
    { label: 'Active', value: 890, color: 'green' },
    { label: 'Idle', value: 234, color: 'yellow' },
    { label: 'Offline', value: 110, color: 'red' },
  ]}
/>
```

---

## Map

```tsx
import { Map, MapCore } from '@decklar/ui-library';
// Deck.gl layers
import { ArcLayer, GeoJsonLayer, IconLayer, LineLayer, PathLayer, PolygonLayer, ScatterplotLayer, TextLayer } from '@decklar/ui-library';
// Hooks
import { useMapLibreCluster, useRouteAnimation, useAlertSimulation } from '@decklar/ui-library';
```

Two map components built on **MapLibre GL** + **deck.gl**:

-   **`MapCore`** — pure map + layers, no UI controls
-   **`Map`** — extends MapCore with fullscreen, zoom, legend, settings panel

### MapCore props

-   `initialViewState`: `MapViewState` — `{ longitude, latitude, zoom, pitch?, bearing? }`
-   `viewState`: `MapViewState` — controlled view state
-   `layers`: `Layer[]` — deck.gl layer instances
-   `controller`: `boolean | ControllerOptions` — enable pan/zoom/rotate
-   `mapStyle`: `string | StyleSpecification` — MapLibre style URL or object
-   `width`: `number | string` (default: `'100%'`)
-   `height`: `number | string` (default: `400`)
-   `minZoom` / `maxZoom`: `number` (default: `0` / `22`)
-   `onViewStateChange`: `(params) => void`
-   `onClick`: `(info: PickingInfo) => void`
-   `onHover`: `(info: PickingInfo) => void`
-   `getTooltip`: `(info: PickingInfo) => MapTooltipContent`
-   `renderTooltip`: `(info: PickingInfo) => ReactNode`
-   `loading`: `boolean`
-   `onMapLoad`: `(map: maplibregl.Map) => void`

**Imperative handle** (via `ref`): `fitBounds()`, `zoomIn()`, `zoomOut()`, `getViewState()`

### Map props (extends MapCore)

-   `fullscreenControl`: `boolean`
-   `zoomControls`: `boolean`
-   `legend`: `ReactNode`
-   `overlay`: `ReactNode`
-   `controls`: `ReactNode`
-   `defaultMapStyle`: `"light"` | `"dark"` | `"satellite"`
-   `onMapStyleChange`: `(mode) => void`
-   `settingsPanel`: `boolean | MapSettingsPanelConfig`

### Basic example

```tsx
import { Map, ScatterplotLayer } from '@decklar/ui-library';

const shipmentLayer = new ScatterplotLayer({
  id: 'shipments',
  data: shipments,
  getPosition: (d) => [d.longitude, d.latitude],
  getRadius: 500,
  getFillColor: [0, 128, 255],
  pickable: true,
});

<Map
  initialViewState={{ longitude: -98, latitude: 39, zoom: 4 }}
  layers={[shipmentLayer]}
  height={500}
  fullscreenControl
  zoomControls
  defaultMapStyle="light"
  onClick={(info) => info.object && openDetail(info.object)}
  getTooltip={(info) => info.object ? { text: info.object.name } : null}
/>;
```

### Map hooks

**`useMapLibreCluster`** — cluster point data on the map:

```tsx
const { layers, supercluster } = useMapLibreCluster({
  data: shipments,
  getPosition: (d) => [d.lng, d.lat],
  clusterRadius: 40,
});
```

**`useRouteAnimation`** — animate a route path:

```tsx
const { layer, isPlaying, play, pause, reset } = useRouteAnimation({
  path: routeCoordinates,
  speed: 50,
});
```

**`useAlertSimulation`** — simulate alerts on the map for demos:

```tsx
const { alerts, layer } = useAlertSimulation({
  templates: DEFAULT_ALERT_TEMPLATES,
  interval: 3000,
});
```

### Map constants & utilities

```tsx
import {
  DEFAULT_VIEW_STATE, DEFAULT_MAP_STYLE, MAP_STYLES, MAP_STYLES_NOLABELS,
  buildSolidPin, buildDottedPin, buildTruckPin, buildWarehousePin, buildPlanePin, buildCustomPin,
  buildScatterDot, clearIconCache,
  generateAlert, formatAlertAge, buildAlertPulseLayer,
  DEFAULT_ALERT_TEMPLATES, ALERT_COLORS_RGBA, ALERT_CSS_COLOR, ALERT_SEVERITY_LABEL,
} from '@decklar/ui-library';
```

### Deck.gl layer re-exports

All layers are re-exported for convenience — no need to install `@deck.gl/layers` separately:

`ArcLayer`, `GeoJsonLayer`, `IconLayer`, `LineLayer`, `PathLayer`, `PolygonLayer`, `ScatterplotLayer`, `TextLayer`
