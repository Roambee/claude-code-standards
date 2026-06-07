---
name: hive-app-creator
description: >
    Guide for creating new apps or modules in the Hive Dashboard (HC20) monorepo.
    Use this skill when the user asks to create a new app, page, module, or feature inside the
    Hive Dashboard, or wants to add a brand new micro-frontend application to the Roambee platform.
    Covers two workflows: (1) Adding a new module/page inside HC20 (e.g., a new table page, dashboard,
    or feature), and (2) Creating an entirely new Single-SPA micro-frontend app alongside HC20.
    Triggers on: "create a new app", "add a new page to hive", "new module in hc20", "scaffold an app",
    "new micro-frontend", "add feature to dashboard", "new hive app".
    DO NOT use this skill for UI component creation — use component-library-skill for that.
    DO NOT use this skill for consuming existing UI library components — use ui-library-usage for that.
---

# Hive App Creator Skill

Use this skill to scaffold new apps or modules in the Roambee Hive Dashboard monorepo.

## STEP 0 — Gather ALL Inputs Before Doing Anything Else

**MANDATORY: Do NOT write any files, generate any code, or begin any scaffolding until the user has explicitly answered ALL four questions below — even if they already mentioned the app name.**

> Example: If the user says _"create a new app Task Manager"_, you now have the name but STILL MUST ask for the other three before doing anything.

Check which of the four inputs you already have from the user's message, then ask for **all missing ones together in a single reply**:

1. **App/Module name** — e.g., "Fleet Manager", "Alert Center"
2. **Description** — one sentence explaining what it does
3. **Scope** — choose one:
    - **A) New module inside HC20** (adds a page at `/hc20/<name>`) — most common
    - **B) Brand new micro-frontend app** (fully separate app like IntegrationHub or Studio)
4. **Primary feature type** — choose one:
    - Table / List page
    - Dashboard / Analytics
    - Form / Settings
    - Custom / Mixed

**Rules:**

-   NEVER assume or default any missing value.
-   NEVER start scaffolding with partial information.
-   If the user's reply still leaves some answers missing, ask again for only the remaining ones.
-   Only once all four are explicitly confirmed, proceed to the matching workflow below.

---

## Architecture Overview

This monorepo uses **Single-SPA** micro-frontends:

| Concept                              | Location                      | Example                                   |
| ------------------------------------ | ----------------------------- | ----------------------------------------- |
| Shell/Orchestrator                   | `packages/client/root/`       | Routes, import maps                       |
| HC20 Dashboard                       | `packages/client/hc20/`       | Bees, Shipments, Assets                   |
| Studio App                           | `packages/client/studio/`     | App Builder, Workflows                    |
| Navigation                           | `packages/client/sidenav/`    | Left sidebar                              |
| Shared Utilities                     | `packages/client/utility/`    | API, EventEmitter, Auth                   |
| UI Library (USE THIS)                | `@decklar/ui-library` (npm)   | DataTable, Form, Toast, all UI components |
| Styleguide (DEPRECATED — DO NOT USE) | `packages/client/styleguide/` | Legacy — do not import in new code        |

**Naming convention**: `@roambee/client-<name>` — packages at `packages/client/<name>/`.

---

## ⚠️ MANDATORY RULE: Use UI Library, NOT Styleguide

All new apps, modules, pages, and components **MUST** import UI components exclusively from `@decklar/ui-library`.

-   **DO**: `import { DataTable, Button, Toast } from '@decklar/ui-library';`
-   **DO NOT**: `import { DataTable, Loader, SubHeader } from '@roambee/client-styleguide';` ← NEVER use this in new code.

`@roambee/client-styleguide` is **legacy/deprecated**. It must NOT be used when creating anything new.
See the **ui-library-usage** skill for the full component catalog, import patterns, and composition recipes.

---

## Workflow A: New Module Inside HC20

Use when adding a new page/feature to the existing Hive Dashboard (`/hc20/*` route).

