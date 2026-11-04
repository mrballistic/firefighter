# Crank & Catch page: handoff for Claude Code

> **Status (2026-11-04): done.** The page is at `www/index.html`, the new photo at `www/assets/playdate-closed.webp`, and this file moved to `docs/web/` (the brief's `site/assets/` is now `www/assets/`).
> - Fonts self-hosted in `www/assets/fonts/` (Latin variable WOFF2, same weight ranges; OFL licenses alongside). No external requests remain.
> - Hero served as `device-hero.webp` (308 KB, from 2.9 MB) via `<picture>` with the PNG fallback, at both places. The photo rule became `.device > picture > img`.
> - Fixed: the no-JS still was stretched to 1600 px tall (its `height` attribute won); added `height:auto`.
> - Updated the meta line to Version 0.6 (current release).
> - Verified in Chromium at 360 px (3× density), 800 px and 1280 px: video plays on the screen and lines up, reduced motion shows the still and play button and the button starts the video, no-JS shows the matching still, no sideways scroll, no console errors or failed requests, first load about 800 KB. **Not yet checked in Safari/iOS or Firefox.**
> - Markup and copy pass `scripts/check_page.py` and the deploy workflow's link check.

The design is final; it was built on a Claude Design canvas from `BRIEF.md` and approved by Todd. This package is the production version: a static `index.html` ready to drop into the `crank-and-catch/` folder of mrballistic.com.

## What's in this package

| File | Goes to |
|---|---|
| `index.html` | `crank-and-catch/index.html` |
| `assets/playdate-closed.webp` | `crank-and-catch/assets/playdate-closed.webp` (**new asset**, not in the original `site/assets/`) |
| `HANDOFF.md` | This file; don't deploy it |

Every other path in `index.html` points at the existing `site/assets/` tree from the brief (`assets/art/…`, `assets/video/…`, `assets/screenshots/…`, `assets/icons/…`, `assets/social/…`, `assets/device-hero.png`). Copy that folder alongside `index.html` unchanged.

`playdate-closed.webp` is cropped and resized from Panic's *Playdate Media Kit 4.0*, `Playdate photos/Playdate-cover-photo-1.png` (Panic has approved redistribution). It's 1200×496, transparent background, about 50 KB.

## Tasks

1. **Place the files** as in the table above and check that every `assets/…` path in `index.html` resolves (no 404s). Paths must stay relative because the page is served from `/crank-and-catch/`.
2. **Self-host the fonts.** Replace the Google Fonts `<link>` (marked `TODO(handoff)`) with local `woff2` files for Space Grotesk 500/700, Inter 400/500/600 and JetBrains Mono 400/500 (all OFL), using `font-display: swap`. Keep the family names so the CSS doesn't change.
3. **Cut the hero image weight.** `assets/device-hero.png` is about 2.8 MB, which breaks the ~3 MB first-load budget on its own. Make a WebP (quality ~88, alpha kept; expect ~200–300 KB) and serve it with `<picture>` and a PNG fallback. It appears **twice** in the hero (the `.device-still` no-JS fallback and the image inside `.device`); update both. It must stay 1600×1600 so the screen transform keeps lining up.
4. **Verify in a browser** (Chromium, Safari/iOS and Firefox), at 360 px, ~800 px and 1280 px+:
   - The hero video plays muted, inline and looping on the Playdate's screen, lined up with the screen glass (`matrix3d` is from `device-screen.json`; don't change it).
   - With `prefers-reduced-motion: reduce`, there's no autoplay and no bouncing jumper. The still composite shows with an orange play button over the screen, and clicking it starts the video.
   - With JavaScript off, the hero shows the cropped still (`.device-still`) and the page reads fine.
   - Every piece of game art stays crisp, with square pixels (`image-rendering: pixelated`).
   - The page doesn't scroll sideways at 360 px.
5. **Lint the copy and markup:** valid HTML, headings in order (h1 → h2 → h3), and curly quotes and apostrophes in rendered text. Don't reword the copy; it's final.

## Design decisions to keep (don't "fix" these)

- **Palette** is the brief's, with two accessibility adjustments: small muted text uses `#8f8c85` (the brief's `#7e7b75` fails AA at small sizes), and links on the light Install section use `#b03a12` (fire orange fails on `#f5f5f0`). The fire button keeps dark text.
- **No eyebrows, stat tiles or zero-padded step numbers.** Todd asked for these AI tells to be removed. Section headings stand alone, the climb facts are a `<dl>`, and the install steps use a CSS counter (1–4).
- **"Aim with the net" diagram:** every sprite is 4× native (building, net, jumper, ambulance) so proportions match the game, dropping to 2× on phones, where the building and ambulance are hidden. The left, center and right items run in that order to match the diagram.
- **Hero device crop:** the 1600 px photo is cropped to x 100–1560, y 140–1440 (aspect 1460/1300). On phones, it crops tighter (1460/1000) with a fade at the bottom, so the screen stays large and the video is the first thing seen.
- **Guardrails from the brief:** no Playdate or Panic logos or badges, no Panic yellow, no Roobert, no "Catalog" or "buy", and the trademark line stays in the footer.

## Out of scope

Analytics, cookie banners, newsletter sign-ups, comments and build tooling. Keep it one fast, static page.
