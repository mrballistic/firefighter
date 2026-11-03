# Active Context

## Current focus
Original art and sound are in (named **Crank & Catch**). Next is a simulator playtest and balance pass.

## Recent changes (2026-11)
- Rebuilt around **bounce angle by hit position** (constant speed), tuned with `scripts/tune.lua` to speed 220, bias 8°, spread 35°.
- Fixed: crash on first rescue (nil `dt` in sprite update), double scoring, observers duplicated per game, double removal of rescued victims, repeated catches, victims moving twice per frame and drifting while paused, missing `super.init`, an unreachable bottom window, and the right-edge ricochet loop.
- Added: difficulty ramp, Express bonus, saved high score, synth sounds with WAV overrides, popups/shake/net sag, auto-pause, crank indicator on the menu, asset drop-in with placeholder fallback.
- Added tests (unit, playability, headless smoke) and `scripts/build.sh`.

- Art from Claude Design: animated building, firefighters (walk cycle), victims, roof smoke; static ambulance, flash, background, launcher card and icon. All verified 1-bit with `scripts/check_art.py`.
- Sounds: boing and splat, trimmed to WAV by `scripts/prep_sounds.py`.

- Menu redone: title art from the card, attract-mode demo, backed text. Bounce raised to 280 px/s at 5° ± 15°.
- Found and fixed: the demo spawned the next jumper the instant the last one was rescued (its outcome handlers skipped the spawn-timer reset).

- 0.3: fair spawning; background art restored (gfx.sprite.removeAll() was deleting the background sprite, so it's now re-registered on every scene build); score moved to top center; popups clamped on screen; American spelling throughout; title subtitle centered; screenshot tooling.

- 0.4: net starts at 72 px and narrows 4 px per 500 points to a 44 px floor (composed per width from the art's end figures); extra life every 10,000 points (max 5); speed-up capped at 1.3×; fixed a hardware-only bug where the net stored its width in the sprite's read-only `width` (rendered 0 px wide); smoke stubs now reject such writes.

- 0.5: extra life every 5,000 points (was 10,000); rescues worth 10 more per speed-up in effect (100 → 160 at full speed, Express +50 on top).

## Next steps
1. Source MP3s live in `docs/`; regenerate the game WAVs with `python3 scripts/prep_sounds.py docs`.
2. Playtest on the simulator and device: crank sensitivity (2 px per degree), the 3-victim threshold, and whether the menu hint text fits beside the crank indicator.
3. Final title, bundle ID and launcher images.