### Step 1 — Derive identifiers from user input

Given user inputs `appName` and `description`, derive:

```
moduleName    = kebab-case(appName)          // e.g., "fleet-manager"
componentName = PascalCase(appName)          // e.g., "FleetManager"
routePath     = "hc20/" + moduleName         // e.g., "hc20/fleet-manager"
routeFileName = camelCase(appName) + "Routes" // e.g., "fleetManagerRoutes"
```

### Step 2 — Create module component

Create: `packages/client/hc20/src/modules/<moduleName>/<ComponentName>/index.tsx`

Use the template from [assets/hc20-module-template.tsx](assets/hc20-module-template.tsx).

Key patterns:

-   Use lazy loading via `React.lazy()`
-   All UI component imports come from `@decklar/ui-library` (NOT `@roambee/client-styleguide`)
-   Imports from `@roambee/client-utility` use `// @ts-ignore`
-   API calls use `API(method, path)` from `@roambee/client-utility`
-   Notifications use `EventEmitter.emit('showSnackbar', {...})`
-   **Every page MUST include `Breadcrumbs`** — import `Breadcrumbs` and `BreadcrumbItem` from `@decklar/ui-library`. Place `<Breadcrumbs items={...} />` at the top of every page. Use `onClick` with `useNavigate()` for SPA navigation. The last breadcrumb item (current page) has no `onClick`/`href`.

### Step 3 — Create route file

Create: `packages/client/hc20/src/routes/<routeFileName>.ts`

```typescript
import { createElement, lazy } from 'react';
import { <CarbonIcon> } from '@carbon/icons-react';
import { RouteType } from '.';

const <ComponentName> = lazy(() => import('../modules/<moduleName>/<ComponentName>'));

const <routeFileName>: RouteType[] = [
    {
        path: '<routePath>',
        element: <ComponentName>,
        title: '<App Name>',
        icon: createElement(<CarbonIcon>),
        visible: true
    }
];

export default <routeFileName>;
```

Pick a Carbon icon from `@carbon/icons-react` that fits the feature. Common choices:

-   `Dashboard` — dashboards/analytics
-   `DataTable` — table/list views
-   `Settings` — settings/config pages
-   `UserMultiple` — user management
-   `LocationHeart` — location features
-   `Delivery` — shipment/logistics
-   `WifiController` — device/IoT
-   `ChartLine` — reports/charts
-   `Application` — generic app

### Step 4 — Register route in index

Edit: `packages/client/hc20/src/routes/index.ts`

Add the import and spread into the routes array:

```typescript
import <routeFileName> from './<routeFileName>';

const routes: RouteType[] = [
    ...homeRoutes,
    ...dashboardRoutes,
    ...shipmentRoutes,
    ...beeRoutes,
    ...assetRoutes,
    ...inventoryDashboardRoutes,
    ...<routeFileName>,           // ← add here
];
```

### Step 5 — (Optional) Add API config

If the module needs API endpoints, add them to `packages/client/hc20/src/configs/APIConfig.ts`:

```typescript
const API_PATH = {
    // ... existing paths
    <UPPER_SNAKE>: '/v2/<moduleName>',
};
```

### Step 6 — (Optional) Add to sidenav

If the module should appear in the HC20 sidebar navigation, add to the Operations array in
`packages/client/sidenav/src/routes.tsx`:

```typescript
{
    link: '/<routePath>',
    title: '<App Name>'
}
```

### Verification

After scaffolding, verify:

-   [ ] Module component exists at `modules/<moduleName>/<ComponentName>/index.tsx`
-   [ ] Route file exists at `routes/<routeFileName>.ts`
-   [ ] Route is imported and spread in `routes/index.ts`
-   [ ] `visible: true` is set if it should appear in the SpeedDial navigation
-   [ ] The route path follows pattern `hc20/<moduleName>`
-   [ ] Every page includes `<Breadcrumbs>` navigation at the top

