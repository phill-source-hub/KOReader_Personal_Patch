# KOReader Personal Patch

An amalgamation of KOReader user-patches and customisations for a **Kindle Paperwhite (7th gen)** running **KOReader 2026.03** with the **ProjectTitle** plugin.

This repo takes cherry-picked patches from a handful of upstream authors and combines them with a small amount of custom glue so the whole suite installs, coexists, and auto-updates cleanly. All patches live in `koreader/patches/` as standard KOReader user-patches — there are no modifications to the KOReader source, no `.patch`/`.diff` files to apply, and no rebuild required.

> Credit where it's due: the vast majority of the Lua here was written by [SeriousHornet](https://github.com/SeriousHornet/KOReader.patches) (GPL-3.0) and [sebdelsol](https://github.com/sebdelsol/KOReader.patches) (MIT). I've only written two small glue patches (`2-minimalist-pt-tweaks.lua` and `2-z-finished-checkmark.lua`) and a sibling auto-updater.

---

## What this gives you

Visually, this combines three independent looks:

1. **The VOS "Visual Overhaul Suite"** — stretched 2:3 rounded covers, rounded folder covers with `.cover.jpg` support and folder-name centring, a rounded progress bar, and numbered series badges on series books.
2. **The r/koreader "minimalist" look** — no line under the top icons, no row dividers in the grid, no line above the footer, no cover borders.
3. **Finished-book decoration** — finished books get a small check icon in the bottom-right corner of the cover and the whole cover is dimmed to 50%.

And a few quality-of-life touches:

- **DPI-aware menus** so touch targets are comfortable on a 300-DPI Paperwhite.
- **Chapter tokens in the sleep screen** (`%C` for chapter title, `%P` for chapter percent).
- **Two independent auto-updaters** under *More tools* — one for sebdelsol's upstream, one for this repo.

---

## Quick install

1. Clone or download this repo.
2. Plug your Kindle in via USB.
3. Run the deploy script for your platform:
   - Linux/macOS: `./deploy/install.sh /path/to/kindle/koreader`
   - Windows: `./deploy/install.ps1 E:\koreader` (adjust drive letter)
4. Eject the Kindle. KOReader will pick everything up on next launch.
5. Recommended first-run steps inside KOReader:
   - *Top menu → ☰ → Extract and cache book information → Here and Under → Refresh* (so series metadata and covers are populated for the badges)
   - *Top menu → ☰ → More tools → Update phill-source-hub/KOReader_Personal_Patch* to verify the auto-updater works.

---

## Patch-by-patch breakdown

The `patches/` folder contains 13 `.lua` files. KOReader loads them in lexicographic order, which matters for these patches because many of them wrap `MosaicMenuItem:paintTo` and each wrapper captures the previous one as its "original". Ordering is controlled by filename prefix:

| Load order | File | Source | Role |
|---|---|---|---|
| (loaded on-demand) | `guard.lua` | sebdelsol | Helper — skips patches that need newer KOReader |
| 1st (`2--` prefix) | `2--disable-all-PT-widgets.lua` | SeriousHornet | **Prerequisite** — strips PT's default overlays so VOS has a clean canvas |
| 2nd | `2--stretched-rounded-covers.lua` | SeriousHornet | 2:3 stretched covers + SVG rounded corners |
| 3rd (`2-` prefix, alpha) | `2-menu-size.lua` | sebdelsol | DPI-aware menu sizing |
| 4th | `2-minimalist-pt-tweaks.lua` | **phill-source-hub** | Hides row dividers, footer separator, and title-bar underline |
| 5th | `2-new-progress-bar.lua` | SeriousHornet | Rounded progress bar (skips finished books automatically) |
| 6th | `2-rounded-folder-covers.lua` | SeriousHornet | Rounded folder covers, `.cover.jpg` support, file-count badge |
| 7th | `2-screensaver-chapter.lua` | sebdelsol | `%C` / `%P` tokens in sleep-screen message |
| 8th | `2-series-badge-numbered.lua` | SeriousHornet | Rounded `#N` badge on series books |
| 9th | `2-update-patches.lua` | sebdelsol | Auto-updater for sebdelsol's upstream |
| 10th | `2-update-phill-patches.lua` | **phill-source-hub** | Auto-updater for this repo |
| 11th (`2-z-` prefix) | `2-z-finished-checkmark.lua` | **phill-source-hub** | Check icon on finished books (loads after progress bar so it layers on top) |
| 12th (`20-` prefix) | `20-faded-finished-books.lua` | SeriousHornet | Dims finished covers to 50% |

### Why the odd prefixes?

KOReader sorts `--` before `-` before letters, and `20` comes after all `2-…` files. That's how the three sources originally authored their files, and it gives us the exact load order we need for everything to layer cleanly.

