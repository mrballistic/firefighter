# Active Context

## Current focus
Version 0.5 is released and plays well on hardware. Work now is balance and polish driven by play: how the busy stages and the endgame feel, and how fast extra lives arrive now that rescues are worth more at speed.

## Release history (2026-11)
- **Initial rebuild:** reworked around bounce angle by hit position (constant speed); fixed the original code's crash on first rescue, double scoring, duplicated observers, double removal, repeated catches, double-stepped and paused-drifting victims, missing `super.init`, an unreachable window and a right-edge ricochet loop. Added difficulty ramp, Express bonus, saved high score, sound, effects, auto-pause, asset drop-in, tests and build script. Art from Claude Design; boing and splat samples.
- **0.3:** fair spawning; attract-mode menu with title cropped from the card; higher bounce (280 px/s at 5° ± 15°); background art restored (`gfx.sprite.removeAll()` deletes the background sprite, so it's re-registered on every scene build); score at top center; popups clamped on screen; American spelling; screenshot tooling.
- **0.4:** net starts at 72 px and narrows 4 px per 500 points to a 44 px floor; extra life every 10,000 points; speed-up capped at 1.3x; fixed the net storing its width in the sprite's read-only `width` (it rendered 0 px wide on the device).
- **0.5:** extra life every 5,000 points; rescues worth 10 more per speed-up in effect (100 to 160).
- **0.6:** popups stack instead of overlapping (a rescue that crosses a threshold also narrows the net, so both popped in the same spot); smoke test checks it. Added the web page kit: `docs/web/BRIEF.md` for Claude Design, `www/assets/` (gameplay video, screenshots, art, icons, social images, Todd's `device-hero.png`), `docs/web/media-kit-derived/` (device photo, mockups, CSS `matrix3d` for the video-in-device overlay). New tools: `scripts/video.sh`, `scripts/site_assets.py`, `scripts/capture/build_capture.sh`. Page will live at mrballistic.com/crank-and-catch; Panic approved redistributing media-kit images.

## Release process
1. Bump `version` and `buildNumber` in `source/pdxinfo`.
2. `scripts/build.sh`, then zip `build/CrankAndCatch.pdx` as `build/CrankAndCatch.pdx.zip`.
3. Commit on a `release-x.y` branch, open a PR into `main`, merge with a merge commit, delete the branch.
4. Publish a GitHub release `vX.Y.0` targeting the merge commit (full SHA), with the zip attached.

Git identity for this repo is the personal account (`mrballistic@gmail.com`, set in repo config). Git and `gh` default to the work account, so pushes and `gh` calls use `GH_TOKEN="$(gh auth token --user mrballistic)"`.

## Next steps
1. Play more on hardware; tune the three-jumper stage and the endgame if they feel unfair.
2. Source MP3s live in `docs/`; regenerate the game WAVs with `python3 scripts/prep_sounds.py docs` after changing them.
