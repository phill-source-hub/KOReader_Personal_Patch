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

## 3. mdlight material-design icons (optional)

**Needed by:** various ProjectTitle menu and dialog icons

**Destination:** `/koreader/resources/icons/mdlight/`

If your minimalist setup shipped replacement mdlight icons, drop them into `icons/mdlight/` in this repo and the deploy script will route them to the correct destination.

---

## Summary of where icons end up on the device

| Source in repo | Destination on Kindle |
|---|---|
| `icons/check.svg` | `/koreader/icons/check.svg` |
| `icons/rounded.corner.*.svg` | `/koreader/icons/` |
| `icons/favorites.svg` et al | `/koreader/icons/` |
| `icons/mdlight/*.svg` | `/koreader/resources/icons/mdlight/` |
