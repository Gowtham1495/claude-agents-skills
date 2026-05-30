---
name: playwright
description: Playwright E2E test patterns. Use when writing or updating browser tests. Covers auth token injection, API helpers, cleanup, selector strategy, RBAC testing, and wait patterns.
---

# Playwright Test Patterns

Read `CLAUDE.md` in the project root for:
- Fixture file location and available helper functions
- Available test roles and how to authenticate
- Dev server port and run command (`npm run test:e2e` or similar)

---

## Auth — always inject a token, never use the UI login form

Token injection is faster and more reliable than driving the login UI:

```typescript
// From the project fixture (check CLAUDE.md for path)
await loginViaApi(page, 'MANAGER');
// Injects JWT into localStorage, sets shared auth token for API helpers
```

After token injection, navigate to the feature:
```typescript
await page.goto('/team');
await page.waitForLoadState('networkidle');
```

---

## API helpers — create and clean up test data

Use typed fetch wrappers from the fixture file:

```typescript
const team = await apiPost<Team>('/teams', { name: `_test_${Date.now()}`, color: '#3B82F6' });
const items = await apiGet<Item[]>('/items');
await apiDelete(`/teams/${team.id}`);
```

---

## Test structure — describe / beforeEach / afterEach

```typescript
test.describe('Feature — CRUD', () => {
  let entityId: string;

  test.beforeEach(async ({ page }) => {
    await loginViaApi(page, 'MANAGER');
    // Create dependencies via API
  });

  test.afterEach(async () => {
    if (entityId) await apiDelete(`/entities/${entityId}`);
    entityId = '';
  });

  test('creates an entity', async ({ page }) => {
    await page.goto('/feature');
    await page.waitForLoadState('networkidle');
    // ... drive UI ...
    // ... capture created ID from API response or DOM ...
  });
});
```

---

## Waits

```typescript
// After any click that triggers a network request
await page.waitForLoadState('networkidle');

// Rarely needed — prefer networkidle
await page.waitForTimeout(300);

// Explicit element wait (use sparingly — networkidle is usually enough)
await expect(page.locator('.my-element')).toBeVisible();
```

---

## Selectors — component-scoped over generic CSS

```typescript
// Preferred: narrow to the component, then the element
page.locator('app-people-table button.action-btn', { hasText: 'Add Person' })
page.locator('app-person-editor input[placeholder="Full name"]')

// Avoid: overly broad selectors that can match unintended elements
page.locator('button', { hasText: 'Save' })   // too broad
```

---

## RBAC tests

Group all role-permission tests in `rbac.spec.ts`:

```typescript
test('ENGINEER sees read-only person view', async ({ page }) => {
  await loginViaApi(page, 'ENGINEER');
  await page.goto('/team');
  await page.locator('td.name-cell', { hasText: 'Alice' }).click();
  await expect(page.locator('app-person-editor h3')).toContainText('View Person');
  await expect(page.locator('app-person-editor input[placeholder="Full name"]')).toBeDisabled();
});

test('MANAGER sees editable person view', async ({ page }) => {
  await loginViaApi(page, 'MANAGER');
  await page.goto('/team');
  await page.locator('td.name-cell', { hasText: 'Alice' }).click();
  await expect(page.locator('app-person-editor h3')).toContainText('Edit Person');
  await expect(page.locator('app-person-editor input[placeholder="Full name"]')).toBeEnabled();
});
```

---

## File organization

- Extend existing `*.spec.ts` files that already cover the feature area
- Only create a new spec file for a genuinely new area with no coverage
- RBAC tests → `rbac.spec.ts`
- Feature CRUD tests → `<feature-name>.spec.ts` (e.g. `team-people.spec.ts`)

---

## Running tests

Check CLAUDE.md for the exact command. Typical:
```bash
npm run test:e2e
```

The `playwright.config.ts` usually auto-starts the dev server. If the server is already running, it will reuse it.
