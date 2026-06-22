---
name: playwright-testing
description: >
  Guide for writing Playwright tests in the Roambee/Decklar monorepo. Covers
  project structure, spec conventions, page object model, auth patterns,
  selector preferences, Zephyr annotation, and cleanup. Use whenever writing
  a new spec file or page object in tests/apps/honeycomb-portal-ui-tests/.
argument-hint: ""
---

# /playwright-testing

Writing a Playwright test or page object for the Honeycomb Portal UI test suite.

**Announce at start:** "Loading playwright-testing. Applying Roambee test conventions."

---

## Project Layout

```
tests/apps/honeycomb-portal-ui-tests/
  playwright.config.ts       — stage-based browser config
  global-setup.ts            — env var validation (runs before all tests)
  config/test-config.ts      — shared timeouts and endpoint constants
  tests/                     — spec files (*.spec.ts)
  pages/                     — Page Object Model classes
  helpers/
    auth-helper.ts           — AuthHelper class (legacy; prefer LoginActionsPage)
    test-utils.ts            — TestUtils (fillInput, waitForPageLoad, etc.)
    csv-utils.ts / xlsx-utils.ts
```

---

## Spec File Conventions

### Structure template

```typescript
import { test, expect } from '@playwright/test';
import FooPage from '../pages/FooPage';
import LoginActionsPage from '../pages/LoginActionsPage';
import AccountPage from '../pages/AccountPage';

// All test data in one const at the top — never inline in steps
const testData = {
  automationUserAccount: 'AutomationUser',
  fooName: 'TestFoo',
  origin: 'Pune',
  destination: 'Mumbai',
};

test.describe('Feature Name', () => {
  // Zephyr annotation — always in beforeEach, not in the test body
  test.beforeEach(async ({}, testInfo) => {
    testInfo.annotations.push({
      type: 'zephyr',
      description: 'HCC-TXXX'   // Zephyr test case ID(s), comma-separated if multiple
    });
  });

  // Set timeout explicitly — default is 300s from config, override per describe if needed
  test.setTimeout(120000);

  // afterEach for cleanup — wrap in try/catch so a cleanup failure doesn't hide test failure
  test.afterEach(async ({ page }) => {
    try {
      // e.g. complete or delete the entity created in the test
    } catch (error) {
      console.log('Cleanup failed:', error);
    }
  });

  test('Test Case 1 - Short description matching Zephyr title', async ({ page }) => {
    const loginActions = new LoginActionsPage(page);
    const accountPage = new AccountPage(page);
    const fooPage = new FooPage(page);

    // Step 1: always login first
    await test.step('Login as Super User and verify user logged in', async () => {
      await loginActions.loginAsSuperUser();
      await loginActions.expectUserLoggedIn();
    });

    // Step 2: account selection (when multi-tenant context required)
    await test.step('Select Automation User Account', async () => {
      await accountPage.selectAccount(testData.automationUserAccount);
      await accountPage.expectAccountSelected(testData.automationUserAccount);
    });

    // Subsequent steps — each meaningful user action gets its own test.step
    await test.step('Description of action', async () => {
      await fooPage.doSomething(testData.fooName);
    });

    await test.step('Verify expected outcome', async () => {
      await fooPage.expectSomethingVisible(testData.fooName);
    });
  });
});
```

### Key rules

- **One spec file per feature/flow.** File name is kebab-case describing the flow: `assets-facilities.spec.ts`.
- **`testData` const at the top.** Never hardcode strings inside steps.
- **`test.step()` for every meaningful block.** Steps show in the HTML report and Zephyr evidence.
- **`test.setTimeout()` always explicit.** Long-running tests (GPS simulation, multi-shipment) use `3000000`.
- **Tag long-running tests** with `@longrun` in the describe name: `test.describe('@longrun Shipment with GPS simulation', ...)`.
- **`afterEach` cleanup wraps in try/catch.** A failing cleanup must not swallow the original test failure.
- **No bare `console.log` in steps** — move logging into page object methods. Reserve it for major phase markers.

---

## Page Object Model

### Class template

