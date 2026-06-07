#!/usr/bin/env bash
# Hook 4: Pre-commit quality gate

DIFF=$(git diff --cached 2>/dev/null)
VIOLATIONS=()

# console.log in non-test files
if echo "$DIFF" | grep -E '^\+.*console\.log\(' | grep -qvE '\.(test|spec)\.(ts|tsx|js)'; then
  VIOLATIONS+=("console.log() found in non-test file(s)")
fi

# debugger statements
if echo "$DIFF" | grep -qE '^\+.*\bdebugger\b'; then
  VIOLATIONS+=("debugger statement found")
fi

# Architecture-impacting changes without doc update
STAGED_FILES=$(git diff --cached --name-only)
ARCH_IMPACTING=$(echo "$STAGED_FILES" | grep -E '(controllers?|services?|modules?|routers?)/[^/]+\.(ts|py)$|^packages/[^/]+/package\.json$|main\.(ts|py)$|^App\.tsx$')
if [ -n "$ARCH_IMPACTING" ]; then
  DOC_UPDATED=$(echo "$STAGED_FILES" | grep -E '^(architecture\.md|README\.md)$')
  if [ -z "$DOC_UPDATED" ]; then
    echo "📝 Docs reminder: These changes may affect architecture.md or README.md. Review and update them if needed before committing:"
    echo "$ARCH_IMPACTING" | sed 's/^/  - /'
  fi
fi

if [ ${#VIOLATIONS[@]} -gt 0 ]; then
  echo "BLOCK: Pre-commit quality gate failed:"
  for v in "${VIOLATIONS[@]}"; do
    echo "  ❌ $v"
  done
  echo "Fix the above issues before committing."
  exit 2
fi

exit 0
