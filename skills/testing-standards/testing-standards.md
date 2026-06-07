# testing-standards

Use before writing any `*.test.ts`, `*.spec.ts`, or `test_*.py` file.

**Announce at start:** "Loading testing-standards to ensure test quality and consistency."

---

## Frontend Unit Tests (Jest + React Testing Library)

**File location:** Co-located with the component — `ComponentName.test.tsx` next to `ComponentName.tsx`.

**Cross-MFE mock pattern:**
```typescript
jest.mock('@roambee/client-utility', () => ({
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
import { EventEmitter } from '@roambee/client-utility';

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
  "https://$(python3 -c "import json,os; print(json.load(open(os.path.expanduser('~/.claude/roambee-config.json')))['jira']['domain'])")/rest/api/3/issue/${TICKET}/attachments" \
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
