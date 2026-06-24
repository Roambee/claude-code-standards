#!/usr/bin/env bash
# Hook 5: Migration safety — hard block on destructive operations

COMMAND="${DECKLAR_BASH_COMMAND:-}"
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)

# Find the migration file most recently modified (likely the one being run)
MIGRATION_FILE=$(find "$REPO_ROOT" -name "*migration*.ts" -newer "$REPO_ROOT/package.json" 2>/dev/null | head -1)
[ -z "$MIGRATION_FILE" ] && exit 0

DANGEROUS=$(grep -iE '(DROP TABLE|DROP COLUMN|TRUNCATE|ALTER COLUMN)' "$MIGRATION_FILE" 2>/dev/null)
if [ -n "$DANGEROUS" ]; then
  echo "BLOCK: Destructive database operation detected in migration:"
  echo "$DANGEROUS" | head -5
  echo ""
  echo "Review the migration carefully. If intentional, confirm with the user before proceeding. Ensure a down() method exists to reverse this."
  exit 2
fi

exit 0
