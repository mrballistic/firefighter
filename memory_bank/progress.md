# Progress

## Done
- Core loop: spawn → catch → aimed bounce → rescue or miss; lives; game over.
- Difficulty ramp, Express bonus, persistent high score.
- Sound (synth, with WAV overrides), popups, shake, net sag, ambulance flash.
- Pause (Ⓑ and the system menu), crank indicator, D-pad fallback.
- Asset drop-in system and art/sound brief.
- Build script; unit, playability and headless smoke tests.

## Not yet verified on screen
The game builds with pdc and passes the headless smoke test, but has not yet been looked at in the simulator after the rebuild. Check text layout, the crank indicator, sound levels and the feel of the crank.

## To do
- Optional sounds: rescue, express, game over (synth fallbacks play for now).
- Balance pass from real play.
- Title and bundle ID; then `imagePath` in pdxinfo.

## Known issues
- None found in tests. Possible difficulty spike at 2,000 points (3 victims).
