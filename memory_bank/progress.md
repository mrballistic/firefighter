# Progress

Current release: **0.5.0** (build 5), published as GitHub release `v0.5.0` with the sideload zip attached. Played on hardware.

## Done
- Core loop: spawn, catch, aimed bounce, rescue or miss; lives; game over.
- Scoring: rescue value rising with speed (100 to 160), Express bonus (+50), extra life every 5,000 points (max 5), saved high score.
- Difficulty: net narrows 72 to 44 px, up to 3 jumpers, speed up to 1.3x, fair spawning.
- Original 1-bit art with 4-frame animations (flames, walk cycle, jumpers, roof smoke), launcher card and icon, title cropped from the card.
- Sound: boing and splat samples, synthesized rescue/express/game-over/extra-life.
- Menu with attract-mode demo; backed text labels; score popups, screen shake, net sag, ambulance flash.
- Pause (B and the system menu), crank indicator on the menu, D-pad fallback.
- Tests: unit and playability (`tests/run.lua`), headless smoke test with and without art (`tests/smoke.lua`).
- Tools: tuning sweep, fairness probe, simulator screenshot capture, art checker, title cropper, sound prep, USB installer.

## To do
- Balance from continued hardware play, especially the three-jumper stage and the endgame (3,500+).
- Optional samples for rescue, express and game over (synth versions are fine for now).

## Known issues
- Endgame at a relaxed crank pace still has about 6 misses/min, roughly 30% unavoidable (clashes after the first bounce). Extra lives offset it.
- USB install doesn't work on the main dev machine (corporate policy blocks USB storage); sideload instead.
