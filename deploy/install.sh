#!/usr/bin/env bash
# ============================================================================
# KOReader Personal Patch — installer (Linux / macOS)
# ----------------------------------------------------------------------------
# Copies the patches, icons, and fonts from this repo into the given KOReader
# installation directory on a Kindle or a kobo or an emulator.
#
# Usage:
#   ./deploy/install.sh /path/to/device/koreader
#   ./deploy/install.sh             # defaults to common Kindle mount points
#
# Safety:
#   - Creates timestamped backups of any file it is about to overwrite under
#     $KOREADER/patches/.phill-backup/<timestamp>/
#   - Never touches files outside the listed destination subdirectories
# ============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Resolve target KOReader directory
TARGET="${1:-}"
if [[ -z "$TARGET" ]]; then
    for candidate in \
        "/Volumes/Kindle/koreader" \
        "/media/$USER/Kindle/koreader" \
        "/run/media/$USER/Kindle/koreader" \
        "/mnt/kindle/koreader"; do
        if [[ -d "$candidate" ]]; then
            TARGET="$candidate"
            echo "→ Auto-detected KOReader at: $TARGET"
            break
        fi
    done
fi

if [[ -z "$TARGET" ]]; then
    echo "Usage: $0 /path/to/device/koreader" >&2
    echo "(could not auto-detect a mounted Kindle)" >&2
    exit 1
fi

if [[ ! -d "$TARGET" ]]; then
    echo "Error: $TARGET is not a directory" >&2
    exit 1
fi

# Sanity-check: target should look like a KOReader install
if [[ ! -f "$TARGET/reader.lua" && ! -f "$TARGET/common.lua" && ! -d "$TARGET/frontend" ]]; then
    echo "Warning: $TARGET does not look like a KOReader install (no reader.lua / frontend/ found)." >&2
    read -r -p "Continue anyway? [y/N] " ans
    if [[ ! "$ans" =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

TS="$(date -u +%Y%m%dT%H%M%SZ)"
BACKUP_DIR="$TARGET/patches/.phill-backup/$TS"

# Return $2 with the $1 prefix stripped (plus leading slash)
relpath() {
    local base="$1" full="$2"
    # Strip trailing slash from base
    base="${base%/}"
    echo "${full#$base/}"
}

copy_with_backup() {
    local src="$1" dst="$2"
    local rel
    rel="$(relpath "$TARGET" "$dst")"
    if [[ -f "$dst" ]]; then
        mkdir -p "$(dirname "$BACKUP_DIR/$rel")"
        cp -p "$dst" "$BACKUP_DIR/$rel"
    fi
    mkdir -p "$(dirname "$dst")"
    cp -p "$src" "$dst"
    echo "  ✓ $rel"
}

echo
echo "KOReader Personal Patch installer"
echo "  repo:   $REPO_ROOT"
echo "  target: $TARGET"
echo "  backup: $BACKUP_DIR (will be created only if files are overwritten)"
echo

# 1. Patches
echo "Installing patches..."
mkdir -p "$TARGET/patches"
for f in "$REPO_ROOT"/patches/*.lua; do
    copy_with_backup "$f" "$TARGET/patches/$(basename "$f")"
done

# 2. Icons (flat)
echo "Installing icons..."
mkdir -p "$TARGET/icons"
shopt -s nullglob
for f in "$REPO_ROOT"/icons/*.svg; do
    copy_with_backup "$f" "$TARGET/icons/$(basename "$f")"
done

# 3. Icons (mdlight subdir)
if [[ -d "$REPO_ROOT/icons/mdlight" ]]; then
    echo "Installing mdlight icons..."
    mkdir -p "$TARGET/resources/icons/mdlight"
    for f in "$REPO_ROOT"/icons/mdlight/*.svg; do
        copy_with_backup "$f" "$TARGET/resources/icons/mdlight/$(basename "$f")"
    done
fi

# 4. Fonts
if [[ -d "$REPO_ROOT/fonts" ]]; then
    echo "Installing fonts..."
    for fontdir in "$REPO_ROOT"/fonts/*/; do
        [[ -d "$fontdir" ]] || continue
        name="$(basename "$fontdir")"
        mkdir -p "$TARGET/fonts/$name"
        for f in "$fontdir"/*.ttf "$fontdir"/*.otf "$fontdir"/*.txt; do
            [[ -f "$f" ]] || continue
            copy_with_backup "$f" "$TARGET/fonts/$name/$(basename "$f")"
        done
    done
fi
shopt -u nullglob

# 5. Warn about missing pieces
echo
echo "Sanity checks:"
for icon in rounded.corner.tl.svg rounded.corner.tr.svg rounded.corner.bl.svg rounded.corner.br.svg; do
    if [[ ! -f "$TARGET/icons/$icon" ]]; then
        echo "  ⚠ Missing $icon in device /icons/ — rounded-corner covers won't render."
        echo "     See icons_needed.md"
    fi
done
for icon in favorites.svg go_up.svg hero.svg history.svg last_document.svg; do
    if [[ ! -f "$TARGET/icons/$icon" ]]; then
        echo "  ⚠ Missing $icon — the minimalist top-bar won't render correctly."
        echo "     See icons_needed.md"
    fi
done
if [[ ! -d "$TARGET/fonts/montserratstatic" ]]; then
    echo "  ⚠ No montserratstatic font folder on device. 'Home' label will fall back to default."
    echo "     See fonts_needed.md"
fi

echo
echo "Done. Safely eject your Kindle, then open KOReader to pick up the changes."
echo "If anything looks wrong, run ./deploy/uninstall.sh \"$TARGET\" to restore backups."
