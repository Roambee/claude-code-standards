# Navigation Components Guide

Guidelines for implementing navigation components (header, footer, side navigation) in Decklar applications.

## Overview

There are **two header systems** in the monorepo. Choose based on the app's UI stack:

| App type                                            | Header to use                                  | Import from                                       |
| --------------------------------------------------- | ---------------------------------------------- | ------------------------------------------------- |
| **New app using `@decklar/ui-library`**             | `GlobalSearchHeader` + `useGlobalSearchHeader` | `@decklar/ui-library` + `@roambee/client-utility` |
| **Existing app using `@roambee/client-styleguide`** | `GlobalSearch`                                 | `@roambee/client-styleguide`                      |

> **For new apps, always use Pattern 4 (GlobalSearchHeader).** Pattern 1/3 are for existing legacy apps only.

---

## Common Navigation Patterns

### Pattern 4: New UI Library Apps — GlobalSearchHeader (USE FOR ALL NEW APPS)

**Used by:** any new app using `@decklar/ui-library`  
**Header:** `GlobalSearchHeader` from `@decklar/ui-library`  
**Logic:** `useGlobalSearchHeader` from `@roambee/client-utility` — handles auth, accounts, apps, logout automatically.

> Full prop/hook API: see the `decklar-header-integration` skill.

```tsx
// App.tsx
import './App.scss';
import '@decklar/ui-library/styles';
import { GlobalSearchHeader, TooltipProvider } from '@decklar/ui-library';
// @ts-ignore
import { useGlobalSearchHeader } from '@roambee/client-utility';
import { useNavigate } from 'react-router-dom';
import AppLogo from './assets/images/logo.svg';

function App() {
	const navigate = useNavigate();

	const { authenticated, loading, userName, avatarFallback, accountLabel, accounts, onAccountSelect, onLogout, applications, customApps, getApplicationRoute, getApplicationImage, onNavigate, profileItems } = useGlobalSearchHeader({
		onNavigateToAuth: () => navigate('/auth')
	});

	if (loading) return <></>; // or your <Loader />
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
						logoAlt="Your App"
						logoHref="/"
						title="Your App Title"
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
				<section id="container-layout">{/* Your app content */}</section>
			</section>
		</TooltipProvider>
	);
}
```

**Key differences from old GlobalSearch:**

-   No manual `useEffect` to fetch accounts — `useGlobalSearchHeader` handles it
-   No manual `useState` for accounts/account — all returned from the hook
-   Auth guard handled via `authenticated` + `loading` from the hook (no `useAuthUser()` call needed)
-   Wrap in `<TooltipProvider>` — required by `@decklar/ui-library`
-   No `skipGlobalStyle` prop needed — `GlobalSearchHeader` has no injected CSS resets

---

### Pattern 1: Legacy Apps with GlobalSearch Header (existing apps only)

**Used by:** `studio`, `hc20`, `ni`, `landing`, `integrationhub`

**Components Required:**

-   **GlobalSearch** - Main header component with logo, user menu, account switcher

**Typical Implementation:**

> **CRITICAL:** Always pass `skipGlobalStyle` when the app uses `@decklar/ui-library`. Without it, GlobalSearch injects aggressive CSS resets via `createGlobalStyle` that override Tailwind/UI library styles.

