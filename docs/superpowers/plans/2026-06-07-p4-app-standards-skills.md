# Decklar Claude Plugin — P4: App Standards Skills

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans` to implement this plan task-by-task.

**Goal:** Migrate 5 existing Decklar skills into the plugin and write 4 new app-developer standards skills (`testing-standards`, `logging-standards`, `api-design`, `migration-standards`).

**Architecture:** All skills are markdown files. Migrated skills are copied from `~/Downloads/.claude/skills/` and restructured to follow the plugin's file layout. New skills are written from scratch using the design spec.

**Prerequisite:** P1 complete — plugin directory structure exists.

**Design spec reference:** App Developer Skills section of `2026-06-06-decklar-claude-standards-plugin-design.md`

---

## File Map

| Action | Path | Source |
|--------|------|--------|
| Migrate | `skills/decklar-ui-library/SKILL.md` | `~/Downloads/.claude/skills/decklar-ui-library/` |
| Migrate | `skills/decklar-api-integration/SKILL.md` | `~/Downloads/.claude/skills/decklar-api-integration/` |
| Migrate | `skills/decklar-app-scaffold/SKILL.md` | `~/Downloads/.claude/skills/decklar-app-scaffold/` |
| Migrate | `skills/decklar-header-integration/SKILL.md` | `~/Downloads/.claude/skills/decklar-header-integration/` |
| Migrate | `skills/hive-app-creator/SKILL.md` | `~/Downloads/.claude/skills/hive-app-creator/` |
| Create | `skills/testing-standards/testing-standards.md` | New |
| Create | `skills/logging-standards/logging-standards.md` | New |
| Create | `skills/api-design/api-design.md` | New |
| Create | `skills/migration-standards/migration-standards.md` | New |

---

## Task 1: Migrate Decklar Skills

**Files:** All 5 migrated skill directories

- [ ] **Step 1: Copy existing skill files**

```bash
# Create skill directories
mkdir -p skills/decklar-ui-library/assets skills/decklar-ui-library/references
mkdir -p skills/decklar-api-integration/assets skills/decklar-api-integration/references
mkdir -p skills/decklar-app-scaffold/references
mkdir -p skills/decklar-header-integration
mkdir -p skills/hive-app-creator/references

# Copy from existing local skills
cp ~/Downloads/.claude/skills/decklar-ui-library/SKILL.md skills/decklar-ui-library/
cp -r ~/Downloads/.claude/skills/decklar-ui-library/assets/ skills/decklar-ui-library/assets/ 2>/dev/null || true
cp -r ~/Downloads/.claude/skills/decklar-ui-library/references/ skills/decklar-ui-library/references/ 2>/dev/null || true

cp ~/Downloads/.claude/skills/decklar-api-integration/SKILL.md skills/decklar-api-integration/
cp -r ~/Downloads/.claude/skills/decklar-api-integration/assets/ skills/decklar-api-integration/assets/ 2>/dev/null || true
cp -r ~/Downloads/.claude/skills/decklar-api-integration/references/ skills/decklar-api-integration/references/ 2>/dev/null || true

cp ~/Downloads/.claude/skills/decklar-app-scaffold/SKILL.md skills/decklar-app-scaffold/
cp -r ~/Downloads/.claude/skills/decklar-app-scaffold/references/ skills/decklar-app-scaffold/references/ 2>/dev/null || true

cp ~/Downloads/.claude/skills/decklar-header-integration/SKILL.md skills/decklar-header-integration/

cp ~/Downloads/.claude/skills/hive-app-creator/SKILL.md skills/hive-app-creator/
cp -r ~/Downloads/.claude/skills/hive-app-creator/references/ skills/hive-app-creator/references/ 2>/dev/null || true
```

- [ ] **Step 2: Verify all SKILL.md files exist**

```bash
for skill in decklar-ui-library decklar-api-integration decklar-app-scaffold decklar-header-integration hive-app-creator; do
  test -f "skills/$skill/SKILL.md" && echo "✅ $skill" || echo "❌ $skill MISSING"
