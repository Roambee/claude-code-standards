#!/usr/bin/env bash
# Hook 14: Swagger/OpenAPI enforcement

CONTENT="${ROAMBEE_FILE_CONTENT:-$(cat 2>/dev/null)}"

# Check for new HTTP method decorators
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
fi
exit 0