---

## Workflow B: New Micro-Frontend App

Use when creating an entirely new top-level application (separate from HC20), like Studio or IntegrationHub.

### Step 1 — Derive identifiers

```
packageName   = kebab-case(appName)                   // e.g., "fleet-ops"
fullName      = "@roambee/client-" + packageName       // e.g., "@roambee/client-fleet-ops"
bundleName    = "roambee-client-" + packageName + ".js"
port          = next available (check existing: 3010-3021)
routePrefix   = "/" + packageName                      // e.g., "/fleet-ops"
```

### Step 2 — Scaffold package directory

Create at `packages/client/<packageName>/` — see [references/microfrontend-scaffold.md](references/microfrontend-scaffold.md) for all required files.

Required files:

```
packages/client/<packageName>/
├── package.json
├── tsconfig.json
├── webpack.config.js
├── postcss-remove-layer.cjs               # Strips @layer from Tailwind CSS (required for UI lib + GlobalSearch)
├── .eslintrc
├── .gitignore
├── .prettierignore
├── babel.config.json
├── jest.config.js
└── src/
    ├── roambee-client-<packageName>.tsx    # Single-SPA entry
    ├── root.component.tsx                  # Root wrapper
    ├── App.tsx                             # Main app component
    ├── App.scss                            # Styles
    ├── declarations.d.ts                   # Type declarations
    ├── configs/
    │   └── APIConfig.ts
    ├── routes/
    │   └── index.ts
    └── modules/                            # Feature modules go here
```

### Step 3 — Register in root shell

Edit `packages/client/root/src/microfrontend-layout.html` — add route:

```html
<route path="<packageName>">
	<application name="@roambee/client-sidenav"></application>
	<application name="<fullName>" loader="hexaLoader"></application>
</route>
```

### Step 4 — Add import map entry

Edit `packages/client/root/webpack.config.js` — add URL variable and import:

```javascript
// Add URL variable (after existing ones)
const <camelCase>Url = process.env.CLIENT_<UPPER_SNAKE>_URL
    || (isLocal ? 'http://localhost:<port>' : 'https://<packageName>.hive.roambee.com');

// Add to imports object
'<fullName>': `${<camelCase>Url}/${bundleName}`,
```

### Step 5 — Register in Landing Page app catalog

**MANDATORY — every new micro-frontend MUST be registered here or it will not appear in the Hive dashboard launcher.**

Edit `packages/client/landing/src/components/Home/index.tsx` — make **all four** of these changes:

#### 5a — Add to `STATIC_APP_METADATA`

```typescript
const STATIC_APP_METADATA: Record<string, { name: string; description: string }> = {
    // ... existing entries ...
    <packageName>: { name: '<App Name>', description: '<one-line description>' },
};
```

#### 5b — Add to the correct category array

Pick the most appropriate category array near the top of the file:

-   `PLATFORM_AI_APPS` — core platform tools (integrations, operations, data)
-   `INTERNAL_APPS` — internal/admin tooling
-   `SUPPORT_DOCS_APPS` — docs, APIs, status pages
-   `MOBILE_APPS` — iOS / Android apps

```typescript
const PLATFORM_AI_APPS = [...existing..., '<packageName>'];
```

#### 5c — Add route case in `getApplicationRoute()`

```typescript
case '<packageName>':
    return '/<packageName>';
```

#### 5d — Add icon case in `getApplicationImage()`

Pick a Carbon icon from `@carbon/icons-react` that suits the feature (already imported at the top of the file, or add the import):

```typescript
case '<packageName>':
    return <DataShare size={24} />;   // replace with best-fit icon
```

#### 5e — Add to static super-admin list

Inside the `if (hasAllAppsRole)` block, add to the matching `staticXxxApps` array:

```typescript
const staticPlatformAIApps = [
    // ... existing entries ...
    { app_code: '<packageName>', name: '<App Name>', description: '<description>' }
];
```