```typescript
import { expect, type Page, type Locator, test } from '@playwright/test';

class FooPage {
  private page: Page;

  constructor(page: Page) {
    this.page = page;
  }

  // ==================== LOCATOR GETTERS ====================

  get fooNameInput(): Locator {
    return this.page.locator("input[placeholder='Foo name']");
  }

  get saveButton(): Locator {
    return this.page.locator("//button[normalize-space(text())='Save']");
  }

  // Parameterised locator — method, not a getter
  getFooRow(name: string): Locator {
    return this.page.getByRole('row', { name: new RegExp(name, 'i') });
  }

  // ==================== ACTION METHODS ====================

  async createFoo(name: string): Promise<void> {
    await test.step(`Create foo: ${name}`, async () => {
      await expect(this.fooNameInput).toBeVisible({ timeout: 10000 });
      await this.fooNameInput.fill(name);
      await expect(this.saveButton).toBeVisible({ timeout: 10000 });
      await this.saveButton.click();
      await this.page.waitForLoadState('networkidle');
    });
  }

  // ==================== ASSERTION METHODS ====================

  async expectFooVisible(name: string): Promise<void> {
    await test.step(`Verify foo "${name}" visible`, async () => {
      await expect(this.getFooRow(name)).toBeVisible({ timeout: 15000 });
    });
  }
}

export default FooPage;
```

### Naming conventions

| Thing | Convention | Example |
|---|---|---|
| Class | `<Feature>Page` | `LocationPage`, `ShipmentsPage` |
| File | `<Feature>Page.ts` | `LocationPage.ts` |
| Locator getter | camelCase noun | `saveButton`, `fooNameInput` |
| Action method | verb + noun | `createLocation()`, `fillShipmentDetails()` |
| Assertion method | `expect` + noun + state | `expectFooVisible()`, `expectShipmentsTableStructure()` |
| Parameterised locator | `get<Thing>(param)` | `getLocationRow(name)` |

### Section dividers

Always separate locators, actions, and assertions with this exact comment:

```typescript
// ==================== LOCATOR GETTERS ====================
// ==================== ACTION METHODS ====================
// ==================== ASSERTION METHODS ====================
```

---

## Authentication

