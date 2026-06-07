# Root Registration Guide

After creating a new application, it must be registered with the single-spa root config.

## Files to Update

1. `packages/client/root/src/microfrontend-layout.html` - Route registration
2. `packages/client/root/webpack.config.js` - Import map URLs

---

## 1. Update microfrontend-layout.html

Add a new route element in `packages/client/root/src/microfrontend-layout.html`.

### ✅ Standard Route — USE THIS FOR ALL NEW APPS

New apps use `GlobalSearchHeader` which renders its own top bar. **Never add sidenav to new apps.**

```html
<route path="{app-name}">
	<application name="@roambee/client-{app-name}" loader="hexaLoader"></application>
</route>
```

### ❌ Route with Sidenav — LEGACY ONLY (do NOT use for new apps)

Only applies to old apps (`integrationhub`, `container`) that were built before `GlobalSearchHeader` existed. Adding sidenav to a new app renders the old collapsed left-panel alongside the new header.

```html
<!-- LEGACY ONLY - DO NOT USE FOR NEW APPS -->
<route path="{app-name}">
	<application name="@roambee/client-sidenav"></application>
	<application name="@roambee/client-{app-name}" loader="hexaLoader"></application>
</route>
```

### Placement

Add the route before the `<route default>` element:

```html
<single-spa-router style="display: none">
	<main>
		<!-- Existing routes... -->

		<!-- ADD NEW ROUTE HERE -->
		<route path="{app-name}">
			<application name="@roambee/client-{app-name}" loader="hexaLoader"></application>
		</route>

		<route default>
			<application name="@roambee/client-landing" loader="hexaLoader"></application>
		</route>
	</main>
</single-spa-router>
```

---

## 2. Update webpack.config.js Import Map

In `packages/client/root/webpack.config.js`, add the URL variable and import map entry.

### Step 1: Add URL Variable

Add after the existing URL declarations (around line 20-30):

```javascript
const {appName}Url = process.env.CLIENT_{APP_NAME_UPPER}_URL || (isLocal ? 'http://localhost:{PORT}' : 'https://{app-name}.hive.roambee.com');
```

**Example:**

```javascript
const myAppUrl = process.env.CLIENT_MY_APP_URL || (isLocal ? 'http://localhost:3022' : 'https://my-app.hive.roambee.com');
```

### Step 2: Add Import Map Entry

Add to the `imports` object:

```javascript
const imports = {
	imports: {
		// Existing imports...
		'@roambee/client-{app-name}': `${appNameUrl}/roambee-client-{app-name}.js`
	}
};
```

**Example:**

```javascript
'@roambee/client-my-app': `${myAppUrl}/roambee-client-my-app.js`,
```

---

## Port Assignment

Assign the next available port. Current assignments:

| Application        | Port      |
| ------------------ | --------- |
| root               | 3010      |
| utility            | 3011      |
| styleguide         | 3012      |
| auth               | 3013      |
| landing            | 3014      |
| sidenav            | 3015      |
| hc20               | 3016      |
| studio             | 3017      |
| petnet             | 3018      |
| resolve            | 3019      |
| integrationhub     | 3020      |
| ni                 | 3021      |
| **Next available** | **3022+** |

---

## Verification

After registration:

1. Start the root config: `cd packages/client/root && npm start`
2. Start your new app: `cd packages/client/{app-name} && npm start`
3. Navigate to `http://localhost:3010/{app-name}` to verify