done
```

Expected: 5 ✅

- [ ] **Step 3: Commit migrated skills**

```bash
git add skills/decklar-*/
git add skills/hive-app-creator/
git commit -m "feat: migrate 5 Decklar skills into decklar-claude plugin"
```

---

## Task 2: `skills/testing-standards/testing-standards.md`

**Files:**
- Create: `skills/testing-standards/testing-standards.md`

- [ ] **Step 1: Create the file**

````markdown
# testing-standards

Use before writing any `*.test.ts`, `*.spec.ts`, or `test_*.py` file.

**Announce at start:** "Loading testing-standards to ensure test quality and consistency."

---

## Frontend Unit Tests (Jest + React Testing Library)

**File location:** Co-located with the component — `ComponentName.test.tsx` next to `ComponentName.tsx`.

**Cross-MFE mock pattern:**
```typescript
jest.mock('@decklar/client-utility', () => ({
  EventEmitter: {
    emit: jest.fn(),
    on: jest.fn(),
    off: jest.fn(),
  },
}));
```

**React Query hook test pattern:**
```typescript
import { renderHook, waitFor } from '@testing-library/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { useShipments } from './useShipments';

const createWrapper = () => {
  const queryClient = new QueryClient({
    defaultOptions: { queries: { retry: false } },
  });
  return ({ children }) => (
    <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
  );
};

it('fetches shipments', async () => {
  const { result } = renderHook(() => useShipments(), { wrapper: createWrapper() });
  await waitFor(() => expect(result.current.isSuccess).toBe(true));
  expect(result.current.data).toBeDefined();
});
```

**EventEmitter-driven test pattern:**
```typescript
import { EventEmitter } from '@decklar/client-utility';

it('emits showSnackbar on error', () => {
  render(<MyComponent />);
  fireEvent.click(screen.getByRole('button', { name: /submit/i }));
  expect(EventEmitter.emit).toHaveBeenCalledWith('showSnackbar', {
    message: expect.stringContaining('error'),
    severity: 'error',
  });
});
```

---

## Backend E2E Tests (NestJS)

**Rule:** Real DB connections only — never mock the database. Mocks mask migration failures.

**File location:** `test/feature-name.e2e-spec.ts` at package root.

**Test module setup:**
```typescript
import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import * as request from 'supertest';
import { AppModule } from '../src/app.module';

describe('ShipmentsController (e2e)', () => {
  let app: INestApplication;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();
    app = moduleFixture.createNestApplication();
    await app.init();
  });

  afterAll(async () => {
    await app.close();
  });

  it('GET /v1/shipments returns paginated list', () => {
    return request(app.getHttpServer())
      .get('/v1/shipments')
      .set('Authorization', `Bearer ${process.env.TEST_JWT}`)
      .expect(200)
      .expect(res => {
        expect(res.body.data).toBeInstanceOf(Array);
        expect(typeof res.body.total).toBe('number');
      });
  });
});
```

**Run command:**
```bash
npm run test:e2e
```

Requires the local DB to be running and migrations applied.

---

## Frontend Integration Tests (Playwright)

**File location:** `e2e/feature-name.spec.ts` at package root.

**Setup:**
```typescript
import { test, expect } from '@playwright/test';

test.describe('Shipment list', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('http://localhost:3000/shipments');
    // Wait for app to load
    await page.waitForSelector('[data-testid="shipment-table"]');
  });

  test('displays shipments with pagination', async ({ page }) => {
    const rows = page.locator('[data-testid="shipment-row"]');
    await expect(rows).toHaveCount(10);

    // Take screenshot for Jira evidence
    await page.screenshot({ path: 'playwright-report/screenshots/shipment-list.png', fullPage: false });

    // Verify pagination controls
    await expect(page.locator('[data-testid="pagination"]')).toBeVisible();
  });
});
```

**Run command:**
```bash
npx playwright test
```

Dev server must be running first. Screenshots saved to `playwright-report/screenshots/`.

**Screenshot → Jira:**
After tests pass, upload screenshots as Jira attachments:
```bash
curl -X POST \
  "https://$(python3 -c "import json,os; print(json.load(open(os.path.expanduser('~/.claude/decklar-config.json')))['jira']['domain'])")/rest/api/3/issue/${TICKET}/attachments" \
  -H "X-Atlassian-Token: no-check" \
  -H "Authorization: Bearer ${JIRA_TOKEN}" \
  -F "file=@playwright-report/screenshots/feature-name.png"
```

Then add a Jira comment via `mcp__claude_ai_Atlassian__addCommentToJiraIssue`:
> "✅ Feature verified via Playwright. [Describe what the screenshot shows]."

---

## Python AI Service Tests

**Unit tests** (pytest — mock all LLM calls):
```python
from unittest.mock import patch, MagicMock
import pytest

@patch('app.services.llm_service.openrouter_client')
def test_classify_shipment_status(mock_client):
    mock_client.complete.return_value = MagicMock(
        content='{"status": "delayed", "confidence": 0.92}'
    )
    result = classify_shipment_status("Package not arrived after 5 days")
    assert result['status'] == 'delayed'
    assert result['confidence'] > 0.9