---

### Step 6 — Add to sidenav (optional)

If the app should appear in the HC20 sidebar navigation, add to the appropriate array in
`packages/client/sidenav/src/routes.tsx`:

```typescript
{
    link: '/<packageName>',
    title: '<App Name>'
}
```

---

### Step 7 — Update lerna.json

Verify `lerna.json` packages glob (`packages/client/*`) already covers the new package.

### Verification

-   [ ] Package directory created at `packages/client/<packageName>/`
-   [ ] Single-SPA lifecycle exports (bootstrap, mount, unmount) in entry file
-   [ ] `postcss-remove-layer.cjs` created at app root
-   [ ] `webpack.config.js` patches the `.css` rule with `postcss-loader` + `postcss-remove-layer`
-   [ ] `import '@decklar/ui-library/styles'` added once at the app root (`App.tsx`)
-   [ ] Route added to `microfrontend-layout.html`
-   [ ] Import map entry in root `webpack.config.js`
-   [ ] Port number doesn't conflict with existing apps
-   [ ] **Landing page: entry in `STATIC_APP_METADATA`**
-   [ ] **Landing page: `app_code` added to correct category array**
-   [ ] **Landing page: `getApplicationRoute()` case added**
-   [ ] **Landing page: `getApplicationImage()` case added**
-   [ ] **Landing page: entry in static super-admin list**
-   [ ] Sidenav entry added (if applicable)
-   [ ] `npm install` and `npm run start` work for the new package

---

## ⚠️ Known Build Errors & Fixes

These errors occur on **every new Single-SPA app** and must be resolved immediately after scaffolding.

---

### Error 1 — `Module not found: Can't resolve 'sass-loader'`

**Symptom:**
```
ERROR in ./src/App.scss
Module not found: Error: Can't resolve 'sass-loader'
```

**Cause:** `sass-loader` and `sass` are used in `webpack.config.js` for `.scss` files but are not included in `package.json` devDependencies by default.

**Fix:** Add both to `devDependencies` in `package.json`, then re-run `npm install --legacy-peer-deps`:

```json
"sass": "^1.69.0",
"sass-loader": "^13.2.0",
```

**Prevention:** The `package.json` template in `references/microfrontend-scaffold.md` already includes these. Always use that template.

---

### Error 2 — Asset / Entrypoint size limit warnings

**Symptom:**
```
ERROR
asset size limit: The following asset(s) exceed the recommended size limit (244 KiB).
  roambee-client-<app-name>.js (800+ KiB)
ERROR
entrypoint size limit: The following entrypoint(s) combined asset size exceeds the recommended limit (244 KiB).
```

**Cause:** Single-SPA bundles are large by design (they share runtime dependencies via import maps at runtime). Webpack's default `performance.hints: 'warning'` threshold is too low.

**Fix:** Set `performance.hints: false` in `webpack.config.js`:

```javascript
performance: {
    hints: false
}
```

**Prevention:** The `webpack.config.js` template in `references/microfrontend-scaffold.md` already has `hints: false`. Always use that template.

---

### Error 3 — `ERESOLVE unable to resolve dependency tree` (React peer deps)

**Symptom:**
```
npm ERR! ERESOLVE unable to resolve dependency tree
npm ERR! peer react@"^18.0.0 || ^19.0.0" from @decklar/ui-library
npm ERR! Found: react@"^17.0.2"
```

**Cause:** The scaffold template lists `react: "^17.0.2"` but `@decklar/ui-library` requires React 18+.

**Fix:** Use React 18 in `package.json`:

```json
"react": "^18.1.0",
"react-dom": "^18.1.0",
"single-spa-react": "^4.6.1"
```

And in devDependencies:
```json
"@types/react": "^18.0.12",
"@types/react-dom": "^18.0.5",
```

Then run: `npm install --legacy-peer-deps`

