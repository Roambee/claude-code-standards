---
name: decklar-header-integration
description: 'Use when adding, modifying, or wiring up the app header (GlobalSearchHeader) in any Decklar microfrontend. Covers the useGlobalSearchHeader hook from @decklar/client-utility, GlobalSearchHeader component from @decklar/ui-library, account switcher, app switcher, profile menu, logout, and navigation. Also use when migrating an app from the old GlobalSearch header to the new one.'
---

# Decklar Header Integration

How to add the new **GlobalSearchHeader** to any Decklar microfrontend app.

## Architecture Overview

```
@decklar/ui-library       →  GlobalSearchHeader  (presentational component)
@decklar/client-utility   →  useGlobalSearchHeader  (data/logic hook)
Your App                  →  wires hook output to component props
```

-   **`GlobalSearchHeader`** — from `@decklar/ui-library`. Renders the full header shell (logo, search, notifications, account switcher, app switcher, profile menu).
-   **`useGlobalSearchHeader`** — from `@decklar/client-utility` (`packages/client/utility/src/hook/useGlobalSearchHeader.tsx`). Bridge hook that fetches accounts, apps, custom AI apps, and builds all props for the header component.

## Required Dependencies

Ensure the app's `package.json` has:

```json
{
	"@decklar/ui-library": "^0.0.1-alpha.5",
	"@decklar/client-utility": "*"
}
```

## Step-by-Step Integration

### 1. Import

```tsx
import { GlobalSearchHeader, TooltipProvider } from '@decklar/ui-library';
import { useGlobalSearchHeader } from '@decklar/client-utility';
```

### 2. Call the Hook

Inside the root `App` component (or layout wrapper):

```tsx
const { authenticated, loading, userName, avatarFallback, accountLabel, accounts, onAccountSelect, onLogout, applications, customApps, getApplicationRoute, getApplicationImage, onNavigate, profileItems } = useGlobalSearchHeader({
	onNavigateToAuth: () => navigate('/auth'), // optional: override logout redirect
	llmApiUrl: process.env.CLIENT_LLM_API_URL // optional: custom API URL for AI apps
});
```

### 3. Render the Header

```tsx
return (
	<TooltipProvider>
		<section id="main-layout">
			<section id="header">
				<GlobalSearchHeader
					logoSrc={DecklarLogo}
					logoAlt="Decklar"
					logoHref="/"
					title="YOUR_APP_TITLE"
					userName={userName}
					avatarFallback={avatarFallback}
					showSearch={false}
					showNotification={false}
					accountLabel={accountLabel}
					accounts={accounts}
					onAccountSelect={onAccountSelect}
					onLogout={onLogout}
					applications={applications}
					customApps={customApps}
					getApplicationRoute={getApplicationRoute}
					getApplicationImage={getApplicationImage}
					onNavigate={onNavigate}
					profileItems={profileItems}
				/>
			</section>
			{/* App content */}
		</section>
	</TooltipProvider>
);
```

### 4. Auth Guard (Recommended Pattern)

```tsx
if (loading) return <Loader />;
if (!authenticated) {
	navigate('/auth');
	return <></>;
}
```

## Full Example (App.tsx)

```tsx
import { useNavigate } from 'react-router-dom';
import { GlobalSearchHeader, TooltipProvider } from '@decklar/ui-library';
import '@decklar/ui-library/styles';
import { useGlobalSearchHeader } from '@decklar/client-utility';
import AppLogo from './assets/logo.svg';

function App(): JSX.Element {
	const navigate = useNavigate();

	const { authenticated, loading, userName, avatarFallback, accountLabel, accounts, onAccountSelect, onLogout, applications, customApps, getApplicationRoute, getApplicationImage, onNavigate, profileItems } = useGlobalSearchHeader({
		onNavigateToAuth: () => navigate('/auth')
	});

	if (loading) return <Loader />;
	if (!authenticated) {
		navigate('/auth');
		return <></>;
	}

	return (
		<TooltipProvider>
			<section id="main-layout">
				<section id="header">
					<GlobalSearchHeader
						logoSrc={AppLogo}
						logoAlt="App Logo"
						logoHref="/"
						title="YOUR_APP_TITLE"
						userName={userName}
						avatarFallback={avatarFallback}
						showSearch={false}
						showNotification={false}
						accountLabel={accountLabel}
						accounts={accounts}
						onAccountSelect={onAccountSelect}
						onLogout={onLogout}
						applications={applications}
						customApps={customApps}
						getApplicationRoute={getApplicationRoute}
						getApplicationImage={getApplicationImage}
						onNavigate={onNavigate}
						profileItems={profileItems}
					/>
				</section>
				<main>{/* routes / content */}</main>
			</section>
		</TooltipProvider>
	);
}

export default App;
```

## Hook Return Values