```tsx
// App.tsx
import { GlobalSearch, Loader } from '@roambee/client-styleguide';
import { API, useAuthUser, EventEmitter } from '@roambee/client-utility';
import { useState, useEffect } from 'react';
import '@decklar/ui-library/styles';
import RoambeeLogo from './assets/images/logo.png';

function App() {
	const navigate = useNavigate();
	const { data: user, authenticated, loading } = useAuthUser();
	const [accounts, setAccounts] = useState([]);
	const [account, setAccount] = useState({ label: '', id: '' });

	const menuItems = [
		{
			lable: 'Logout', // Note: typo preserved for compatibility
			clickHandler: () => {
				API('POST', '/auth/logout', {}).then(() => {
					navigate('/auth');
				});
			}
		}
	];

	useEffect(() => {
		if (!loading && authenticated && user) {
			API('GET', '/accounts?quick_view=true&all=true')
				.then((result) => {
					if (result.rows && result.rows.length) {
						setAccounts(result.rows);
					}
					if (user?.account?.data) {
						setAccount({
							label: user.account.data.title,
							id: user.account.uuid
						});
					}
				})
				.catch((error) => {
					console.error('Error fetching accounts:', error);
					EventEmitter.emit('showSnackbar', {
						id: 'error',
						message: error?.message || 'Something went wrong!',
						variant: 'error',
						position: 'top-right'
					});
				});
		}
	}, [authenticated, loading, user]);

	return (
		<section id="main-layout">
			<section id="header">
				<GlobalSearch
					className="header"
					user={user}
					showLogo={true}
					logo={RoambeeLogo}
					showSearch={false}
					showNotification={false}
					title="Your App Title"
					menuItems={menuItems}
					accounts={accounts}
					account={account}
					skipGlobalStyle
				/>
			</section>
			<section id="container-layout">{/* Your app content */}</section>
		</section>
	);
}
```

### Pattern 2: Lightweight Application (No Header)

**Used by:** any app with minimal navigation, `auth`

**Components Required:**

-   None (custom headers if needed)

**Typical Implementation:**

```tsx
// App.tsx
import { Routes, Route } from 'react-router-dom';

export default function App() {
	return (
		<Routes>
			<Route path="/your-app/*" element={<YourComponent />} />
		</Routes>
	);
}
```

### Pattern 3: Application with Layout Wrapper

**Used by:** `integrationhub`

**Components Required:**

-   **GlobalSearch** (in Topbar component)
-   **Breadcrumb** (optional, for navigation context)

**Typical Implementation:**

```tsx
// pages/MainLayout.tsx
import { Outlet } from 'react-router-dom';
import { Breadcrumb } from '@roambee/client-styleguide';
import Topbar from './Topbar';

const MainLayout = () => {
	return (
		<section id="main-layout">
			<section id="header">
				<Topbar user={user} />
			</section>
			<section id="container-layout">
				<Breadcrumb
					links={[
						{ name: 'Home', value: '/integrationhub' },
						{ name: 'Current Page', value: '/integrationhub/page' }
					]}
				/>
				<Outlet />
			</section>
		</section>
	);
};

// pages/Topbar.tsx
import { GlobalSearch } from '@roambee/client-styleguide';
import { API } from '@roambee/client-utility';

const Topbar = ({ user }) => {
	const navigate = useNavigate();
	const [accounts, setAccounts] = useState([]);
	const [account, setAccount] = useState({ label: '', id: '' });

	const menuItems = [
		{
			lable: 'Logout',
			clickHandler: async () => {
				await API('POST', '/auth/logout', {});
				navigate('/auth');
			}
		}
	];

	return <GlobalSearch user={user} showSearch={false} showLogo={true} showNotification={false} title="Integration Hub" menuItems={menuItems} accounts={accounts} account={account} skipGlobalStyle />;
};
```

## GlobalSearch Component API

### Required Props

| Prop        | Type   | Description                                              |
| ----------- | ------ | -------------------------------------------------------- |
| `user`      | Object | Current user object from `useAuthUser()`                 |
| `menuItems` | Array  | Menu items for user dropdown (typically includes Logout) |

### Optional Props

| Prop               | Type             | Default | Description                                                                               |
| ------------------ | ---------------- | ------- | ----------------------------------------------------------------------------------------- |
| `className`        | string           | -       | CSS class name                                                                            |
| `showLogo`         | boolean          | false   | Show application logo                                                                     |
| `logo`             | string/Component | -       | Logo image source or component                                                            |
| `showSearch`       | boolean          | false   | Show global search bar                                                                    |
| `showNotification` | boolean          | false   | Show notification bell                                                                    |
| `title`            | string           | ''      | Application title/name                                                                    |
| `accounts`         | Array            | []      | List of accounts for account switcher                                                     |
| `account`          | Object           | {}      | Currently selected account `{ label, id }`                                                |
| `isBeta`           | boolean          | false   | Show beta badge                                                                           |
| `skipGlobalStyle`  | boolean          | false   | Skip injecting global CSS resets. **Must be `true` for apps using `@decklar/ui-library`** |

