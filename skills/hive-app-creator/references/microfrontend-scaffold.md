# Micro-Frontend Scaffold Reference

Complete file-by-file guide for creating a new Single-SPA micro-frontend app.

Replace all placeholders:

-   `__PKG_NAME__` → kebab-case (e.g., `fleet-ops`)
-   `__FULL_NAME__` → `@roambee/client-__PKG_NAME__`
-   `__BUNDLE__` → `roambee-client-__PKG_NAME__`
-   `__PORT__` → next available port (3022+)
-   `__TITLE__` → display title (e.g., "Fleet Ops")

---

## package.json

> **Dependency guidelines:**
>
> -   `@decklar/ui-library` — REQUIRED. All UI components come from here. Do NOT use MUI (`@mui/material`, `@emotion/react`, `@emotion/styled`) in new apps.
> -   `@carbon/icons-react` — REQUIRED. Used for icons.
> -   `@roambee/client-styleguide` — Do NOT add as a dependency. It is resolved as a single-spa external via the import map.

```json
{
	"name": "@roambee/client-__PKG_NAME__",
	"version": "0.1.0",
	"private": true,
	"scripts": {
		"start": "webpack serve --port __PORT__",
		"build": "concurrently npm:build:*",
		"test": "cross-env BABEL_ENV=test jest",
		"start:standalone": "webpack serve --env standalone",
		"build:webpack": "webpack --mode=production",
		"analyze": "webpack --mode=production --env analyze",
		"lint": "eslint src --ext js,ts,tsx",
		"format": "prettier --write .",
		"check-format": "prettier --check .",
		"watch-tests": "cross-env BABEL_ENV=test jest --watch",
		"coverage": "cross-env BABEL_ENV=test jest --coverage",
		"build:types": "tsc"
	},
	"dependencies": {
		"@carbon/icons-react": "^11.43.0",
		"@decklar/ui-library": "^0.0.1-alpha.3",
		"@tanstack/react-query": "^5.62.16",
		"process": "^0.11.10",
		"react": "^18.1.0",
		"react-dom": "^18.1.0",
		"react-hook-form": "^7.71.2",
		"react-router-dom": "^6.27.0",
		"single-spa": "^5.9.3",
		"single-spa-react": "^4.6.1",
		"zod": "^4.3.6"
	},
	"devDependencies": {
		"@babel/core": "^7.23.3",
		"@babel/eslint-parser": "^7.23.3",
		"@babel/plugin-transform-runtime": "^7.23.3",
		"@babel/preset-env": "^7.23.3",
		"@babel/preset-react": "^7.23.3",
		"@babel/preset-typescript": "^7.23.3",
		"@babel/runtime": "^7.23.3",
		"@testing-library/jest-dom": "^5.17.0",
		"@testing-library/react": "^12.1.5",
		"@types/jest": "^27.0.1",
		"@types/react": "^18.0.12",
		"@types/react-dom": "^18.0.5",
		"@types/systemjs": "^6.1.1",
		"@types/webpack-env": "^1.16.2",
		"babel-jest": "^27.5.1",
		"concurrently": "^6.2.1",
		"cross-env": "^7.0.3",
		"eslint": "^7.32.0",
		"eslint-config-prettier": "^8.3.0",
		"eslint-config-ts-react-important-stuff": "^3.0.0",
		"eslint-plugin-prettier": "^3.4.1",
		"identity-obj-proxy": "^3.0.0",
		"jest": "^27.5.1",
		"jest-cli": "^27.0.6",
		"postcss-loader": "^7.3.3",
		"prettier": "^2.3.2",
		"pretty-quick": "^3.1.1",
		"sass": "^1.69.0",
		"sass-loader": "^13.2.0",
		"ts-config-single-spa": "^3.0.0",
		"typescript": "^4.3.5",
		"webpack": "5.94.0",
		"webpack-cli": "^5.1.4",
		"webpack-config-single-spa-react-ts": "^4.0.0",
		"webpack-dev-server": "5.2.1",
		"webpack-merge": "^5.8.0"
	}
}
```

## tsconfig.json

```json
{
	"extends": "ts-config-single-spa",
	"compilerOptions": {
		"jsx": "react-jsx",
		"declarationDir": "dist"
	},
	"files": ["src/roambee-client-__PKG_NAME__.tsx"],
	"include": ["src/**/*"],
	"exclude": ["src/**/*.test*"]
}
```

## webpack.config.js

> **IMPORTANT:** This config includes the PostCSS `@layer` removal plugin required for `@decklar/ui-library` to work alongside `@roambee/client-styleguide`'s GlobalSearch header. See [postcss-remove-layer.cjs](#postcss-remove-layercjs) below.

```javascript
const webpack = require('webpack');
const { merge } = require('webpack-merge');
const singleSpaDefaults = require('webpack-config-single-spa-react-ts');
const removeLayerPlugin = require('./postcss-remove-layer.cjs');

module.exports = (webpackConfigEnv, argv) => {
	const defaultConfig = singleSpaDefaults({
		orgName: 'roambee',
		projectName: 'client-__PKG_NAME__',
		webpackConfigEnv,
		argv
	});

	const merged = merge(defaultConfig, {
		plugins: [
			new webpack.ProvidePlugin({
				process: 'process'
			}),
			new webpack.EnvironmentPlugin({
				// Add environment variables as needed
			})
		],
		module: {
			rules: [
				{
					test: /\.(s(a|c)ss)$/,
					use: ['style-loader', 'css-loader', 'sass-loader']
				},
				{
					test: /\.(png|svg|jpg|jpeg|gif|ogg|mp3|wav)$/i,
					type: 'asset/resource'
				}
			]
		},
		performance: {
			hints: false
		}
	});

	// Add postcss-loader to the default .css rule to strip @layer wrappers.
	// This fixes CSS cascade conflicts: @decklar/ui-library uses Tailwind v4
	// (@layer-based) while @roambee/client-styleguide injects unlayered resets
	// via styled-components' createGlobalStyle — unlayered always beats @layer.
	merged.module.rules.forEach((rule) => {
		if (rule.test && rule.test.toString() === '/\\.css$/i' && Array.isArray(rule.use)) {
			rule.use.push({
				loader: 'postcss-loader',
				options: {
					postcssOptions: {
						plugins: [removeLayerPlugin]
					}
				}
			});
		}
	});

	return merged;
};
```