Always use `LoginActionsPage` (not `AuthHelper` — that's the older version).

```typescript
import LoginActionsPage from '../pages/LoginActionsPage';

const loginActions = new LoginActionsPage(page);

// Options:
await loginActions.loginAsSuperUser();       // SUPER_USER_EMAIL / SUPER_USER_PASSWORD
await loginActions.loginAsAdmin();           // ADMIN_EMAIL / ADMIN_PASSWORD
await loginActions.loginAsRoambeeAdmin();    // ROAMBEE_ADMIN_EMAIL / ROAMBEE_ADMIN_PASSWORD

// Always assert login after login call
await loginActions.expectUserLoggedIn();
```

`LoginActionsPage` handles the rebranding modal and agreement popover automatically — do not duplicate that logic in specs or other page objects.

---

## Selector Preferences

In order of preference:

1. **`getByRole()`** — most robust, use for standard HTML/ARIA elements
   ```typescript
   this.page.getByRole('button', { name: 'Save' })
   this.page.getByRole('row', { name: /shipment name/i })
   this.page.getByRole('textbox', { name: 'Search Account' })
   ```

2. **CSS attribute selector** — for Angular form controls and standard inputs
   ```typescript
   this.page.locator("input[placeholder='Location name']")
   this.page.locator("input[name='email']")
   this.page.locator("button[type='submit']")
   ```

3. **XPath with `normalize-space`** — for Clarity UI components where text matching is needed
   ```typescript
   this.page.locator("//button[normalize-space(text())='Save']")
   this.page.locator("//span[normalize-space(text())='Shipments']")
   ```

4. **XPath with attribute** — for Angular-specific attributes (`clrdropdowntoggle`, `formcontrolname`)
   ```typescript
   this.page.locator('//button[@clrdropdowntoggle]')
   this.page.locator("input[formcontrolname='address']")
   ```

5. **`:has-text()` combinator** — when role + text covers it
   ```typescript
   this.page.locator('button:has-text("Log in as")')
   ```

**Avoid:** index-based XPath like `(//button)[2]` — breaks when UI changes. Use `getByRole` with a name filter or scope the locator to its container row first.

---

## Waiting and Timing

```typescript
// Wait for page to settle after navigation
await this.page.waitForLoadState('networkidle');

// Wait for element before interacting — always use explicit timeout
await expect(this.saveButton).toBeVisible({ timeout: 10000 });
await expect(this.saveButton).toBeEnabled({ timeout: 10000 });

// Hard wait — use sparingly, only when polling an async backend or animation
await this.page.waitForTimeout(2000);

// After a form fill, give the app time to react before the next action
await this.page.waitForTimeout(2000);  // standard pause after fill

// Navigation
await this.page.goto('/shipments/all', { waitUntil: 'networkidle' });

// fillInput helper from test-utils handles wait + fill + validate in one call
import { fillInput } from '../helpers/test-utils';
await fillInput(page, this.fooNameInput, value);
```

Timeout values from `config/test-config.ts`:
- `ELEMENT_TIMEOUT`: 5000ms — quick UI interactions
- `NAVIGATION_TIMEOUT`: 10000ms — page transitions, modals loading
- `DEFAULT_TIMEOUT`: 30000ms — slower backend calls

---

## Zephyr Integration

Every `test.describe` block must annotate with a Zephyr test case ID:

```typescript
test.beforeEach(async ({}, testInfo) => {
  testInfo.annotations.push({
    type: 'zephyr',
    description: 'HCC-T86'         // single ID
    // description: 'HCC-T36, HCC-T37'  // multiple IDs, comma-separated
  });
});
```

The junit reporter in `playwright.config.ts` picks up these annotations for Zephyr evidence upload. Do not omit them — tests without Zephyr IDs cannot be linked to test management.

---

## Environment Variables

Required env vars (validated in `global-setup.ts`):

| Variable | Used for |
|---|---|
| `SUPER_USER_EMAIL` / `SUPER_USER_PASSWORD` | Super user login |
| `ADMIN_EMAIL` / `ADMIN_PASSWORD` | Admin user login |
| `ROAMBEE_ADMIN_EMAIL` / `ROAMBEE_ADMIN_PASSWORD` | Roambee admin login |
| `HIVE_USER_EMAIL` / `HIVE_USER_PASSWORD` | Hive portal login |
| `BASE_URL` | Target environment (default: `https://view-staging.decklar.com`) |
| `TEST_STAGE` | Controls browser matrix (`pr`, `full-regression`, `nightly`, `release`) |
| `GOOGLE_API_KEY` | GPS simulation in long-running shipment tests |

Never hardcode credentials. Read from `process.env` at the top of the page object or helper file, not inside methods.

---

## Running Tests

```bash
cd tests/apps/honeycomb-portal-ui-tests

# Run all tests (all browsers, no TEST_STAGE = default matrix)
npx playwright test

# Run a single spec
npx playwright test tests/location.spec.ts

# Run in headed mode for debugging
npx playwright test tests/location.spec.ts --headed

# Run with a specific stage (PR = Chromium only)
TEST_STAGE=pr npx playwright test

# Show HTML report
npx playwright show-report
```

---

## Common Patterns

### CRUD test structure (create → edit → delete in one test)

```typescript
test('Test Case 1 - CRUD for Foo', async ({ page }) => {
  // ...login and account selection...

  await test.step('Create foo', async () => {
    await fooPage.createFoo(testData.fooName);
    await fooPage.expectFooVisible(testData.fooName);
  });

  await test.step('Edit foo', async () => {
    await fooPage.editFoo(testData.fooName, testData.editedName);
    await fooPage.expectFooVisible(testData.editedName);
  });

  await test.step('Delete foo', async () => {
    await fooPage.deleteFoo(testData.editedName);
    await fooPage.expectFooNotVisible(testData.editedName);
  });
});
```

### Handling optional modals (rebranding popover, agreement dialog)

```typescript
// Pattern used in LoginActionsPage — use the same approach for any conditional UI
const modal = this.page.locator('.modal-content:has-text("Some modal title")');
if (await modal.isVisible().catch(() => false)) {
  await modal.locator('button:has-text("Continue")').click({ force: true });
  await expect(modal).toBeHidden({ timeout: 5000 });
}
```

### Scoping locators to a table row (avoid index selectors)

```typescript
// Find the row first, then scope actions to it
const row = this.page.getByRole('row', { name: new RegExp(entityName, 'i') });
await expect(row).toBeVisible({ timeout: 15000 });
await row.getByRole('button').first().click();       // action button in that row
```

### afterEach cleanup for entities created in the test

```typescript
test.afterEach(async ({ page }) => {
  try {
    await page.goto('/shipments/all?type=all');
    const shipmentsPage = new ShipmentsPage(page);
    await shipmentsPage.fillSearchShipmentNameInput(testData.shipmentName);
    await shipmentsPage.clickOnShipmentByName(testData.shipmentName);
    await shipmentsPage.completeShipment(testData.shipmentName);
  } catch (error) {
    console.log('afterEach cleanup failed:', error);
    // Do not rethrow — test failure is more important than cleanup failure
  }
});
```
