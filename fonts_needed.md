# Fonts you need to supply

This repo does not bundle any font files (licensing + size).

## Montserrat — required for the minimalist "Home" label

**Source:** https://fonts.google.com/specimen/Montserrat

**Destination:** `/koreader/fonts/montserratstatic/`

Download the "Static" variants zip from Google Fonts and extract the TTF files into `fonts/montserratstatic/` in this repo. The deploy script will then copy the folder to `/koreader/fonts/montserratstatic/` on your Kindle.

At minimum you need:
- `Montserrat-Regular.ttf`
- `Montserrat-Bold.ttf`

ProjectTitle will auto-discover any TTF in `/koreader/fonts/` subfolders after restart.

## If you skip this

The minimalist look will still apply, but the "Home" label in the title bar will fall back to KOReader's default serif face. Everything else works.

---

## Directory layout in this repo

```
fonts/
└── montserratstatic/
    ├── Montserrat-Regular.ttf
    ├── Montserrat-Bold.ttf
    ├── ... (optional: other weights)
    └── OFL.txt
```
