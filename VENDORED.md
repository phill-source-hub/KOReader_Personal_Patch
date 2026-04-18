# Vendored third-party files

This repo bundles verbatim (or near-verbatim) copies of patches authored by others. This file maps each vendored file to its upstream source, license, and vendor date so future re-syncs are trivial.

## SeriousHornet — "Visual Overhaul Suite"

- **Repo:** https://github.com/SeriousHornet/KOReader.patches
- **License:** GPL-3.0
- **Vendored on:** 2026-04-17 (commit/SHA not pinned — grab current `main`)

| File | Upstream path |
|---|---|
| `patches/2--disable-all-PT-widgets.lua` | `2--disable-all-PT-widgets.lua` |
| `patches/2--stretched-rounded-covers.lua` | `2--stretched-rounded-covers.lua` |
| `patches/2-rounded-folder-covers.lua` | `2-rounded-folder-covers.lua` |
| `patches/2-new-progress-bar.lua` | `2-new-progress-bar.lua` |
| `patches/2-series-badge-numbered.lua` | `2-series-badge-numbered.lua` |
| `patches/20-faded-finished-books.lua` | `20-faded-finished-books.lua` |

Skipped from SeriousHornet's collection (with reasons):
- `2--disable-all-CB-widgets.lua` — we use ProjectTitle, not CoverBrowser
- `2---stretched-covers.lua` / `2--rounded-covers.lua` — we use the combined `2--stretched-rounded-covers.lua` variant
- `2-series-indicator.lua` — we chose `2-series-badge-numbered.lua` instead
- `2-new-status-icons.lua` — replaced by our own `2-z-finished-checkmark.lua`
- `2-pages-badge.lua`, `2-percent-badge.lua`, `2-new-collections-star.lua` — not wanted

## sebdelsol

- **Repo:** https://github.com/sebdelsol/KOReader.patches
- **License:** MIT
- **Vendored on:** 2026-04-17 (commit/SHA not pinned — grab current `main`)

| File | Upstream path |
|---|---|
| `patches/guard.lua` | `guard.lua` |
| `patches/2-menu-size.lua` | `2-menu-size.lua` |
| `patches/2-screensaver-chapter.lua` | `2-screensaver-chapter.lua` |
| `patches/2-update-patches.lua` | `2-update-patches.lua` |

Skipped from sebdelsol's collection:
- `2--ui-font.lua` — not using, Montserrat is only applied to the "Home" label via ProjectTitle, not system-wide
- `2-browser-folder-cover.lua` — redundant with SeriousHornet's `2-rounded-folder-covers.lua` which covers the `.cover.jpg` use case AND adds rounded corners
- `2-browser-hide-underline.lua`, `2-browser-up-folder.lua` — ProjectTitle handles these
- `2-change-status-bar-color.lua`, `2-statusbar-better-compact.lua`, `2-statusbar-cycle-presets.lua`, `2-statusbar-thin-chapter.lua` — not wanted (minimalist setup)
- `2-disable-top-menu-zones.lua` — not wanted
- `2-filemanager-titlebar.lua` — conflicts with ProjectTitle's title bar
- `2-reference-page-count.lua`, `2-screensaver-cover.lua` — not wanted

## Minimalist setup (Reddit u/——)

- **Source:** https://www.reddit.com/r/koreader/comments/1op2mrq/my_minimalistic_setup/
- **License:** not stated — treat as CC-BY for the intent, reimplemented independently

The original minimalist setup shipped as plugin-file drops (modified `mosaicmenu.lua` and `covermenu.lua` for `projecttitle.koplugin`) plus a `2-disable-fullyread-progressbars-2.lua` trophy patch. Those file drops are **not** used here. Instead:

- The "no row dividers / no footer line / no title-bar underline" behaviour is reimplemented as the proper user-patch `patches/2-minimalist-pt-tweaks.lua` so it survives ProjectTitle updates.
- The "finished books get a marker" behaviour is reimplemented as `patches/2-z-finished-checkmark.lua`, using a check icon rather than the original trophy, and hooking into the post-VOS paint chain.

## First-party (phill-source-hub)

- `patches/2-minimalist-pt-tweaks.lua` — MIT
- `patches/2-z-finished-checkmark.lua` — MIT
- `patches/2-update-phill-patches.lua` — MIT

---

## How to re-sync upstream

```bash
# In a scratch dir, grab the latest upstream files
cd /tmp && rm -rf sh-patches sd-patches
git clone --depth=1 https://github.com/SeriousHornet/KOReader.patches sh-patches
git clone --depth=1 https://github.com/sebdelsol/KOReader.patches sd-patches

# Diff against our vendored copies (bodies should match line-for-line except header comment blocks)
cd /path/to/KOReader_Personal_Patch
diff <(tail -n +8 patches/2--disable-all-PT-widgets.lua) /tmp/sh-patches/2--disable-all-PT-widgets.lua

# If upstream has changed, copy their body in, preserve our vendor header, and bump updates.json
```

Then run `./deploy/refresh-manifest.sh` to recompute md5 hashes.
