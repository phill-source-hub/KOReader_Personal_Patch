#!/usr/bin/env bash
# ============================================================================
# KOReader Personal Patch — uninstaller (Linux / macOS)
# ----------------------------------------------------------------------------
# Removes every file this repo installed, then restores any pre-existing files
# from the most recent backup created by install.sh.
#
# Usage:  ./deploy/uninstall.sh /path/to/device/koreader
# ============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

TARGET="${1:-}"
if [[ -z "$TARGET" ]]; then
    echo "Usage: $0 /path/to/device/koreader" >&2
    exit 1
fi
if [[ ! -d "$TARGET" ]]; then
    echo "Error: $TARGET is not a directory" >&2
    exit 1
fi

echo "KOReader Personal Patch uninstaller"
echo "  repo:   $REPO_ROOT"
echo "  target: $TARGET"
echo

# 1. Remove every patch this repo installed
echo "Removing patches..."
for f in "$REPO_ROOT"/patches/*.lua; do
    name="$(basename "$f")"
    target_file="$TARGET/patches/$name"
    if [[ -f "$target_file" ]]; then
        rm -f "$target_file"
        echo "  ✗ patches/$name"
    fi
done

# 2. Remove icons we installed (only the ones in our repo — won't touch foreign icons)
echo "Removing icons..."
shopt -s nullglob
for f in "$REPO_ROOT"/icons/*.svg; do
    name="$(basename "$f")"
    target_file="$TARGET/icons/$name"
    if [[ -f "$target_file" ]]; then
        rm -f "$target_file"
        echo "  ✗ icons/$name"
    fi
done
for f in "$REPO_ROOT"/icons/mdlight/*.svg; do
    [[ -f "$f" ]] || continue
    name="$(basename "$f")"
    # These live in /koreader/icons/ (the override layer), not in
    # /koreader/resources/icons/mdlight/ (the system layer).
    # Removing them causes KOReader to fall back to its stock icons.
    target_file="$TARGET/icons/$name"
    if [[ -f "$target_file" ]]; then
        rm -f "$target_file"
        echo "  ✗ icons/$name  (mdlight override)"
    fi
done

# 3. Remove any fonts we installed
echo "Removing fonts..."
for fontdir in "$REPO_ROOT"/fonts/*/; do
    [[ -d "$fontdir" ]] || continue
    name="$(basename "$fontdir")"
    if [[ -d "$TARGET/fonts/$name" ]]; then
        rm -rf "$TARGET/fonts/$name"
        echo "  ✗ fonts/$name/"
    fi
done
shopt -u nullglob

# 4. Restore most recent backup
BACKUP_ROOT="$TARGET/patches/.phill-backup"
if [[ -d "$BACKUP_ROOT" ]]; then
    # Find most recent backup dir
    LATEST="$(ls -1 "$BACKUP_ROOT" 2>/dev/null | sort | tail -n 1)"
    if [[ -n "$LATEST" && -d "$BACKUP_ROOT/$LATEST" ]]; then
        echo
        echo "Restoring pre-install backup from $LATEST..."
        ( cd "$BACKUP_ROOT/$LATEST" && find . -type f | while read -r rel; do
            rel="${rel#./}"
            target_file="$TARGET/$rel"
            mkdir -p "$(dirname "$target_file")"
            cp -p "$BACKUP_ROOT/$LATEST/$rel" "$target_file"
            echo "  ✓ restored $rel"
        done )
    fi
fi

echo
echo "Uninstall complete. Restart KOReader to pick up the changes."
