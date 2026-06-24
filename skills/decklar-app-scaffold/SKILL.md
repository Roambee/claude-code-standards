---
name: decklar-app-scaffold
description: Create new single-spa microfrontend applications in the Decklar monorepo. Use this skill when the user says "create a new app" (or similar)—then automatically create folder structure, config files, source files, root registration, and run npm install / bootstrap. After scaffolding, direct the user to "set up shadcn" (decklar-shadcn-app) or "use styleguide" (decklar-component-builder) for automatic UI setup. Handles folder structure, configuration files, root registration, and import map setup.
---

# Decklar Application Scaffold

Create new single-spa microfrontend applications in the Decklar monorepo.

## New user: Create a new app with this skill

**Suggested prompt (user can say):**  
"Create a new app using the decklar-app-scaffold skill" or "Scaffold a new microfrontend app"

When the user asks to **create a new app** using this skill, you MUST:

1. **Scaffold the app automatically:** Create the folder structure, config files, and source files at `packages/client/{app-name}/` from the reference templates (no manual steps for the user).
2. **Register the app:** Add the route to `microfrontend-layout.html` and import map in root `webpack.config.js`.
3. **Run install:** Run `npm install` in the app directory and `npm run bootstrap` from the monorepo root.

**Then** tell the user they can choose UI stack:

-   **"Set up shadcn"** or **"Use decklar-shadcn-app"** → Use the `decklar-shadcn-app` skill to automatically init shadcn, apply Decklar theme, and install default components (button, card, dialog, input, table, badge, label, tabs, separator).
-   **"Use styleguide"** or **"Use decklar-component-builder"** → Ensure `@decklar/client-styleguide` is in `package.json`, run install, and use the `decklar-component-builder` skill for building UI with styleguide components.

Do not only give instructions—create the files and run the commands as part of the flow.

## Quick Start

1. Create folder structure at `packages/client/{app-name}/`
2. Add configuration files (see [references/config-templates.md](references/config-templates.md))
3. Add source files (see [references/source-templates.md](references/source-templates.md))
4. Register with root config (see [references/root-registration.md](references/root-registration.md))
5. Run `npm install --legacy-peer-deps` and `npm run bootstrap`

## Mandatory Defaults for Every New App

The following must be true for **every** scaffolded app — do not skip:

| Requirement                               | Detail                                                                                                                                                                                                                                                                                                                     |
| ----------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Header**                                | Always include a header in `App.tsx` — choose the correct pattern based on UI stack: **new `@decklar/ui-library` apps** use `GlobalSearchHeader` + `useGlobalSearchHeader` (see `decklar-header-integration` skill); **legacy/styleguide apps** use `GlobalSearch` from `@decklar/client-styleguide`. See source template. |
| **`@tanstack/react-query`**               | Always include in `dependencies` — required for API data fetching via React Query hooks. Wrap app in `QueryClientProvider` in `root.component.tsx`.                                                                                                                                                                        |
| **`zod` + `react-hook-form`**             | Always include in `dependencies` — required for `Form` + `Form*` components from `@decklar/ui-library`.                                                                                                                                                                                                                    |
| **`sass` + `sass-loader`**                | Always include in `devDependencies` — required for `.scss` imports.                                                                                                                                                                                                                                                        |
| **`performance.hints: false`**            | Always set in `webpack.config.js` — Single-SPA bundles exceed the default 244 KiB threshold by design.                                                                                                                                                                                                                     |
| **React 18**                              | Use `react@^18.1.0` — `@decklar/ui-library` requires React 18+.                                                                                                                                                                                                                                                            |
| **`@decklar/ui-library: ^0.0.1-alpha.3`** | This is the correct published version. Do not use `^0.3.0`.                                                                                                                                                                                                                                                                |

## Naming Convention

| Item       | Pattern                         | Example                     |
| ---------- | ------------------------------- | --------------------------- |
| Folder     | `{app-name}`                    | `my-app`                    |
| Package    | `@decklar/client-{app-name}`    | `@decklar/client-my-app`    |
| Entry file | `decklar-client-{app-name}.tsx` | `decklar-client-my-app.tsx` |
| Port       | Next available (3022+)          | `3022`                      |

## Required Folder Structure

