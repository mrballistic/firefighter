# Crank & Catch: art & sound brief

Everything needed to produce original art and sound for this game. Paste this
whole file into Claude Design (or hand it to anyone making assets).

## The game in one paragraph

A Playdate game. A building on the left is on fire; people jump from its
windows. The player turns the crank to slide two firefighters holding a net
along the bottom of the screen. Each catch bounces the jumper back up, and
**where they land on the net sets the throw**: centre goes nearly straight up,
the right side throws them toward an ambulance on the right, the left side
throws them back toward the building. Get them into the ambulance to score.

## Direction

- **Original look.** Don't imitate any existing game's characters, screens or
  layout, and avoid the segmented-LCD look specifically. We want our own
  character designs and our own scene.
- **Tone:** urgent but cheerful. A miss is a cartoon splat (think pratfall,
  not injury); nothing gory.
- **Readable at tiny sizes.** The Playdate screen is 400×240 at about 173 DPI,
  and sprites are as small as 15×15. Bold silhouettes beat detail.

## Hard technical rules

- **1-bit only:** every pixel is pure black, pure white, or transparent. No
  greys or anti-aliasing; the device has no grey and will threshold them
  unpredictably. Pattern dithering (checkerboard and similar) is fine and is
  how 1-bit art does shading.
- **The background is black, so sprites read as white-on-black.** Use black
  inside a sprite for detail lines and windows, and transparency around it.
- **PNG, exact pixel sizes as listed.** Collision is tuned to these sizes;
  a different size breaks gameplay.
- **Animated sheets** are named `<name>-table-<frame width>-<frame height>.png`,
  with frames laid out left to right. All timings live in
  `source/game/config.lua`; the game freezes every animation while paused.
- Files go in `source/images/`. Every file is optional: anything missing falls
  back to the current placeholder drawing, so art can land one file at a time.

## Sprites

| File | Size (px) | What it is | Must-haves |
|---|---|---|---|
| `building.png` | 40 × 200 | The burning building; its bottom sits on the screen's bottom edge | Five windows on the **right-hand face**, centred at y = 15, 45, 75, 105, 135 (from the top of the image), each about 20×20. Jumpers appear at the right edge at those heights. Flames and smoke welcome. |
| `firefighters.png` | 48 × 20 | Two firefighters holding a net between them | The **net's top surface must be exactly at row 10** (rows 10–13 = net). Firefighters stand at the far left and far right ends (about 5 px each). **Keep aim marks on the net**: a centre notch plus quarter ticks. Players aim with them. |
| `victim.png` | 15 × 15 | A jumper, mid-air | Reads as a person at 15 px. Arms up or flailing. |
| `victim-table-15-15.png` *(optional, replaces `victim.png`)* | 15 × 15 per frame | Same jumper, flailing | Frames side by side (4 frames = 60 × 15). Loops at 0.12 s/frame; each jumper starts at a random frame. |
| `building-table-40-200.png` *(optional, replaces `building.png`)* | 40 × 200 per frame | Flames flickering in the windows | Same window positions in every frame. Loops at 0.18 s/frame. |
| `firefighters-table-48-20.png` *(optional, replaces `firefighters.png`)* | 48 × 20 per frame | Walk cycle | **Frame 1 is the standing pose** (shown whenever the net is still). Frames advance every 8 px the net moves, so steps match the crank. The net surface stays on row 10 in every frame. |
| `smoke-table-64-24.png` *(optional)* | 64 × 24 per frame | Smoke drifting off the roof | Its bottom-left corner sits on the roof's left edge (screen x 10, y 40); puffs drift up and to the right. Loops at 0.3 s/frame, on its own clock. No placeholder: without this file there's no smoke. |
| `ambulance.png` | 40 × 30 | The ambulance on the right; its bottom sits about 5 px above the screen's bottom | Victims drop in from above and the left, so an open back or roof hatch facing left/up sells it. Cab on the right. |
| `ambulance-flash.png` *(optional)* | 40 × 30 | Shown for 0.2 s on each rescue | If missing, the game uses an inverted `ambulance.png`. |
| `title.png` *(generated)* | about 239 × 53 | Menu title | Cropped from the launcher card by `scripts/make_title.py`, so the menu and card share one lettering. Don't draw it separately; re-run the script after changing the card. |
| `background.png` *(optional)* | 400 × 240 | Full-screen backdrop behind everything | **Mostly black** (sprites are white). Keep the **top 20 px** clear (score/lives text) and the **middle band** around y = 80–160 calm (menu text). A ground line near y = 236, a skyline, stars or drifting smoke all work. |

### Layout reference (screen coordinates, 400 × 240)

- Building: x 10–50, y 40–240.
- Net: slides between x ≈ 74 and 326; its surface is at y = 220.
- Ambulance: x 350–390, y 205–235.
- Highest bounce reaches about y = 115; jumpers start between y = 55 and 175.
- Menu: the title sits at y 6–59, with two text lines below it down to y ≈ 106.

## Launcher (Playdate home screen)

Goes in `source/images/launcher/` (already referenced from `source/pdxinfo`).
The game is called **Crank & Catch**; the card should carry that title.

| File | Size (px) | Notes |
|---|---|---|
| `card.png` | 350 × 155 | The game's card. Title art plus a hint of the scene. |
| `card-highlighted.png` *(optional)* | 350 × 155 | Shown when selected. |
| `icon.png` | 32 × 32 | List-view icon. |
| `launchImage.png` *(optional)* | 400 × 240 | Shown while loading. |

## Sounds

Each is optional; missing ones use built-in synth beeps.

- **Any format is fine as a source** (mp3, aif, m4a). Keep the originals
  *outside* `source/` (the current originals are in `docs/`), and run
  `python3 scripts/prep_sounds.py docs`. It writes trimmed 16-bit
  mono WAVs to `source/sounds/` (leading silence and silent tail removed, short
  fade-out). Don't leave MP3s in `source/sounds/`: pdc bundles them as well.

| File | When | Notes |
|---|---|---|
| `bounce.wav` | Every catch | The game **pitch-shifts it by up to half an octave** (lower on a left-edge catch, higher on the right), so record it at a neutral middle pitch. Under 0.3 s. A boing. |
| `rescue.wav` | Victim reaches the ambulance | Short and bright, under 0.5 s. |
| `express.wav` | Rescue in 2 bounces or fewer (bonus) | A bigger version of `rescue.wav`. |
| `splat.wav` | Victim hits the ground | Cartoon splat. Plays on every miss, including the last one. |
| `gameover.wav` | Last life lost | 1–2 s. Starts 0.5 s after the final splat. |