---

## postcss-remove-layer.cjs

> **Why this file exists:** `@decklar/ui-library` uses Tailwind CSS v4 which wraps all styles in `@layer` (base, components, utilities). The `GlobalSearch` header from `@roambee/client-styleguide` injects **unlayered** CSS resets at runtime via `createGlobalStyle`. In the CSS cascade, unlayered styles **always beat** `@layer`-ed styles — so GlobalSearch's `button { background: transparent }` overrides the UI library's `.rb-button` class. This plugin strips `@layer` wrappers so both compete on specificity instead — Tailwind class selectors (`.rb-button`) naturally beat element selectors (`button`).
>
> **Note:** Next.js apps (e.g., `smartbee-ai`, `admin-panel` with Vite) do NOT need this file — they manage PostCSS and Tailwind via their own standard configs and don't share this cascade conflict.

```javascript
/**
 * PostCSS plugin to remove @layer wrappers from CSS.
 *
 * @decklar/ui-library uses Tailwind CSS v4 which wraps styles in @layer
 * (base, components, utilities). When mixed with @roambee/client-styleguide's
 * GlobalSearch, which injects unlayered CSS resets via styled-components'
 * createGlobalStyle, the unlayered resets always win in the CSS cascade
 * (unlayered > @layer). Removing @layer lets both compete on specificity,
 * where Tailwind's class selectors naturally beat GlobalStyle's element selectors.
 */
module.exports = () => ({
	postcssPlugin: 'postcss-remove-layer',
	AtRule: {
		layer(atRule) {
			atRule.replaceWith(atRule.nodes);
		}
	}
});
module.exports.postcss = true;
```

## src/roambee-client-**PKG_NAME**.tsx

```typescript
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

## src/root.component.tsx

```typescript
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { BrowserRouter } from 'react-router-dom';
import App from './App';

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
	return (
		<QueryClientProvider client={queryClient}>
			<BrowserRouter>
				<App />
			</BrowserRouter>
		</QueryClientProvider>
	);
}
```

## src/App.tsx

> **Default**: Every new app MUST include the `GlobalSearch` header so logged-in user details, account switcher, and logout are always visible. Replace `__TITLE__` with the app display name.
>
> **CRITICAL**: Always pass `skipGlobalStyle` to `GlobalSearch` when the app uses `@decklar/ui-library` — without it, GlobalSearch injects CSS resets that break Tailwind styles.

```typescript
import './App.scss';
import '@decklar/ui-library/styles';

// @ts-ignore
import { GlobalSearch } from '@roambee/client-styleguide';
// @ts-ignore
import { API, useAuthUser, setRoutes, EventEmitter } from '@roambee/client-utility';
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
						<GlobalSearch className="header" user={user} showLogo={false} showSearch={false} showNotification={false} title="__TITLE__" menuItems={menuItems} accounts={accounts} account={account} skipGlobalStyle />
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

## src/App.scss

```scss
#main-layout {
	display: flex;
	flex-direction: column;
	height: 100vh;

	#header {
		flex-shrink: 0;
	}

	#container-layout {
		flex: 1;
		overflow: auto;
		padding: 1rem;
	}
}
```

## src/configs/APIConfig.ts

```typescript
const API_PATH = {
	LOGOUT: '/auth/logout'
};

export { API_PATH };
```

## src/routes/index.ts

```typescript
import { lazy, type ReactNode } from 'react';

export interface RouteType {
	title: string;
	path: string;
	element?: React.ElementType;
	icon?: ReactNode;
	visible?: boolean;
	exact?: boolean;
	children?: RouteType[];
}

const Home = lazy(() => import('../modules/home/Home'));

const routes: RouteType[] = [
	{
		path: '__PKG_NAME__',
		element: Home,
		title: 'Home'
	}
];

export default routes;
```

## src/modules/home/Home/index.tsx

```typescript
// @ts-ignore
import { getAuthUser } from '@roambee/client-utility';

function Home() {
	const user = getAuthUser();

	return (
		<div>
			<h1>Welcome to __TITLE__</h1>
			<p>
				Hello, {user?.first_name} {user?.last_name}
			</p>
		</div>
	);
}

export default Home;
```

## src/declarations.d.ts

```typescript
declare module '*.png';
declare module '*.svg';
declare module '*.jpg';
declare module '*.jpeg';
declare module '*.gif';
declare module '*.scss';
```

---

## Root Shell Registration

### microfrontend-layout.html

Add inside `<main>`:

```html
<route path="__PKG_NAME__">
	<application name="@roambee/client-sidenav"></application>
	<application name="@roambee/client-__PKG_NAME__" loader="hexaLoader"></application>
</route>
```

### root/webpack.config.js

Add URL variable and import map entry:

```javascript
const __CAMEL__Url = process.env.CLIENT___UPPER___URL
    || (isLocal ? 'http://localhost:__PORT__' : 'https://__PKG_NAME__.hive.roambee.com');

// In imports object:
'@roambee/client-__PKG_NAME__': `${__CAMEL__Url}/roambee-client-__PKG_NAME__.js`,
```