```
packages/client/{app-name}/
├── .eslintrc
├── .gitignore
├── .prettierignore
├── babel.config.json
├── jest.config.js
├── package.json
├── postcss-remove-layer.cjs          # Strips @layer from Tailwind CSS (required for UI lib + GlobalSearch)
├── tsconfig.json
├── webpack.config.js
└── src/
    ├── decklar-client-{app-name}.tsx   # Single-spa entry
    ├── root.component.tsx               # Root component (QueryClientProvider + BrowserRouter)
    ├── App.tsx                          # Main app (header, routes, auth)
    ├── App.scss                         # Global styles
    ├── declarations.d.ts                # TS declarations
    ├── assets/                          # Static assets
    │   └── images/
    ├── api/                             # ALL API integration code
    │   ├── endpoints.ts                 # URL constants (BASE_URL + ENDPOINTS)
    │   ├── queryKeys.ts                 # React Query cache key factories
    │   ├── hooks/                       # All hooks: base query, filter state, page-level
    │   │   ├── useResource.ts           # Base query + mutation hooks
    │   │   ├── useResourceFilters.ts    # Filter state (useState only)
    │   │   └── useResourcePage.ts       # Page-level composed hook
    │   └── services/                    # Pure async API functions
    │       ├── resource.service.ts
    │       └── index.ts
    ├── components/                      # Feature components
    │   └── {Feature}/
    │       ├── index.ts                 # Re-exports
    │       ├── types.ts                 # TypeScript types/interfaces for this feature
    │       ├── constants.ts             # Static options, badge maps, enums
    │       └── components/
    │           ├── Home/index.tsx
    │           ├── Form/index.tsx
    │           └── Detail/index.tsx
    ├── routes/                          # Route definitions
    │   └── index.ts
    └── utils/                           # Pure validation/transform functions
        └── resource.validations.ts
```

## Reference Files

| Reference                                                       | When to use                                                                                                                       |
| --------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------- |
| [config-templates.md](references/config-templates.md)           | Creating package.json, webpack, tsconfig, babel, eslint, jest configs                                                             |
| [source-templates.md](references/source-templates.md)           | Creating entry point, root component, App.tsx                                                                                     |
| [navigation-components.md](references/navigation-components.md) | Adding header, footer, or side navigation — covers both old `GlobalSearch` (styleguide) and new `GlobalSearchHeader` (ui-library) |
| [root-registration.md](references/root-registration.md)         | Registering app in microfrontend-layout.html and import maps                                                                      |

## Post-Creation Checklist

-   [ ] All config files created from templates
-   [ ] `postcss-remove-layer.cjs` created (strips `@layer` from Tailwind CSS)
-   [ ] Source files created in `src/`
-   [ ] `QueryClientProvider` wrapping `BrowserRouter` in `root.component.tsx`
-   [ ] `import '@decklar/ui-library/styles'` added in `App.tsx`
-   [ ] `src/api/` folder created with `endpoints.ts`, `queryKeys.ts`, `services/`, `hooks/`
-   [ ] Every page includes `<Breadcrumbs>` navigation at the top (import `Breadcrumbs` + `BreadcrumbItem` from `@decklar/ui-library`)
-   [ ] `App.scss` includes `box-sizing: border-box` reset and `margin: 0` on `#main-layout`
-   [ ] Navigation components added (header/footer) if needed
-   [ ] Header added — `GlobalSearchHeader` + `useGlobalSearchHeader` for new UI library apps; `GlobalSearch` + `skipGlobalStyle` for legacy styleguide apps
-   [ ] Logo asset copied from an existing app (`packages/client/webhook/src/assets/images/Final_Logo_Formerly_Decklar-011.png`) into `src/assets/images/` — import as `.png`, not `.svg`
-   [ ] Route added to `microfrontend-layout.html` — **standard route ONLY (no sidenav)**
-   [ ] ❌ `@decklar/client-sidenav` NOT included in the route (sidenav is legacy-only; new apps use `GlobalSearchHeader` which renders its own top bar)
-   [ ] Import map URL added to root `webpack.config.js`
-   [ ] **Landing page registered** in `packages/client/landing/src/components/Home/index.tsx`:
    -   [ ] Entry added to `STATIC_APP_METADATA`
    -   [ ] `app_code` added to the correct category array (`PLATFORM_AI_APPS`, `INTERNAL_APPS`, etc.)
    -   [ ] Case added in `getApplicationRoute()` returning `'/<app-name>'`
    -   [ ] Case added in `getApplicationImage()` with a matching Carbon icon
    -   [ ] Entry added to the static super-admin list inside `if (hasAllAppsRole)` block
