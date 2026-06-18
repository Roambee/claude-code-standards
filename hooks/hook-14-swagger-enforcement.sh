#!/usr/bin/env bash
# Hook 14: Swagger/OpenAPI enforcement — fires once per controller file per session

source "$HOME/roambee-claude/hooks/lib.sh"

# Dedup per file: each controller is warned at most once per session
FILE_KEY="hook-14-$(echo "${ROAMBEE_FILE_PATH:-unknown}" | tr '/: .' '____')"
told_this_session "$FILE_KEY" && exit 0

CONTENT="${ROAMBEE_FILE_CONTENT:-$(cat 2>/dev/null)}"

# Check for HTTP method decorators — exit silently if none
HAS_ENDPOINT=$(echo "$CONTENT" | grep -cE '@(Get|Post|Put|Patch|Delete)\(')
[ "$HAS_ENDPOINT" -eq 0 ] && exit 0

# Check for Swagger decorators
HAS_SWAGGER=$(echo "$CONTENT" | grep -cE '@Api(Operation|Response|Tags)\(')

if [ "$HAS_SWAGGER" -eq 0 ]; then
  echo "📋 New API endpoint(s) detected without Swagger documentation. Add:"
  echo "  @ApiTags('resource-name')       — on the controller class"
  echo "  @ApiOperation({ summary: '' })  — on each endpoint method"
  echo "  @ApiResponse({ status: 200 })   — on each endpoint method"
  echo "Undocumented endpoints accumulate quickly and break the API contract."
  mark_told "$FILE_KEY"
fi
exit 0