---

## Folder layout

```
KOReader_Personal_Patch/
├── README.md                       # this file
├── CHANGELOG.md                    # version history
├── VENDORED.md                     # third-party source, license, SHA mapping
├── updates.json                    # manifest of md5 hashes for auto-updater
├── patches/                        # → copies to /koreader/patches/
│   ├── guard.lua
│   ├── 2--disable-all-PT-widgets.lua
│   ├── 2--stretched-rounded-covers.lua
│   ├── 2-menu-size.lua
│   ├── 2-minimalist-pt-tweaks.lua
│   ├── 2-new-progress-bar.lua
│   ├── 2-rounded-folder-covers.lua
│   ├── 2-screensaver-chapter.lua
│   ├── 2-series-badge-numbered.lua
│   ├── 2-update-patches.lua
│   ├── 2-update-phill-patches.lua
│   ├── 2-z-finished-checkmark.lua
│   └── 20-faded-finished-books.lua
├── icons/                          # → copies to /koreader/icons/
│   ├── check.svg                   #   patch-specific icons (shipped)
│   ├── rounded.corner.*.svg        #   VOS rounded corners (you supply)
│   ├── favorites.svg, go_up.svg …  #   PT top-bar icons (you supply)
│   └── mdlight/                    # → ALSO copies to /koreader/icons/
│       └── *.svg                   #   stock-theme overrides (optional)
├── icons_needed.md                 # list of additional icons you must drop in
├── fonts_needed.md                 # list of fonts you must drop in
└── deploy/
    ├── install.sh                  # Linux/macOS deploy
    ├── install.ps1                 # Windows deploy
    └── uninstall.sh                # rollback
```

---

## Things you still need to supply

Two things are deliberately **not** shipped in this repo because of licensing and size:

1. **The rounded-corner SVGs and the minimalist top-icon SVGs**. See `icons_needed.md` for the full list and where to grab them.
2. **The Montserrat font family**. See `fonts_needed.md`.

The deploy script will warn you if any of these are missing from the staging folders at install time.

---

## Maintenance workflow

### Normal operation (you want to update everything)

Inside KOReader:

1. *Top menu → ☰ → More tools → Update sebdelsol/KOReader.patches* — updates sebdelsol-authored files
2. *Top menu → ☰ → More tools → Update phill-source-hub/KOReader_Personal_Patch* — updates everything in this repo

Both updaters show you a checkbox list before applying. New files are unchecked by default; files that have a newer md5 are checked.

### When you change a patch locally on the device

The updaters compare md5 hashes. If you've edited a patch on-device to tune values, and that patch is also in the upstream `updates.json`, the next update will offer to overwrite your local change. Either:

- Skip that file when the update prompt appears, or
- Pull your change back into this repo and publish a new `updates.json` (see below)

### When you want to publish a new version of this repo

1. Edit the patch file(s) in `patches/`
2. Recompute `updates.json` by running `./deploy/refresh-manifest.sh` (or by hand — it's just `md5sum` output)
3. Bump the version in `CHANGELOG.md`
4. Commit and push

On-device users will see the update next time they open *More tools → Update phill-source-hub/…*

### When KOReader or ProjectTitle updates

User-patches survive KOReader updates automatically (they live in `/koreader/patches/`, not in the KOReader install dir).

ProjectTitle updates *might* break things because many of these patches hook internals of `mosaicmenu.lua` / `covermenu.lua` / `ptutil.lua`. The most fragile patches are:

- `2-minimalist-pt-tweaks.lua` — depends on `ptutil.thinGrayLine`, `ptutil.thinBlackLine`, `ptutil.thinWhiteLine`, `ptutil.mediumBlackLine` existing with their current signatures
- `2-rounded-folder-covers.lua` — uses `debug.getupvalue` / `debug.setupvalue` against `MosaicMenuItem.update`'s closure, which is highly implementation-dependent

If things break after a PT update, the safest first step is to disable patches one by one (rename `.lua` → `.lua.disabled`) to isolate the cause.

---

## Known compatibility constraints

- Requires **ProjectTitle** to be active (not just installed). None of these patches will do anything useful with the stock CoverBrowser because the `2--disable-all-PT-widgets.lua` prerequisite only covers the PT widget set.
- Requires **KOReader ≥ 2025.04-107** for the auto-updater patches (enforced by `guard.lua`).
- Tested on **Kindle Paperwhite 7th gen (300 DPI)** — badge sizes and font constants may want tuning on other devices. All tunables are at the top of each patch.

---

## Licenses

- Third-party patches retain their original licenses (see `VENDORED.md`).
- The `2-minimalist-pt-tweaks.lua`, `2-z-finished-checkmark.lua`, and `2-update-phill-patches.lua` files are licensed MIT.