| Property              | Type                  | Description                                 |
| --------------------- | --------------------- | ------------------------------------------- |
| `user`                | `object`              | Raw auth user object                        |
| `authenticated`       | `boolean`             | Whether user is logged in                   |
| `loading`             | `boolean`             | Auth loading state                          |
| `userName`            | `string`              | Display name of logged-in user              |
| `avatarFallback`      | `string`              | First letter of name (uppercase)            |
| `accountLabel`        | `string`              | Current account title                       |
| `accounts`            | `HeaderAccount[]`     | All accounts (with parentId hierarchy)      |
| `onAccountSelect`     | `(account) => void`   | Delegates to selected account, reloads page |
| `onLogout`            | `() => void`          | Logs out and redirects                      |
| `applications`        | `HeaderApp[]`         | Decklar + AI apps combined                  |
| `customApps`          | `HeaderApp[]`         | Custom AI Builder apps                      |
| `getApplicationRoute` | `(appCode) => string` | Returns URL for an app code                 |
| `getApplicationImage` | `(appCode) => string` | Returns icon/image for an app code          |
| `onNavigate`          | `(url, app) => void`  | Navigates to an app                         |
| `profileItems`        | `HeaderProfileItem[]` | Profile dropdown menu items                 |
| `rawAccounts`         | `RawAccount[]`        | Raw account data for advanced use           |

## TypeScript Interfaces

```tsx
// Available from @decklar/client-utility
export interface HeaderAccount {
	id: string;
	label: string;
	parentId?: string;
	onSelect?: () => void;
}

export interface HeaderProfileItem {
	id: string;
	label: string;
	disabled?: boolean;
	onSelect?: () => void;
	href?: string;
	icon?: React.ReactNode;
	showDividerAfter?: boolean;
}

export interface HeaderApp {
	id?: string | number;
	appCode: string;
	name: string;
	description?: string;
}
```

## GlobalSearchHeader Props Reference

| Prop                  | Type                  | Required | Default | Description                 |
| --------------------- | --------------------- | -------- | ------- | --------------------------- |
| `logoSrc`             | `string`              | yes      | —       | Logo image source           |
| `logoAlt`             | `string`              | yes      | —       | Logo alt text               |
| `logoHref`            | `string`              | no       | `"/"`   | Logo click destination      |
| `title`               | `string`              | yes      | —       | App name shown in header    |
| `userName`            | `string`              | yes      | —       | User display name           |
| `avatarFallback`      | `string`              | yes      | —       | Fallback text for avatar    |
| `showSearch`          | `boolean`             | no       | `true`  | Show search icon            |
| `showNotification`    | `boolean`             | no       | `true`  | Show notification icon      |
| `newNotification`     | `boolean`             | no       | `false` | Show notification badge dot |
| `accountLabel`        | `string`              | yes      | —       | Current account name        |
| `accounts`            | `HeaderAccount[]`     | yes      | —       | Account switcher list       |
| `onAccountSelect`     | `(account) => void`   | yes      | —       | Account switch handler      |
| `onLogout`            | `() => void`          | yes      | —       | Logout handler              |
| `applications`        | `HeaderApp[]`         | yes      | —       | Apps for app switcher       |
| `customApps`          | `HeaderApp[]`         | no       | `[]`    | Custom AI apps              |
| `getApplicationRoute` | `(appCode) => string` | yes      | —       | App URL resolver            |
| `getApplicationImage` | `(appCode) => string` | yes      | —       | App icon resolver           |
| `onNavigate`          | `(url, app) => void`  | yes      | —       | App navigation handler      |
| `profileItems`        | `HeaderProfileItem[]` | yes      | —       | Profile menu items          |
| `adminSettingsHref`   | `string`              | no       | —       | Admin settings link         |

## Migrating from Old GlobalSearch Header

If the app currently uses `GlobalSearch` from `@decklar/client-styleguide`:

1. **Remove** the old imports:

    ```tsx
    // ❌ Remove
    import { GlobalSearch } from '@decklar/client-styleguide';
    ```

2. **Add** new imports (see Step 1 above).

3. **Replace** the manual account/app fetching logic with `useGlobalSearchHeader()`. The hook handles all API calls, state management, and data transformation internally.

4. **Replace** the `<GlobalSearch ... />` JSX with `<GlobalSearchHeader ... />` using hook output (see Step 3 above).

5. **Wrap** the app in `<TooltipProvider>` (required by `@decklar/ui-library`).

## Key Files

| File                                                         | Purpose       |
| ------------------------------------------------------------ | ------------- |
| `packages/client/utility/src/hook/useGlobalSearchHeader.tsx` | Hook source   |
| `packages/client/utility/src/decklar-client-utility.tsx`     | Barrel export |

## AI App Codes

These app codes are classified as AI/Agentic apps and grouped separately in the app switcher:

```ts
const AI_APP_CODES = ['hc20', 'tote-retrieval', 'location', 'bee-guardian', 'mcp-playground', 'analysis-agent', 'report-customization'];
```

## Common Customizations

-   **Hide search/notifications**: Set `showSearch={false}` and `showNotification={false}`
-   **Custom profile items**: Override `profileItems` array from the hook with your own
-   **Admin settings link**: Pass `adminSettingsHref="/admin-settings"` directly to the component
-   **Custom logout redirect**: Pass `onNavigateToAuth` option to the hook
