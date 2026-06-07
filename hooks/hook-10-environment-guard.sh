#!/usr/bin/env bash
# Hook 10: Environment guard

echo "🌍 This command may target a non-local environment. Before proceeding, confirm:"
echo "  - Target environment: dev / staging / prod?"
echo "  - Is this the intended environment for this operation?"
exit 0
