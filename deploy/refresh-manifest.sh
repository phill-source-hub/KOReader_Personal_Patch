#!/usr/bin/env bash
# ============================================================================
# Regenerate updates.json after editing any patch or icon in this repo.
# Run this before committing changes to be pushed to users.
# ============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

# md5sum on Linux, md5 -q on macOS
if command -v md5sum >/dev/null 2>&1; then
    MD5() { md5sum "$1" | awk '{print $1}'; }
elif command -v md5 >/dev/null 2>&1; then
    MD5() { md5 -q "$1"; }
else
    echo "Error: no md5sum or md5 found" >&2
    exit 1
fi

{
    echo "{"
    first=true
    # Include patches + bundled icons (but not the mdlight sub-icons, those are left
    # for manual sync since they're numerous).
    for f in patches/*.lua icons/*.svg; do
        [[ -f "$f" ]] || continue
        name="$(basename "$f")"
        hash="$(MD5 "$f")"
        if $first; then
            first=false
        else
            echo ","
        fi
        printf '  "%s": "%s"' "$name" "$hash"
    done
    echo
    echo "}"
} > updates.json

echo "Wrote updates.json:"
cat updates.json