**Prevention:** The `package.json` template in `references/microfrontend-scaffold.md` already uses React 18. Always use that template.

---

### Error 4 — `notarget No matching version found for @decklar/ui-library@^0.3.0`

**Symptom:**
```
npm ERR! notarget No matching version found for @decklar/ui-library@^0.3.0
```

**Cause:** The published version on npm is `^0.0.1-alpha.3`, not `^0.3.0`.

**Fix:** Use the correct version in `package.json`:
```json
"@decklar/ui-library": "^0.0.1-alpha.3",
```

**Prevention:** Always verify with the monorepo root `package.json` — it is the source of truth for the correct `@decklar/ui-library` version.

---

## CSS Compatibility: @decklar/ui-library + Single-SPA Apps

> **Next.js apps are exempt** — `smartbee-ai` (Next.js) and `admin-panel` (Vite) manage PostCSS/Tailwind via their own standard configs and do NOT face this issue.

When a **Single-SPA microfrontend** uses `@decklar/ui-library`, a CSS cascade conflict must be resolved via `postcss-remove-layer.cjs`.

### The Problem

| System | CSS Behavior |
| --- | --- |
| `@decklar/ui-library` | Uses Tailwind v4 — all styles wrapped in `@layer` |
| `@roambee/client-styleguide` (GlobalSearch) | Injects element resets via `createGlobalStyle` — **unlayered** |

In the CSS cascade, **unlayered styles always beat `@layer`-ed styles**, regardless of specificity. So GlobalSearch's `button { background: transparent }` overrides Tailwind's `.rb-button` class completely.

### The Fix

`postcss-remove-layer.cjs` strips all `@layer { ... }` wrappers at build time. Both systems become unlayered and compete on specificity — where Tailwind class selectors (`.rb-button`) naturally beat element selectors (`button`).

**Every new Single-SPA app using `@decklar/ui-library` MUST include:**

1. `postcss-remove-layer.cjs` at the app root (see [references/microfrontend-scaffold.md](references/microfrontend-scaffold.md))
2. The `postcss-loader` patch in `webpack.config.js` that appends it to the default `.css` rule

**Loader chain for `.css` files after the fix:**

```
style-loader → css-loader → postcss-loader (with postcss-remove-layer)
```

### Additional CSS Fixes When Using GlobalSearch

If the app also renders `<GlobalSearch>` from `@roambee/client-styleguide`:

- Pass `skipGlobalStyle` prop — prevents aggressive element resets (`button`, `a`, `h1`–`h6`, `body`) from being injected
- Add `box-sizing: border-box` reset and `margin: 0` in `App.scss` to compensate for the skipped normalize

---

## RouteType Interface

Both HC20 modules and standalone apps use this shared interface:

```typescript
export interface RouteType {
	title: string;
	path: string;
	element?: React.ElementType;
	icon?: ReactNode;
	visible?: boolean;
	exact?: boolean;
	children?: RouteType[];
}
```

## Shared Imports Pattern

```typescript
// UI components — always use the UI Library (never styleguide)
import { DataTable, Button, Input, Select, Toast } from '@decklar/ui-library';
import '@decklar/ui-library/styles'; // once at app root

// @ts-ignore — required for cross-microfrontend imports
import { API, useAuthUser, setRoutes, EventEmitter, getAuthUser, generateQueryParams } from '@roambee/client-utility';
```

> **NEVER** import from `@roambee/client-styleguide` in new code. It is deprecated.

## Port Allocation (current)

| Port | App             |
| ---- | --------------- |
| 3010 | root            |
| 3011 | utility         |
| 3012 | styleguide      |
| 3013 | auth            |
| 3014 | landing         |
| 3015 | sidenav         |
| 3016 | hc20            |
| 3017 | studio          |
| 3018 | petnet (cosmos) |
| 3019 | resolve         |
| 3020 | integrationhub  |
| 3021 | ni (location)   |

Next available port: **3022+**