### MenuItem Structure

```typescript
interface MenuItem {
	lable: string; // Note: typo is in original component
	clickHandler: () => void;
}
```

## Side Navigation Integration

The side navigation is a separate microfrontend (`@roambee/client-sidenav`) mounted globally in the root config. Individual applications don't need to implement it directly.

**Side Navigation Interaction:**

```tsx
// Toggle side navigation
import { EventEmitter } from '@roambee/client-utility';

EventEmitter.emit('toggleSideNav', true); // Open
EventEmitter.emit('toggleSideNav', false); // Close

// Listen for side navigation state
EventEmitter.addListener('toggleSideNav', (isOpen) => {
	console.log('Side nav is:', isOpen ? 'open' : 'closed');
});
```

## Layout SCSS Structure

Common layout structure used across applications:

```scss
// App.scss
// Essential resets — layout-critical only.
// Element-level resets (button, a, h1-h6) are intentionally omitted
// so they don't conflict with @decklar/ui-library's Tailwind CSS.
*,
*::before,
*::after {
	box-sizing: border-box;
}

#main-layout {
	display: flex;
	flex-direction: column;
	height: 100vh;
	width: 100%;
	margin: 0;

	#header {
		flex-shrink: 0;
	}

	#container-layout {
		flex: 1;
		overflow-y: auto;
	}

	// For apps that integrate with side navigation
	&.sidenav-normal {
		margin-left: 240px;
	}

	&.sidenav-small {
		margin-left: 80px;
	}
}
```

## Decision Guide — which header to use?

| You are...                                         | Use                                                                                           |
| -------------------------------------------------- | --------------------------------------------------------------------------------------------- |
| Creating a **new** app with `@decklar/ui-library`  | Pattern 4 — `GlobalSearchHeader`                                                              |
| **Migrating** an existing styleguide app to new UI | Pattern 4 — `GlobalSearchHeader` (see `decklar-header-integration` skill for migration steps) |
| Maintaining an **existing** styleguide app         | Pattern 1 — `GlobalSearch` with `skipGlobalStyle`                                             |

## Best Practices

1. **New apps:** use `useGlobalSearchHeader` — no manual account/auth state needed
2. **Legacy apps:** always pass `skipGlobalStyle` to `GlobalSearch` when `@decklar/ui-library` is present
3. **Always wrap** new UI library apps in `<TooltipProvider>` from `@decklar/ui-library`
4. **Use consistent logo** — store in `src/assets/images/`
5. **Application title** should be descriptive and match branding
6. **Error handling** - emit snackbar events for API errors

## Common Utilities

### Authentication Check

```tsx
import { useAuthUser } from '@roambee/client-utility';

const { data: user, authenticated, loading } = useAuthUser();

if (loading) {
	return <Loader />;
}

if (!authenticated) {
	return <Navigate to="/auth" />;
}
```

### Account Fetching Pattern

```tsx
useEffect(() => {
	if (!loading && authenticated && user) {
		API('GET', '/accounts?quick_view=true&all=true')
			.then((result) => {
				if (result.rows?.length) {
					setAccounts(result.rows);
				}
				if (user?.account?.data) {
					setAccount({
						label: user.account.data.title,
						id: user.account.uuid
					});
				}
			})
			.catch(console.error);
	}
}, [authenticated, loading, user]);
```

## Footer Component

Currently, no standard footer component is used across applications. If needed, create custom footer within your app.

## Decision Guide

**Choose Pattern 1 (GlobalSearch Header) when:**

-   App needs user authentication
-   App requires account switching
-   App is a primary user-facing application
-   App needs consistent platform navigation

**Choose Pattern 2 (No Header) when:**

-   App is a utility or standalone tool
-   App has custom authentication flow
-   App is embedded in another context

**Choose Pattern 3 (Layout Wrapper) when:**

-   App has complex routing/navigation
-   App needs breadcrumbs
-   App requires nested layouts
-   App has multiple top-level sections
