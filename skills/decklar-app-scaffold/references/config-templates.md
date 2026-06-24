# Configuration File Templates

Complete templates for all configuration files needed when scaffolding a new application.

Replace `{app-name}` with your application name (lowercase, hyphenated).
Replace `{PORT}` with the assigned port number.

---

## package.json

> **Dependency guidelines:**
>
> -   `@decklar/ui-library` — REQUIRED. All UI components come from here.
> -   `@carbon/icons-react` — REQUIRED. Used for icons.
> -   `zod` — Add when using `Form` + Zod validation from `@decklar/ui-library`.
> -   `@emotion/react`, `@emotion/styled`, `@mui/material` — Do NOT include. New apps use `@decklar/ui-library`, not MUI directly. These are dead weight.
> -   `@decklar/client-styleguide` — Do NOT add as a dependency. It is resolved as a single-spa external via the import map (shared across microfrontends).

```json
{
	"name": "@decklar/client-{app-name}",
	"version": "0.1.0",
	"private": true,
	"scripts": {
		"start": "webpack serve --port {PORT}",
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

---

## webpack.config.js

> **IMPORTANT:** This config includes the PostCSS `@layer` removal plugin required for `@decklar/ui-library` to work alongside `@decklar/client-styleguide`'s GlobalSearch header. See [postcss-remove-layer.cjs](#postcss-remove-layercjs) below.

```javascript
const webpack = require('webpack');
const { merge } = require('webpack-merge');
const singleSpaDefaults = require('webpack-config-single-spa-react-ts');
const removeLayerPlugin = require('./postcss-remove-layer.cjs');

module.exports = (webpackConfigEnv, argv) => {
	const defaultConfig = singleSpaDefaults({
		orgName: 'decklar',
		projectName: 'client-{app-name}',
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
	// (@layer-based) while @decklar/client-styleguide injects unlayered resets
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

> **Why this file exists:** `@decklar/ui-library` uses Tailwind CSS v4 which wraps all styles in `@layer` (base, components, utilities). The `GlobalSearch` header from `@decklar/client-styleguide` injects **unlayered** CSS resets at runtime via `createGlobalStyle`. In the CSS cascade, unlayered styles **always beat** `@layer`-ed styles. This plugin strips `@layer` wrappers so both compete on specificity instead — Tailwind class selectors (`.rb-button`) naturally beat GlobalStyle element selectors (`button`).

```javascript
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

---

## tsconfig.json

```json
{
	"extends": "ts-config-single-spa",
	"compilerOptions": {
		"jsx": "react-jsx",
		"declarationDir": "dist"
	},
	"files": ["src/decklar-client-{app-name}.tsx"],
	"include": ["src/**/*"],
	"exclude": ["src/**/*.test*"]
}
```

---

## babel.config.json

```json
{
	"presets": ["@babel/preset-env", ["@babel/preset-react", { "runtime": "automatic" }], "@babel/preset-typescript"],
	"plugins": [["@babel/plugin-transform-runtime", { "useESModules": true, "regenerator": false }]],
	"env": {
		"test": {
			"presets": [["@babel/preset-env", { "targets": "current node" }]]
		}
	}
}
```

---

## .eslintrc

```json
{
	"extends": ["ts-react-important-stuff", "plugin:prettier/recommended"],
	"parserOptions": {
		"project": "tsconfig.json"
	}
}
```

---

## .gitignore

```
node_modules
.DS_Store
dist
coverage
.cache
```

---

## .prettierignore

```
.gitignore
coverage
node_modules
dist
```

---

## jest.config.js

```javascript
const { createJestConfig } = require('../../jest.config.base');
module.exports = createJestConfig(__dirname);
```

---

## declarations.d.ts

```typescript
declare module '*.scss';
declare module '*.css';
declare module '*.png';
declare module '*.svg';
declare module '*.jpg';
```

declare module '\*.jpg';

```

```
