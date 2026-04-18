# Changelog

## [0.1.0] — 2026-04-17

Initial consolidation. All patches installed simultaneously for the first time on a Kindle Paperwhite (7th gen) running KOReader 2026.03 with ProjectTitle.

### Icon-install convention

`icons/mdlight/*.svg` in this repo is deployed to `/koreader/icons/` on the device (the **override layer**), NOT to `/koreader/resources/icons/mdlight/` (the system layer). This is per KOReader's recommended convention — the stock icon theme is never touched, so uninstalling cleanly reverts to stock.

The `icons/mdlight/` subfolder in the repo exists purely for organisational separation: it keeps the ~100 minimalist theme overrides distinct from patch-required icons like `check.svg`. On-device they all share the same destination.

### Added
- **Vendored from SeriousHornet/KOReader.patches** (GPL-3.0):
  - `2--disable-all-PT-widgets.lua`
  - `2--stretched-rounded-covers.lua`
  - `2-rounded-folder-covers.lua`
  - `2-new-progress-bar.lua`
  - `2-series-badge-numbered.lua`
  - `20-faded-finished-books.lua`
- **Vendored from sebdelsol/KOReader.patches** (MIT):
  - `guard.lua`
  - `2-menu-size.lua`
  - `2-screensaver-chapter.lua`
  - `2-update-patches.lua`
- **First-party** (MIT):
  - `2-minimalist-pt-tweaks.lua` — scoped replacement for the Reddit minimalist setup's plugin-file overrides
  - `2-z-finished-checkmark.lua` — rewrite of the minimalist trophy patch, now uses `check.svg` and coexists with the VOS progress bar
  - `2-update-phill-patches.lua` — sibling auto-updater for this repo
- `updates.json` manifest
- Deploy scripts for Linux/macOS/Windows
- Bundled `icons/check.svg`

### Known at release time
- Requires ProjectTitle active (not CoverBrowser)
- Requires KOReader ≥ 2025.04-107 for the auto-updater patches
- Rounded-corner SVGs and minimalist top-icon SVGs must be supplied separately (see `icons_needed.md`)
- Montserrat font family must be supplied separately (see `fonts_needed.md`)