```

**Integration tests** — connect to real services, run on demand only:
```bash
pytest tests/integration/ -m integration
```

Do not run integration tests in CI — they hit real APIs and cost money.
````

- [ ] **Step 2: Commit**

```bash
git add skills/testing-standards/
git commit -m "feat: add testing-standards skill"
```

---

## Task 3: `skills/logging-standards/logging-standards.md`

**Files:**
- Create: `skills/logging-standards/logging-standards.md`

- [ ] **Step 1: Create the file**

````markdown
# logging-standards

Use when adding any logging, error handling, or user-facing notifications.

**Announce at start:** "Loading logging-standards."

---

## NestJS Services

Use `Logger` from `@nestjs/common`. Never use `console.log`.

```typescript
import { Logger, Injectable } from '@nestjs/common';

@Injectable()
export class ShipmentService {
  private readonly logger = new Logger(ShipmentService.name);

  async createShipment(dto: CreateShipmentDto): Promise<Shipment> {
    this.logger.log(`Creating shipment for tracking: ${dto.trackingNumber}`);
    try {
      const result = await this.repository.save(dto);
      this.logger.log(`Shipment created: ${result.id}`);
      return result;
    } catch (error) {
      this.logger.error(`Failed to create shipment: ${error.message}`, error.stack);
      throw error;
    }
  }
}
```

---

## React Frontend

User-facing errors use `EventEmitter`, not `console.error`.

```typescript
import { EventEmitter } from '@decklar/client-utility';

// Error notification
EventEmitter.emit('showSnackbar', {
  message: 'Failed to load shipments. Please try again.',
  severity: 'error',
});

// Success notification
EventEmitter.emit('showSnackbar', {
  message: 'Shipment exported successfully.',
  severity: 'success',
});
```

Never show raw error messages from the API to the user. Map them to human-readable text.

---

## Python AI Services

Structured JSON logging. Every log entry must include `request_id`, `service`, `level`.

```python
import logging, json, sys

def get_logger(service_name: str):
    logger = logging.getLogger(service_name)
    handler = logging.StreamHandler(sys.stdout)
    handler.setFormatter(logging.Formatter('%(message)s'))
    logger.addHandler(handler)
    logger.setLevel(logging.INFO)
    return logger

logger = get_logger('shipment-classifier')

# Usage
logger.info(json.dumps({
    "level": "INFO",
    "service": "shipment-classifier",
    "request_id": request_id,
    "model": model_name,
    "tokens_in": response.usage.input_tokens,
    "tokens_out": response.usage.output_tokens,
    "latency_ms": latency,
    "event": "llm_call_complete"
}))
```

---

## Never Log

- Raw user input or full prompt content
- PII fields: email, phone, name, address, location, national ID
- Auth tokens, API keys, session tokens
- Full request/response bodies from external APIs (log metadata only)
````

- [ ] **Step 2: Commit**

```bash
git add skills/logging-standards/
git commit -m "feat: add logging-standards skill"
```

---

## Task 4: `skills/api-design/api-design.md`

**Files:**
- Create: `skills/api-design/api-design.md`

- [ ] **Step 1: Create the file**

````markdown
# api-design

Use when designing or reviewing a new API endpoint in NestJS.

**Announce at start:** "Loading api-design standards."

---

## URL Conventions

- Versioning: `/v1/` for stable, `/v2/` for current generation. New endpoints start at `/v1/`.
- Kebab-case: `/v1/shipment-events`, not `/v1/shipmentEvents`
- Plural nouns for collections: `/v1/shipments`, not `/v1/shipment`
- Nested resources for ownership: `/v1/shipments/:id/events`

## Response Format

Always use `ResponseHandlerService`. Never call `res.json()` directly.

```typescript
import { ResponseHandlerService } from '@decklar/platform-utility';

@Get()
async getShipments(@Query() query: GetShipmentsDto) {
  const result = await this.shipmentService.findAll(query);
  return this.responseHandler.success(result);
}
```

Paginated response shape:
```typescript
{
  data: Shipment[],
  total: number,
  page: number,
  pageSize: number
}
```

Error response shape (handled by global exception filter — do not construct manually):
```typescript
{
  statusCode: number,
  message: string,
  error: string
}
```

## Auth Headers

All endpoints (except public health checks) require `Authorization: Bearer <JWT>`. The JWT is validated by the Central Authorization Service middleware — do not implement auth logic in individual services.

## Swagger Documentation (Required)

Every endpoint must have:
```typescript
@ApiTags('shipments')
@Controller('v1/shipments')
export class ShipmentsController {

