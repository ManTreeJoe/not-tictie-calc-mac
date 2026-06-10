#!/usr/bin/env bash
#
# Generates TicTie-legend.js from the canonical, shared tickmark legend
# (Sources/TicTieCore/Resources/tickmark-legend.json) so the Acrobat plug-in
# uses exactly the same tickmarks as the standalone TicTie Mac app.
#
# Run this whenever you edit the legend JSON, then re-run install.sh.
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$SCRIPT_DIR/../Sources/TicTieCore/Resources/tickmark-legend.json"
OUT="$SCRIPT_DIR/TicTie-legend.js"

if [[ ! -f "$SRC" ]]; then
    echo "Canonical legend not found at: $SRC"
    exit 1
fi

{
    echo "/* AUTO-GENERATED from Sources/TicTieCore/Resources/tickmark-legend.json."
    echo "   Do not edit by hand — run AcrobatPlugin/generate-legend.sh instead. */"
    printf 'var TICTIE_LEGEND = '
    cat "$SRC"
    echo ';'
} > "$OUT"

echo "Wrote $OUT"
