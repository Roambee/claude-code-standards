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
