# Crank & Catch: web page design brief

A brief for designing a single web page for **Crank & Catch**, a free indie game for the Playdate handheld. Hand this file, the `www/assets/` folder and the `docs/web/media-kit-derived/` folder to the designer. **Deliver the page as `www/index.html`**: `www/` is exactly what gets deployed, so asset paths are `assets/...` relative to it.

---

## 1. The job

**What:** one static HTML page that explains the game, shows it in motion, links to the download, and walks players through installing it.

**Where it lives:** `https://mrballistic.com/crank-and-catch/` (an `index.html` in a `crank-and-catch/` folder on Todd's site, with `assets/` beside it).

**Who it's for:** Playdate owners (and the Playdate-curious) arriving from a link on social media, a forum, or the GitHub repo. Most are on phones. They already know what a Playdate is; they need to see the game, believe it's fun, and get it onto their device in under a minute.

**Success looks like:** someone lands, watches a few seconds of the video, taps **Download**, and follows the install steps without leaving the page.

---

## 2. Guardrails (please read first)

- **This is an indie game *for* Playdate, not a Panic product.** Panic publishes no third-party brand or badge guidelines, so:
  - Don't use the Playdate or Panic logos, or any "Available on / Made for Playdate" style badge. Say "for Playdate" in plain text.
  - Don't use Panic's brand yellow (`#ffc833` / `#fbc651`) as the page's accent color, and don't use **Roobert** (Panic's licensed typeface). Both would make the page read as official.
  - Device photos from Panic's press media kit are fine to use (Panic has approved redistribution) to show the game on real hardware; see `assets/device-hero.png` and section 7. Keep the trademark line in the footer.
- **Original game, original look.** Don't style the page after any classic handheld or LCD game.
- **No store language.** The game is free and sideloaded, not on Panic's Catalog. Never say "Catalog" or "buy".
- **Typography rules for the copy:** curly quotes and apostrophes (’ “ ”) everywhere in rendered text; em-dashes only where they earn it, always closed up (`word—word`). Numeric ranges use en-dashes.

---

## 3. Visual direction

### Mood
A late-night city, a burning building, and a cheerful rescue crew. Warm, a little scrappy, very readable. The game's own 1-bit pixel art is the star; the page should frame it, not compete with it.

### Palette

Derived from the actual Playdate screen (the tones its 1-bit display shows) plus a fire accent from the game's theme.

| Token | Hex | Role |
|---|---|---|
| `--page` | `#1d1c18` | Page background (warm near-black) |
| `--screen-dark` | `#312f28` | Playdate screen "black"; panels, cards |
| `--screen-light` | `#b1afa8` | Playdate screen "white"; body text on dark, pixel art |
| `--paper` | `#f5f5f0` | Optional light sections, high-contrast headings |
| `--fire` | `#ef5023` | Accent: primary button, links, small highlights |
| `--fire-hover` | `#ff6c42` | Accent hover / focus |
| `--muted` | `#7e7b75` | Secondary text, captions |

Text contrast: `#b1afa8` on `#1d1c18` passes WCAG AA for body text; white text on `#ef5023` passes for large/bold button labels only, so use **dark text (`#1d1c18`) on the fire button**, or bold 18 px+ white.

### Type
- **Wordmark:** the game's own pixel lettering, `assets/art/title-lcd@4x.png` (also `-1bit` for pure white). Don't re-typeset the title.
- **Headings and body:** a friendly grotesk with a bit of character, free to self-host. Suggested: **Space Grotesk** (OFL) for headings, **Inter** (OFL) for body. Any similar open-license pair is fine.
- **Small labels / specs:** a monospace such as **JetBrains Mono** or **IBM Plex Mono** (both OFL) works well for version numbers and step numbers.

### Pixel art handling (important)
- Every game image must render with crisp, square pixels: `image-rendering: pixelated;` on `img`, `video` and any background image containing game art.
- Scale only by whole numbers. Assets are pre-scaled (`@3x`, `@4x`, `@6x`, `@8x`); when displaying at other sizes, prefer CSS sizes that are whole multiples of the 400×240 screen (400, 800, 1200 px wide).
- Don't round corners on, blur, or add drop shadows to the game screen itself; a frame or bezel around it is fine.

### Motion
- The gameplay video autoplays **muted, looped, inline** (`autoplay muted loop playsinline`), with a poster.
- Respect `prefers-reduced-motion: reduce`: show the poster image and a play button instead of autoplay; no parallax or scroll-jacking.
- Small delights are welcome and on-theme, e.g. a jumper sprite (`assets/art/jumper-frame*`) bouncing in a margin, kept subtle and also disabled under reduced motion.

### Voice
Short, warm, a little wry. Confident, never salesy. Sentences, not slogans.

---

## 4. Page structure and copy

Copy is final unless a section notes otherwise; trim for layout as needed but keep the facts.

### 4.1 Hero

- **Wordmark:** title image (CRANK & CATCH / BOUNCE TO SAFETY).
- **Visual:** the gameplay video. Two options, designer’s choice:
  - **A (preferred):** the video playing inside the Playdate device photo, using the provided transform (section 7).
  - **B:** the video in a simple rounded bezel in `--screen-dark`, LCD-tone video (`crank-and-catch-lcd.mp4/.webm`).
- **Intro line:**
  > People are jumping from a burning building. Turn the crank to slide the net under them, and bounce them across the street to the ambulance.
- **Primary button:** **Download for Playdate** → `https://github.com/mrballistic/playdate-crank-and-catch/releases/latest/download/CrankAndCatch.pdx.zip`
- **Secondary link:** **How to install** → `#install`
- **Meta line (small, muted):** `Free · Version 0.5 · For Playdate`

### 4.2 How it plays

Section heading: **Aim with the net**

> Every catch bounces your jumper back into the air, and where they land on the net decides where they go next.

Three items, each with a small sprite or still:

- **Center:** nearly straight up. Safe and slow, and handy for holding one jumper while you deal with another.
- **Right side:** a long throw toward the ambulance. Fewer bounces, more risk.
- **Left side:** back toward the fire. The building bounces them back, so it’s not over yet.

(The labels “Center”, “Right side”, “Left side” can sit on a diagram of the net; `assets/art/firefighters-table-48-20-lcd@6x.png` frame 1 shows the net.)

Closing line:
> Get someone to the ambulance in two bounces or fewer for an **Express** bonus.

### 4.3 The climb

Section heading: **It gets harder. Fairly.**

> The net starts wide and forgiving, then narrows as your score climbs. A second jumper joins at 500 points, a third at 2,000, and everything speeds up as you go.

Facts (render as a compact list or stat tiles):

- **Rescue:** 100 points, worth more as the game speeds up (up to 160)
- **Express:** +50 for a rescue in two bounces or fewer
- **Extra life:** every 5,000 points, up to five
- **Net:** 72 px wide at the start, down to 44 px

Fairness line:
> Extra jumpers only leap when you could actually reach them. If two land at once, it’s because of where you aimed.

### 4.4 Screenshots

A row or grid of 3–4 stills (all 1200×720, LCD tones): `01-menu`, `03-express`, `04-net-narrows`, `05-late-game`. Captions optional:

- “The menu plays itself while you decide.”
- “Two bounces or fewer: Express.”
- “Every 500 points, the net gets a little narrower.”
- “Later on, the sky gets busy.”

### 4.5 Install (anchor `#install`)

Section heading: **Get it on your Playdate**

> Crank & Catch installs over Wi-Fi from your Playdate account. It takes about a minute.

Numbered steps:

1. **Download the game.** Get `CrankAndCatch.pdx.zip` (button repeats here). Don’t unzip it.
2. **Make sure your Playdate is registered** to your account at play.date. Wireless installs only work with a registered device.
3. **Upload it.** Sign in at **play.date**, open **Account → Sideload**, and drop in the zip. (Link: `https://play.date/account/sideload/`)
4. **Open Game Library on your Playdate.** The game downloads automatically; refresh the list if it doesn’t show up right away. On older system software, look under **Settings → Games**.

Small print under the steps:
> Prefer a cable? Panic’s guide covers installing over USB too: [help.play.date](https://help.play.date/games/sideloading/). Sideloaded games stay in your account, so you can reinstall any time.

### 4.6 Questions (optional, short)

- **Is it free?** Yes. It’s open source under the MIT license.
- **Is this made by Panic?** No. It’s an independent game by Todd Greco, made for Playdate.
- **What does it need?** A Playdate on current system software, connected to Wi-Fi.
- **Where’s the source?** On [GitHub](https://github.com/mrballistic/playdate-crank-and-catch).

### 4.7 Footer

- Made by **Todd Greco** · [mrballistic.com](https://mrballistic.com)
- [Source on GitHub](https://github.com/mrballistic/playdate-crank-and-catch) · [All releases](https://github.com/mrballistic/playdate-crank-and-catch/releases) · MIT license
- Trademark line (required if the device photo is used, recommended anyway):
  > Playdate is a registered trademark of Panic Inc. Crank & Catch is an independent game and is not affiliated with or endorsed by Panic.

---

## 5. Technical requirements

- **One static `index.html`**, CSS inline or in one stylesheet. No framework needed. The only JavaScript required is the small device-scaling snippet if Option A is used (section 7); the page must still read fine without JS.
- **Asset paths relative** (`assets/...`), since the page is served from `/crank-and-catch/`.
- **Responsive:** design mobile-first (360 px wide) up to wide desktop. The hero video should be the first thing visible on a phone.
- **Video markup:**
  ```html
  <video autoplay muted loop playsinline preload="metadata"
         poster="assets/video/crank-and-catch-poster-lcd.png"
         aria-label="Crank & Catch gameplay: catching jumpers and bouncing them to the ambulance">
    <source src="assets/video/crank-and-catch-lcd.webm" type="video/webm">
    <source src="assets/video/crank-and-catch-lcd.mp4" type="video/mp4">
  </video>
  ```
  The video has no audio track; it's designed for silent autoplay.
- **Accessibility:** meaningful alt text on screenshots, visible focus styles (use `--fire-hover`), buttons are real links, headings in order, color contrast as noted in section 3.
- **Performance:** keep the page under roughly 3 MB on first load. Lazy-load screenshots (`loading="lazy"`); the hero video is about 1 MB (WebM) and uses `preload="metadata"` plus the poster.

### Head tags

```html
<title>Crank & Catch: a crank-powered rescue game for Playdate</title>
<meta name="description" content="Turn the crank, catch the jumpers, and aim each bounce to get them to the ambulance. A free game for Playdate.">
<link rel="canonical" href="https://mrballistic.com/crank-and-catch/">
<meta name="theme-color" content="#1d1c18">

<meta property="og:type" content="website">
<meta property="og:title" content="Crank & Catch">
<meta property="og:description" content="Turn the crank, catch the jumpers, and aim each bounce to get them to the ambulance. A free game for Playdate.">
<meta property="og:url" content="https://mrballistic.com/crank-and-catch/">
<meta property="og:image" content="https://mrballistic.com/crank-and-catch/assets/social/og-image-1200x630.png">
<meta property="og:image:width" content="1200">
<meta property="og:image:height" content="630">
<meta property="og:image:alt" content="The Crank & Catch title screen: a burning building, a firefighter net and an ambulance in 1-bit pixel art">
<meta name="twitter:card" content="summary_large_image">

<link rel="icon" href="assets/icons/favicon.ico" sizes="any">
<link rel="icon" type="image/png" sizes="32x32" href="assets/icons/favicon-32.png">
<link rel="apple-touch-icon" href="assets/icons/apple-touch-icon.png">
```

---

## 6. Asset manifest

All in `www/assets/` (paths below are relative to it). Every image is strict 1-bit art (or its LCD-tone version); scale only by whole numbers.

### Video (`video/`)
| File | Size | Use |
|---|---|---|
| `crank-and-catch-lcd.webm` / `.mp4` | 1200×720, 48 s, ~1 MB | **Main video**, Playdate screen tones. Menu for 5 s, then a real game. |
| `crank-and-catch-1bit.webm` / `.mp4` | 1200×720 | Same in pure black and white, if a starker look suits the layout. |
| `crank-and-catch-screen-400x240.webm` / `.mp4` | 400×240 | Native size in the device photo's LCD tones; **only for Option A** (video inside the device photo). |
| `crank-and-catch-screen-poster-400x240.png` | 400×240 | Poster for that variant. A `<video>` poster fills the video's own box, so it must be screen-sized; never use a full device image as the poster. |
| `crank-and-catch-poster-lcd.png` | 1200×720 | Poster frame (first moment of gameplay). |
| `crank-and-catch-loop-lcd.gif` | 800×480, 6 s | Fallback loop for places video can't go (README, email, social). |

### Screenshots (`screenshots/`)
Each comes as `-lcd@3x.png` (1200×720, screen tones; **use these on the page**), `-1bit@3x.png` (1200×720) and `-1bit.png` (native 400×240).

| Name | Shows |
|---|---|
| `01-menu` | Title screen with the attract-mode demo |
| `02-two-up` | Two jumpers in the air at once |
| `03-express` | “EXPRESS +150” at the ambulance |
| `04-net-narrows` | The first net narrowing (popups stacked) |
| `05-late-game` | 1,000+ points, narrower net |

### Art (`art/`)
Each in `-lcd` (screen tones) and `-1bit` (white on transparent). Sheets are 4 frames laid out left to right.

| File | Notes |
|---|---|
| `title-*@4x.png` (956×212) | Wordmark: CRANK & CATCH / BOUNCE TO SAFETY |
| `card-*@3x.png` (1050×465) | The Playdate launcher card art |
| `icon-*@8x.png` (256×256) | App icon: a jumper on the net |
| `jumper-frame1–4-lcd@8x.png` (120×120 each) | A flailing jumper, one frame per file; good for small decorative animation |
| `victim-table-15-15-*@8x.png` | The same 4 frames as one sheet |
| `firefighters-table-48-20-*@6x.png` | Firefighters with the net, 4-frame walk cycle (frame 1 = standing) |
| `building-table-40-200-*@3x.png` | The burning building, 4 frames of flame flicker |
| `smoke-table-64-24-*@4x.png` | Roof smoke, 4 frames |
| `ambulance-*@6x.png` | The ambulance |

### Icons (`icons/`)
`favicon.ico`, `favicon-32.png`, `apple-touch-icon.png` (180), `icon-192.png`, `icon-512.png`.

### Social (`social/`)
| File | Use |
|---|---|
| `og-image-1200x630.png` | Link preview image (wired up in the head tags above). Simple: the title screen on the page background. Replace with a richer composition if you like; keep 1200×630. |
| `hero-21x9-2520x1080.png` | Wide banner, gameplay centered on the page background, for any 21:9 header slot. |

---

## 7. Optional: the video inside a real Playdate (Option A)

In `docs/web/media-kit-derived/` (built from Panic's press photo; Panic has approved redistribution). These are source files and are **not deployed**; copy anything the page needs into `www/assets/`:

| File | What |
|---|---|
| `playdate-device.png` | 1600×1600 Playdate photo with the crank out (transparent background), from Panic's *Playdate Media Kit 4.0* (`Playdate photos/Playdate-1.png`; identical to the file in Todd's unzipped kit at `~/Downloads/Playdate Media Kit 4.0/`). The kit has other angles too, but the screen coordinates and transform below only fit this one. |
| `device-mockup-menu.png`, `device-mockup-gameplay.png` | Stills: the game composited onto the device's screen, perspective-matched. Good for the OG image or a no-JS fallback. |
| `device-screen.json` | The screen's corner coordinates (pixels and percentages) and the CSS transform below. |
| `device-video-demo.html` | **A working reference** of the video playing on the device's screen. Verified in Chromium. |
| `www/assets/device-hero.png` | **Todd's composite (preferred still):** 1600×1600, the gameplay screenshot on the device's screen with the photo's glass reflection kept over it, so it reads as a real photo. Use it as the hero image when not using the live video, and as the **base image for Option A**: put it under the video instead of `playdate-device.png`, so the device already shows the game before the video loads or when motion is reduced. Same photo and screen position, so it lines up exactly with the transform below. Also a good basis for a richer social image. |

How it works: lay out a 1600×1600 box containing `assets/device-hero.png` (or the bare `playdate-device.png`), place the 400×240 `crank-and-catch-screen-400x240` video at its top-left with this transform, then scale the whole box to fit:

```css
.device { position: absolute; width: 1600px; height: 1600px; transform-origin: 0 0; transform: scale(var(--s)); }
.device video {
  position: absolute; top: 0; left: 0; width: 400px; height: 240px;
  transform-origin: 0 0;
  transform: matrix3d(1.896506, 0.026029, 0, -0.000077, 0.005046, 2.366709, 0, 0.000005, 0, 0, 1, 0, 165, 228, 0, 1);
  image-rendering: pixelated;
}
```
```js
new ResizeObserver(([e]) => device.style.setProperty('--s', e.contentRect.width / 1600)).observe(frame);
```

Keep the trademark line in the footer (section 4.7). Option B (a plain bezel) remains the fallback where a device image doesn't fit the layout.

The video covers the glass reflection that `device-hero.png` shows on the screen. To keep that real-glass look while it plays, lay a faint diagonal white gradient (around 6–10% opacity) over the video, clipped to the same transformed box.

---

## 8. Links

| What | URL |
|---|---|
| Direct download (always the latest release) | `https://github.com/mrballistic/playdate-crank-and-catch/releases/latest/download/CrankAndCatch.pdx.zip` |
| Latest release page | `https://github.com/mrballistic/playdate-crank-and-catch/releases/latest` |
| Source | `https://github.com/mrballistic/playdate-crank-and-catch` |
| Sideload upload page | `https://play.date/account/sideload/` |
| Panic's sideloading help | `https://help.play.date/games/sideloading/` |
| Page URL | `https://mrballistic.com/crank-and-catch/` |

## 9. Out of scope

Analytics, cookie banners, newsletter sign-ups, comments, and any build tooling. Keep it one fast, friendly page.
