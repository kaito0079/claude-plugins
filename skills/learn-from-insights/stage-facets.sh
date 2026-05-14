#!/bin/bash
# stage-facets.sh — Stage /insights per-session facets into /tmp/claude/ for the
# learn-from-insights skill to consume.
#
# Idempotency: clears the staging dir first so deleted source facets do not
# linger as stale entries in the staging copy.
set -euo pipefail

SRC="$HOME/.claude/usage-data/facets"
STAGE_DIR="/tmp/claude/insights-facets"

if [ ! -d "$SRC" ]; then
    echo "ERROR: $SRC does not exist." >&2
    echo "Run /insights first to generate per-session analysis." >&2
    exit 2
fi

# Count source facets; if zero, surface a clear message rather than copying nothing silently.
src_count=$(find "$SRC" -maxdepth 1 -name '*.json' -type f 2>/dev/null | wc -l | tr -d ' ')
if [ "$src_count" -eq 0 ]; then
    echo "ERROR: no facet files in $SRC." >&2
    echo "Run /insights first to generate per-session analysis." >&2
    exit 3
fi

rm -rf "$STAGE_DIR"
mkdir -p "$STAGE_DIR"

# cp -p preserves mtime so downstream tools can use it as recency signal.
cp -p "$SRC"/*.json "$STAGE_DIR"/

staged=$(find "$STAGE_DIR" -maxdepth 1 -name '*.json' -type f 2>/dev/null | wc -l | tr -d ' ')
echo "Staged $staged facets to $STAGE_DIR"
