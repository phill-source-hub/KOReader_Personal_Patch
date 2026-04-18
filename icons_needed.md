# Icons you need to supply

This repo ships exactly one icon: `icons/check.svg` (the finished-book marker).

Two more sets of icons are needed for the full visual experience. They aren't bundled because they come from other authors' repos with their own licenses.

## 1. Rounded-corner SVGs — required for VOS covers

**Needed by:** `2--stretched-rounded-covers.lua` and `2-rounded-folder-covers.lua`

**Source:** https://github.com/SeriousHornet/KOReader.patches/tree/main/icons%20(bw)

Download these four files (use the B&W variant since the Paperwhite is e-ink):

- `rounded.corner.tl.svg`
- `rounded.corner.tr.svg`
- `rounded.corner.bl.svg`
- `rounded.corner.br.svg`

Drop them into `icons/` in this repo, then recompute `updates.json` (see main README) before committing.

At deploy time they will end up in `/koreader/icons/` on the device.

## 2. ProjectTitle top-icon SVGs — required for minimalist look

**Needed by:** the ProjectTitle plugin's title bar (`covermenu.lua` references these by name: `favorites`, `go_up`, `hero`, `history`, `last_document`, `plus`).

**Source:** your existing minimalist setup bundle (you mentioned uploading them separately)

Files:

- `favorites.svg`
- `go_up.svg`
- `hero.svg`
- `history.svg`
- `last_document.svg`
- `plus.svg`

Drop them into `icons/` and the deploy script will copy them to `/koreader/icons/`.

## 3. mdlight icon overrides (optional)

**Purpose:** restyled versions of KOReader's built-in system icons (menus, dialogs, dogears, WiFi indicators, etc.) from the minimalist setup.

**Destination on device:** `/koreader/icons/` — the **override layer**, NOT `/koreader/resources/icons/mdlight/`.

KOReader ships a stock icon theme at `/koreader/resources/icons/mdlight/`. When the icon loader looks up, say, `appbar.settings.svg`, it checks `/koreader/icons/` **first** and only falls back to `/koreader/resources/icons/mdlight/` if the override isn't there. So installing to the override layer:

1. Leaves KOReader's stock icons untouched on disk.
2. Makes reversion trivial — delete the override files and the stock look is back.
3. Is also the [officially recommended](https://github.com/KukkiiNeko/koreader-user-patches-collection) approach: "Do not replace icons in `koreader/resources/icons/mdlight`. Those are the system icons, which you need as base. Add them in your `koreader/icons` folder to overwrite them."

### How to use

Drop the minimalist mdlight SVGs (all ~100 of them, or a subset you like) into `icons/mdlight/` in this repo. **The folder separation in the repo is purely organisational** — it keeps the minimalist overrides distinct from patch-specific icons like `check.svg`. The install script will install them all to the same destination on-device (`/koreader/icons/`) and will warn if any filename exists in both `icons/` and `icons/mdlight/`.

### Note on our patches

**None of our patches actually require any mdlight icon.** These overrides only affect the visual styling of KOReader's own built-in UI (menus, dialogs, dogears, etc.). If you skip this folder entirely, everything in the patch suite still works — you'll just have stock KOReader icons in menus and dialogs instead of the minimalist restyled versions.

---

## Summary of where icons end up on the device

| Source in repo | Destination on Kindle | Notes |
|---|---|---|
| `icons/check.svg` | `/koreader/icons/check.svg` | Used by `2-z-finished-checkmark.lua` |
| `icons/rounded.corner.*.svg` | `/koreader/icons/` | Used by 2 VOS patches |
| `icons/favorites.svg` et al | `/koreader/icons/` | Used by ProjectTitle's title bar |
| `icons/mdlight/*.svg` | `/koreader/icons/` (**override layer**) | Overrides stock mdlight theme; uninstall removes them → reverts to stock |
