---
name: feature-planning
description: Tech-agnostic planning checklist for new features or changes. Use before coding any non-trivial feature to clarify scope, data model, API surface, RBAC, and UI entry points.
---

# Feature Planning Checklist

Always read `CLAUDE.md` in the project root before filling in tech-specific details.

---

## 1. Data model

- Is a new table needed?
- Are new columns being added to an existing table?
- If yes to either → flag for a DB migration (check CLAUDE.md for migration tooling and current version)
- Does adding columns affect existing rows? (backfill required, NOT NULL risk?)

## 2. API surface

For each new or changed endpoint, note:
- HTTP method + path
- Request shape (body fields, query params)
- Response shape (new fields on existing record? New response type?)
- HTTP status codes for success and each error case
- Any existing endpoint being extended vs. a truly new one?

## 3. Security / RBAC

- Which roles are allowed to call each endpoint?
- Which roles can see vs. interact with the UI feature?
- Is a new permission/role needed, or do existing roles cover it?

## 4. UI entry points

- New route/page, or new tab/section on an existing page?
- New component, or extend an existing one?
- What data does the UI need to fetch? From which endpoints?
- Read-only for some roles, editable for others?

## 5. Risk assessment

- Does this change shared/critical tables (people, projects, teams)?
- Is there existing production data that a migration must not break?
- Are there downstream features that depend on the data shape being changed?

---

## Plan file template

```markdown
## Context
<Why this feature is being built. The problem it solves.>

## Scope
<API / UI / Full-stack. Which repos/directories are touched.>

## API Changes
- Endpoints: method, path, roles
- Request/response DTO changes
- Service logic: key validations, business rules

## UI Changes
- Components: new or extended, file paths
- Service updates: new signals, HTTP calls
- RBAC guards: which computed signal controls visibility/editability
- Template changes

## DB / Migration Changes
- Table/column changes
- Migration version (from CLAUDE.md)
- Data risk

## Verification
- Manual test steps (golden path + role restrictions)
- Playwright test file to create or extend
```
