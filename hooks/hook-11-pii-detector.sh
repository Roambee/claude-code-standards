#!/usr/bin/env bash
# Hook 11: PII field detector

CONTENT="${ROAMBEE_FILE_CONTENT:-$(cat 2>/dev/null)}"

PII_FIELDS="email|phone|mobile|address|location|fullName|firstName|lastName|dateOfBirth|dob|ssn|nationalId|passportNumber|full_name|first_name|last_name|date_of_birth|national_id|passport_number"

FOUND=$(echo "$CONTENT" | grep -iE "(${PII_FIELDS})\s*[:=@]" | head -3)
if [ -n "$FOUND" ]; then
  echo "🔒 PII field detected. Before proceeding, confirm:"
  echo "  1. Is this field encrypted at rest?"
  echo "  2. Is it excluded from logs?"
  echo "  3. Does it comply with the data retention policy?"
  echo "  Matched: $(echo "$FOUND" | head -1 | sed 's/^[[:space:]]*//')"
fi
exit 0
