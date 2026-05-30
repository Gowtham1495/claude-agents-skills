---
name: liquibase
description: Generic Liquibase YAML migration patterns. Use when adding or changing database schema in any Spring Boot project. Covers the two-file rule, naming conventions, common operations, and the NOT NULL backfill pattern.
---

# Liquibase YAML Migrations

Read `CLAUDE.md` in the project root for:
- Current latest version number (so you know what `N+1` to use)
- Author name convention
- Master changelog file path
- Any project-specific gotchas

---

## The two-file rule — do both or the migration never runs

Every migration requires **two changes**. Missing either one means Liquibase silently skips the file.

1. **Create the migration file** at the changes directory (see CLAUDE.md for path)
2. **Register it** in the master changelog with an `include` entry

---

## File naming

`V{N}__{snake_case_description}.yaml`

- Double underscore between version and description
- All lowercase, underscores for spaces
- `.yaml` extension (not `.yml`, not `.xml`)

---

## File skeleton

```yaml
databaseChangeLog:
  - changeSet:
      id: V{N}-01
      author: <see CLAUDE.md>
      comment: <what this changeset does>
      changes:
        - <operation>: ...

  - changeSet:
      id: V{N}-02
      author: <see CLAUDE.md>
      comment: <what this changeset does>
      changes:
        - <operation>: ...
```

Changeset IDs must be globally unique across the entire changelog history — never reuse one. They are permanent once a changeset has run in any environment.

---

## Common operations

**Create table:**
```yaml
- createTable:
    tableName: my_table
    columns:
      - column:
          name: id
          type: VARCHAR(36)
          constraints:
            primaryKey: true
            nullable: false
      - column:
          name: created_at
          type: TIMESTAMP
          defaultValueComputed: CURRENT_TIMESTAMP
```

**Add column (nullable):**
```yaml
- addColumn:
    tableName: existing_table
    columns:
      - column:
          name: new_col
          type: VARCHAR(255)
```

**Add index:**
```yaml
- createIndex:
    tableName: my_table
    indexName: idx_my_table_col
    columns:
      - column:
          name: col_name
```

**Unique constraint:**
```yaml
- addUniqueConstraint:
    tableName: my_table
    columnNames: col_a, col_b
    constraintName: uq_my_table_col_a_col_b
```

**Raw SQL (data migration / seed):**
```yaml
- sql:
    sql: |
      UPDATE my_table SET status = 'ACTIVE' WHERE status IS NULL;
```

**Delete rows:**
```yaml
- delete:
    tableName: my_table
```

---

## NOT NULL on an existing table with data

Never add `nullable: false` directly to a column that already has rows — the DB will reject it.

**Safe pattern (three changesets):**
1. Add the column as nullable
2. Backfill existing rows with a `sql` changeset
3. Add the NOT NULL constraint

```yaml
- changeSet:
    id: V{N}-01
    comment: Add col (nullable first)
    changes:
      - addColumn:
          tableName: my_table
          columns:
            - column:
                name: new_col
                type: VARCHAR(36)

- changeSet:
    id: V{N}-02
    comment: Backfill new_col
    changes:
      - sql:
          sql: UPDATE my_table SET new_col = 'default' WHERE new_col IS NULL;

- changeSet:
    id: V{N}-03
    comment: Add NOT NULL constraint to new_col
    changes:
      - addNotNullConstraint:
          tableName: my_table
          columnName: new_col
          columnDataType: VARCHAR(36)
```

---

## Registering in the master changelog

Append at the bottom of the master file:

```yaml
  - include:
      file: db/changelog/changes/V{N}__{description}.yaml
```

The path starts with `db/` (relative to the classpath root `src/main/resources/`), not `src/`.

---

## Verification

Restart the application. Look for in the logs:

```
liquibase.util : Run:  2    ← number of new changesets executed
liquibase.util : Previously run: 63
```

If `Run: 0` after adding a migration → the file is not registered in the master changelog.

---

## Gotchas

- `includeAll` does not exist in many projects — use explicit `include` per file
- Editing a changeset after it has run causes a checksum mismatch error on next startup — create a new changeset instead
- Changesets run in the order they appear in the master file, then top-to-bottom within each file
- If changeset B depends on A, A must come first
