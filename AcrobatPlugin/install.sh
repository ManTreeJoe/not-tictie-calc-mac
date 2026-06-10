#!/usr/bin/env bash
#
# Installs TicTie.js into Adobe Acrobat's user "JavaScripts" folder on macOS,
# so the "TicTie" menu appears under View the next time Acrobat starts.
#
# Usage:   ./install.sh            # install
#          ./install.sh --uninstall
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$SCRIPT_DIR/TicTie.js"
BASE="$HOME/Library/Application Support/Adobe/Acrobat"

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    grep '^#' "$0" | sed 's/^# \{0,1\}//'
    exit 0
fi

if [[ ! -d "$BASE" ]]; then
    echo "Could not find Acrobat support folder at:"
    echo "  $BASE"
    echo "Is Adobe Acrobat (Pro) installed and run at least once?"
    exit 1
fi

# Acrobat keeps per-version folders (DC, 2020, 24, 25, …). Install into each
# version that exists so it works regardless of which Acrobat you launch.
shopt -s nullglob
versions=("$BASE"/*/)
if [[ ${#versions[@]} -eq 0 ]]; then
    echo "No Acrobat version folders found under $BASE"
    exit 1
fi

installed=0
for vdir in "${versions[@]}"; do
    js_dir="${vdir}JavaScripts"
    dest="$js_dir/TicTie.js"
    if [[ "${1:-}" == "--uninstall" ]]; then
        if [[ -f "$dest" ]]; then
            rm -f "$dest"
            echo "Removed: $dest"
            installed=$((installed + 1))
        fi
    else
        mkdir -p "$js_dir"
        cp "$SRC" "$dest"
        echo "Installed: $dest"
        installed=$((installed + 1))
    fi
done

if [[ "${1:-}" == "--uninstall" ]]; then
    echo "Done. Removed from $installed location(s). Restart Acrobat."
else
    echo "Done. Installed to $installed location(s)."
    echo "Quit and reopen Adobe Acrobat, then look for View ▸ TicTie."
fi