-   [ ] Sidenav entry added in `packages/client/sidenav/src/routes.tsx` (if applicable)
-   [ ] `npm install` completed in app directory
-   [ ] `npm run bootstrap` run from monorepo root
-   [ ] App starts successfully with `npm start`

## ⚠️ Known Build Errors & Fixes

These errors occur on **every new Single-SPA app** and must be resolved immediately after scaffolding.

---

### Error 1 — `Module not found: Can't resolve 'sass-loader'`

**Symptom:**

```
ERROR in ./src/App.scss
Module not found: Error: Can't resolve 'sass-loader'
```

**Cause:** `sass-loader` and `sass` are used in `webpack.config.js` for `.scss` files but may be missing from `package.json` devDependencies.

**Fix:** Ensure both are in `devDependencies`, then re-run `npm install --legacy-peer-deps`:

```json
"sass": "^1.69.0",
"sass-loader": "^13.2.0",
```

---

### Error 2 — Asset / Entrypoint size limit warnings

**Symptom:**

```
ERROR
asset size limit: The following asset(s) exceed the recommended size limit (244 KiB).
  decklar-client-<app-name>.js (800+ KiB)
ERROR
entrypoint size limit: The following entrypoint(s) combined asset size exceeds the recommended limit.
```

**Cause:** Single-SPA bundles are large by design. Webpack's default `performance.hints: 'warning'` threshold is too low for this architecture.

**Fix:** Set `performance.hints: false` in `webpack.config.js`:

```javascript
performance: {
	hints: false;
}
```

---

### Error 3 — `ERESOLVE unable to resolve dependency tree` (React peer deps)

**Symptom:**

```
npm ERR! ERESOLVE unable to resolve dependency tree
npm ERR! peer react@"^18.0.0 || ^19.0.0" from @decklar/ui-library
```

**Cause:** Template defaults to `react: "^17.0.2"` but `@decklar/ui-library` requires React 18+.

**Fix:** Use React 18 in `package.json`:

```json
"react": "^18.1.0",
"react-dom": "^18.1.0",
"single-spa-react": "^4.6.1",
"@types/react": "^18.0.12",
"@types/react-dom": "^18.0.5"
```

Then run: `npm install --legacy-peer-deps`

---

### Error 4 — `notarget No matching version found for @decklar/ui-library`

**Symptom:**

```
npm ERR! notarget No matching version found for @decklar/ui-library@^0.3.0
```

**Fix:** Use the correct version — always check the monorepo root `package.json` as the source of truth:

```json
"@decklar/ui-library": "^0.0.1-alpha.3",
```

---

## CSS Compatibility: @decklar/ui-library + GlobalSearch Header

When an app uses **both** `@decklar/ui-library` (Tailwind CSS v4) and `GlobalSearch` from `@decklar/client-styleguide`, there are two CSS conflicts that MUST be resolved:

### Problem 1: `@layer` cascade

`@decklar/ui-library/styles` is Tailwind CSS v4 wrapped in `@layer` declarations. `GlobalSearch` injects **unlayered** CSS resets via `createGlobalStyle`. In the CSS cascade, unlayered styles **always beat** `@layer`-ed styles — so GlobalSearch's `button { background: transparent }` overrides the UI library's `.rb-button` class.

**Fix:** `postcss-remove-layer.cjs` strips `@layer` wrappers at build time, letting both compete on specificity. Tailwind class selectors (`.rb-button`) naturally beat element selectors (`button`).

### Problem 2: GlobalSearch's `<GlobalStyle />` resets

`GlobalSearch` unconditionally renders `<GlobalStyle />` which injects `styled-normalize` + aggressive element resets (`button`, `a`, `h1`-`h6`, `body`) at runtime, overriding UI library styles.

**Fix:** Pass `skipGlobalStyle` prop to `<GlobalSearch>`. This skips the global reset injection.

### Problem 3: Missing layout resets

With `skipGlobalStyle`, the `box-sizing: border-box` and `body { margin: 0 }` resets are also lost, causing layout overflow and extra whitespace.

**Fix:** Add `box-sizing` reset and `margin: 0` in `App.scss` (see template).