  @Get()
  @ApiOperation({ summary: 'List all shipments with pagination' })
  @ApiResponse({ status: 200, description: 'Paginated shipment list', type: PaginatedShipmentDto })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({ status: 403, description: 'Forbidden' })
  async getShipments() { ... }
}
```

## JSON Naming

Request and response bodies use camelCase:
```json
{ "trackingNumber": "RB12345", "estimatedDelivery": "2026-06-10" }
```

Never use snake_case in JSON bodies (TypeORM entity columns can be snake_case internally — use `@Column({ name: 'tracking_number' })` + a camelCase property name).
````

- [ ] **Step 2: Commit**

```bash
git add skills/api-design/
git commit -m "feat: add api-design skill"
```

---

## Task 5: `skills/migration-standards/migration-standards.md`

**Files:**
- Create: `skills/migration-standards/migration-standards.md`

- [ ] **Step 1: Create the file**

````markdown
# migration-standards

Use before writing any TypeORM migration file.

**Announce at start:** "Loading migration-standards. Read this fully before writing any migration."

---

## Naming

Format: `<timestamp>-<meaningful-description>.ts`

```
✅ 1717800000000-add-shipment-status-index.ts
✅ 1717800001000-backfill-tracking-number-format.ts
❌ 1717800000000-migration.ts
❌ 1717800000000-update.ts
```

Generate the timestamp:
```bash
date +%s%3N
```

## Always Write `down()`

Every migration must be fully reversible. The `down()` method must undo exactly what `up()` did.

```typescript
export class AddShipmentStatusIndex1717800000000 implements MigrationInterface {
  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`CREATE INDEX "IDX_shipment_status" ON "shipment" ("status")`);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP INDEX "IDX_shipment_status"`);
  }
}
```

If a rollback is genuinely impossible (data loss), add a comment at the top and confirm with the user before committing:
```typescript
// WARNING: This migration is irreversible — backfilled data cannot be restored.
// Confirmed by: Heet Shah on 2026-06-07
```

## Schema vs Data Migrations

Never mix them. Use separate files:

1. `1717800000000-add-normalised-phone-column.ts` — schema only (ADD COLUMN)
2. `1717800001000-backfill-normalised-phone.ts` — data only (UPDATE rows)
3. `1717800002000-drop-old-phone-column.ts` — schema cleanup (DROP COLUMN)

Running them in sequence is safe. Running them in one file risks timeouts on large tables.

## No Business Logic

Migrations must only use raw `QueryRunner` — never import from `src/`:

```typescript
// ✅ Correct
await queryRunner.query(`UPDATE "user" SET "status" = 'active' WHERE "status" IS NULL`);

// ❌ Wrong — UserService may be renamed or deleted; migration runs forever
import { UserService } from '../modules/user/user.service';
```

## Column Type Changes

Never change a column type in a single migration. Three-step pattern:

```typescript
// Migration 1: add new column
await queryRunner.addColumn('shipment', new TableColumn({ name: 'status_v2', type: 'varchar' }));

// Migration 2 (separate file): backfill
await queryRunner.query(`UPDATE "shipment" SET "status_v2" = "status"::varchar`);

// Migration 3 (separate file): drop old, rename new
await queryRunner.dropColumn('shipment', 'status');
await queryRunner.renameColumn('shipment', 'status_v2', 'status');
```

## Before Committing

```bash
# Run the migration
npm run migration:run

# Verify the DB state looks correct
# Then test the rollback
npm run migration:revert

# Verify the DB is back to its prior state
# Re-run to confirm idempotency
npm run migration:run
```

Only commit after both run and revert succeed cleanly.
````

- [ ] **Step 2: Commit**

```bash
git add skills/migration-standards/
git commit -m "feat: add migration-standards skill"
```

---

## Task 6: End-to-End Verification

- [ ] **Step 1: Verify all skill files exist**

```bash
for skill in decklar-ui-library decklar-api-integration decklar-app-scaffold \
             decklar-header-integration hive-app-creator \
             testing-standards logging-standards api-design migration-standards; do
  FILE=$(ls skills/$skill/*.md 2>/dev/null | head -1)
  [ -n "$FILE" ] && echo "✅ $skill" || echo "❌ $skill MISSING"
done
```

Expected: 9 ✅

- [ ] **Step 2: Verify Hook 2 references the right skill names**

```bash
grep -E "decklar-ui-library|decklar-api-integration|decklar-header-integration" \
  docs/hooks-settings-patch.json hooks/hook-02-path-aware-skill.sh
```

Expected: matches in both files.

- [ ] **Step 3: Final commit**

```bash
git status
git commit -m "chore: P4 complete — app standards skills implemented"
```
