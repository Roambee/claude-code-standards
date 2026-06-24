# Source File Templates

Templates for the main source files in a new application.

Replace placeholders:

-   `{app-name}` - lowercase, hyphenated (e.g., `my-app`)
-   `{APP_NAME}` - readable name (e.g., `My App`)
-   `{APP_NAME_UPPER}` - uppercase constant (e.g., `MY_APP`)

> **Note:** For navigation components (header, footer, side navigation), see [navigation-components.md](navigation-components.md)

> **Logo asset:** Copy `Final_Logo_Formerly_Decklar-011.png` from any existing app (e.g., `packages/client/webhook/src/assets/images/`) into `src/assets/images/` of the new app. Do not reference a local `logo.svg` — it doesn't exist.

---

## Entry Point: decklar-client-{app-name}.tsx

The single-spa lifecycle entry point.

```tsx
import React from 'react';
import ReactDOM from 'react-dom';
import singleSpaReact from 'single-spa-react';
import Root from './root.component';

const lifecycles = singleSpaReact({
	React,
	ReactDOM,
	rootComponent: Root,
	errorBoundary() {
		return null;
	}
});

export const { bootstrap, mount, unmount } = lifecycles;
```

---

## Root Component: root.component.tsx

Wraps the app with providers and initializes services.

```tsx
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { BrowserRouter } from 'react-router-dom';
import { useEffect } from 'react';
import App from './App';
// @ts-ignore
import { initializeOpenObserve, SERVICES } from '@decklar/client-utility';

const queryClient = new QueryClient({
	defaultOptions: {
		queries: {
			staleTime: 30_000,
			gcTime: 5 * 60_000,
			refetchOnWindowFocus: false,
			retry: 1
		}
	}
});

export default function Root() {
  useEffect(() => {
    console.info('OpenObserve initialised for {APP_NAME}.');
    initializeOpenObserve(SERVICES.{APP_NAME_UPPER});
  }, []);

  return (
    <QueryClientProvider client={queryClient}>
      <BrowserRouter>
        <App />
      </BrowserRouter>
    </QueryClientProvider>
  );
}
```

---

## Main App: App.tsx

The main application component with routing.

**No-Header Template (special cases only — auth pages, embedded tools):**

```tsx
import { Routes, Route } from 'react-router-dom';

export default function App() {
	return (
		<Routes>
			<Route path="/{app-name}/*" element={<div>Welcome to {APP_NAME}</div>} />
		</Routes>
	);
}
```

> **Choose the correct header template based on the UI stack — see both options below.**
>
> -   **New `@decklar/ui-library` apps** → use the **GlobalSearchHeader template** (Pattern A below)
> -   **Legacy apps using `@decklar/client-styleguide`** → use the **GlobalSearch template** (Pattern B below)

---

### Pattern A — New `@decklar/ui-library` App (USE THIS FOR ALL NEW APPS)

Uses `GlobalSearchHeader` from `@decklar/ui-library` + `useGlobalSearchHeader` from `@decklar/client-utility`.  
No manual account fetching needed — the hook handles everything.

> Full prop reference and hook return values: see the `decklar-header-integration` skill.

```tsx
import './App.scss';
import '@decklar/ui-library/styles';
import { GlobalSearchHeader, TooltipProvider } from '@decklar/ui-library';
// @ts-ignore
import { useGlobalSearchHeader, setRoutes } from '@decklar/client-utility';
import { Suspense } from 'react';
import { Route, Routes, useNavigate } from 'react-router-dom';
import routes from './routes';
import AppLogo from './assets/images/Final_Logo_Formerly_Decklar-011.png';

function App(): JSX.Element {
	const navigate = useNavigate();

	setRoutes(routes);

	const { authenticated, loading, userName, avatarFallback, accountLabel, accounts, onAccountSelect, onLogout, applications, customApps, getApplicationRoute, getApplicationImage, onNavigate, profileItems } = useGlobalSearchHeader({
		onNavigateToAuth: () => navigate('/auth')
	});

	if (loading) return <></>; // or <Loader />
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
						logoAlt="{APP_NAME}"
						logoHref="/"
						title="{APP_NAME}"
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
				<section id="container-layout">
					<Suspense fallback={null}>
						<Routes>
							{routes.map((route, idx) => (
								<Route key={idx} path={route.path} element={<route.element />} />
							))}
						</Routes>
					</Suspense>
				</section>
			</section>
		</TooltipProvider>
	);
}

export default App;
```

---

### Pattern B — Legacy/Styleguide App (existing apps only)

Uses `GlobalSearch` from `@decklar/client-styleguide`. Only use for apps already on the old styleguide stack.  
**Do NOT use for new apps.** Always pass `skipGlobalStyle` — without it, GlobalSearch CSS resets override `@decklar/ui-library` Tailwind styles.

```tsx
import './App.scss';
import '@decklar/ui-library/styles';

// @ts-ignore
import { GlobalSearch } from '@decklar/client-styleguide';
// @ts-ignore
import { API, useAuthUser, setRoutes, EventEmitter } from '@decklar/client-utility';
import { Suspense, useEffect, useState } from 'react';
import { Route, Routes, useNavigate } from 'react-router-dom';
import routes from './routes';

function App(): JSX.Element {
	const navigate = useNavigate();
	const { data: user, authenticated, loading } = useAuthUser();
	const [accounts, setAccounts] = useState([]);
	const [account, setAccount] = useState({ label: '', id: '' });

	setRoutes(routes);

	const menuItems = [
		{
			lable: 'Logout',
			clickHandler: () => {
				API('POST', '/auth/logout', {}).then(() => {
					navigate('/auth');
				});
			}
		}
	];

	useEffect(() => {
		if (!loading) {
			if (!authenticated) {
				navigate('/auth');
				return;
			}
			if (authenticated && user) {
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
					.catch((error: Error) => {
						EventEmitter.emit('showSnackbar', {
							id: 'error',
							leftIcon: true,
							message: error?.message || 'Something went wrong!',
							variant: 'error',
							ariaLabel: 'close button',
							position: 'bottom-center'
						});
					});
			}
		}
	}, [authenticated, loading, user, navigate]);

	return (
		<section id="main-layout">
			{authenticated && (
				<>
					<section id="header">
						<GlobalSearch className="header" user={user} showLogo={false} showSearch={false} showNotification={false} title="{APP_NAME}" menuItems={menuItems} accounts={accounts} account={account} skipGlobalStyle />
					</section>
					<section id="container-layout">
						<Suspense fallback={null}>
							<Routes>
								{routes.map((route, idx) => (
									<Route key={idx} path={route.path} element={<route.element />} />
								))}
							</Routes>
						</Suspense>
					</section>
				</>
			)}
		</section>
	);
}

export default App;
```

> For more navigation patterns and detailed implementation guide, see [navigation-components.md](navigation-components.md)

---

## API Config: configs/APIConfig.ts

Centralized API path constants for the application.

```typescript
const API_PATH = {
	// Add your API paths here, e.g.:
	// ITEMS: '/v2/{app-name}',
	// ITEM_BY_ID: '/v2/{app-name}/:id'
};

export default API_PATH;
```

---

## Optional: App.scss

Global styles for the application.

**Basic Styles:**

```scss
// Global application styles
```

**With Header Layout:**

> **IMPORTANT:** The `box-sizing` reset and `margin: 0` are essential. Without them, browser defaults cause layout overflow and extra space — especially when `skipGlobalStyle` is used on GlobalSearch (which normally provided these resets).

```scss
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
