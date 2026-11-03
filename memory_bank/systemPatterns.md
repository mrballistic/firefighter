# System Patterns

## Architecture
- `buildScene()` builds the same sprites for the menu and the game; `game.demo` switches between the attract-mode demo (no score, no sound, demo net steering) and real play.
- `main.lua` owns everything that changes: the state machine (menu / playing / paused / game over), the victim list, scoring, lives and spawning. No observer or event bus: rescue and loss call `onRescued` / `onLost` directly. (An earlier observer setup re-registered on every game, which doubled scoring in game 2.)
- **Pure-Lua core:** `config.lua`, `physics.lua` and `rules.lua` touch no `playdate.*` APIs, so tests run on stock Lua. Keep any new game logic in this layer when possible.
- **Sprites don't move themselves.** `gfx.sprite.update()` calls every sprite's `update()` with no arguments, so movement or timers in `update()` run twice per frame or crash on a nil `dt`. Entities expose `tick(dt)` (animation, timers) and `sync()` (copy the physics body to the sprite position), called from `main.lua`.
- Victim state lives in a plain `body` table `{x, y, vx, vy, bounces}`, separate from the sprite.

## Physics
- Semi-implicit Euler; gravity 400 px/s²; frame time clamped to 1/15 s.
- Catches are detected by the victim's centre **crossing** the catch line (`NET_Y − radius`) while falling, over the net. This fires once per catch and can't be skipped by a long frame.
- Bounce: fixed speed (280), angle = 5° + h × 15°. Chosen with `scripts/tune.lua` for higher arcs (more reaction time) while keeping each step of aim worth fewer bounces.
- `Physics.timeToLand` / `landingX` predict where a body next crosses the catch line; the demo player (and the smoke test's scripted player) steer to that point.
- Walls: the building face reflects; the right screen edge stops the victim dead over the ambulance (no ricochet loop).
- Rescue: centre x ≥ ambulance left edge and bottom ≥ ambulance top. Lost: fully below the screen.

## Rendering
- `gfx.sprite.setAlwaysRedraw(true)` plus a black background colour (or `images/background` via the background callback). The whole frame redraws, so immediate-mode UI text never leaves stale pixels. Don't call `gfx.clear()`.
- UI text is drawn after `gfx.sprite.update()` with `kDrawModeFillWhite`.

## Assets
- `Assets.anim(name, step, fallback)` plays `<name>-table-W-H.png` sheets on an explicit clock (so pause freezes it), falling back to a still image, then the placeholder. Building flames (0.18 s), smoke (0.3 s, separate sprite on the roof) and victims (0.12 s, random phase) tick on time; the firefighters' walk cycle ticks on **pixels moved** and resets to the standing frame when the net stops.
- Draw order is explicit via `Config.Z_*`: building < smoke < ambulance < net < victims.
- `Assets.image(name, fallback)` loads `source/images/<name>.png`, or calls the fallback, which draws the placeholder. Art can land one file at a time; the specs are in `docs/art-brief.md`.
- Sounds: `source/sounds/<name>.wav` overrides the synth fallback; the bounce sample is pitch-shifted by hit position.
