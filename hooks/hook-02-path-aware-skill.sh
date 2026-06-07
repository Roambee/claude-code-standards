#!/usr/bin/env bash
# Hook 2: Path-aware skill reminder — context injection based on file path

FILE_PATH="${ROAMBEE_FILE_PATH:-}"

case "$FILE_PATH" in
  */src/components/*)
    echo "📌 Skill reminder: Load \`decklar-ui-library\` before writing this component. It covers required patterns, known bugs, and @decklar/ui-library usage."
    ;;
  */src/api/hooks/*|*/src/api/services/*)
    echo "📌 Skill reminder: Load \`decklar-api-integration\` before wiring this API. It covers Query Key Factory, React Query hooks, and URL-persisted filters."
    ;;
  */App.tsx)
    echo "📌 Skill reminder: Load \`decklar-header-integration\` before editing App.tsx. It covers GlobalSearchHeader integration."
    ;;
  */packages/client/*/src/index.*)
    echo "📌 Skill reminder: This looks like a new MFE entry point. Load \`decklar-app-scaffold\` or \`hive-app-creator\` before scaffolding."
    ;;
esac
exit 0
