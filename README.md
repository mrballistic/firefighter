# 🚒 Crank & Catch

A crank-controlled rescue game for [Playdate](https://play.date). People are jumping from a burning building: slide the net under them and bounce them across the screen into the ambulance. 🎮

## 🎮 How it plays

- 🎣 **Turn the crank** to slide the firefighters and their net (the D-pad works too).
- 🎯 **Where they land on the net sets the throw.** Center sends them nearly straight up and a little forward: safe, and it buys time. The right side throws them toward the ambulance. The left side throws them back toward the building.
- 🚑 **Get them into the ambulance** for 100 points. Make it in **2 bounces or fewer** for an Express bonus (+50).
- ❌ Three misses and it's over.
- 📈 **It ramps up:** a second jumper at 500 points, a third at 2,000, and every 500 points the action runs 5% faster (capped at +40%) with less time between jumpers.
- ⚖️ **It's fair:** an extra jumper only leaps when a player cranking at a comfortable pace could reach both their first landing and everyone else's next one. Clashes after that come from where you aimed.

| Control | Action |
|---|---|
| 🎣 Crank / ✛ left-right | Move the net |
| Ⓐ | Start / back to menu |
| Ⓑ | Pause / resume (opening the Playdate menu also pauses) |

The high score is saved on the device. While the menu is up, the scene plays itself: the firefighters work through a stream of jumpers, as a demo of the aiming.

## 🛠️ Building

Requires the [Playdate SDK](https://play.date/dev/) (tested with 3.1.2) at `~/Developer/PlaydateSDK`, or wherever `PLAYDATE_SDK_PATH` points.

```bash
scripts/build.sh          # run tests, then build build/CrankAndCatch.pdx
scripts/build.sh --run    # ...and open it in the Playdate Simulator
scripts/build.sh --test   # tests only (no SDK needed, just `lua`)
```

## 📲 Installing on a Playdate

- **Sideload over Wi-Fi (works everywhere):** zip the build (`cd build && zip -r CrankAndCatch.pdx.zip CrankAndCatch.pdx`), upload it at [play.date/account/sideload](https://play.date/account/sideload/), then on the Playdate open **Settings → Games**.
- **USB:** `scripts/install_device.sh` puts the Playdate in disk mode, copies the game into `Games/`, and launches it. The Playdate must be unlocked and on a data cable. Machines with endpoint security that blocks USB storage will refuse the disk ("The disk you attached was not readable"); use sideloading there. Never click **Initialize** on that dialog, because it erases the Playdate's games and saves.

## 🧪 Tests

The physics, scoring and difficulty code is plain Lua with no Playdate dependencies, so it is tested with a stock `lua` (`brew install lua`):

- `tests/run.lua`: unit tests. Beyond the basics, they check playability: every window's jumper lands within reach of the net, the highest bounce stays on screen, aiming further right never takes more bounces, overshoots still end in the ambulance, and the Express bonus is achievable but not by safe center catches.
- `tests/smoke.lua`: runs the real `main.lua` headless against a stubbed Playdate API, with a scripted player, through menu → play → pause → game over → second game → relaunch. It catches runtime errors in game logic. It can't catch a wrong Playdate API call, because the stubs accept anything, so check changes in the simulator too.
- `SMOKE_ART=1 lua tests/smoke.lua`: the same run with every image present as a 4-frame sheet. It checks the animations (flames cycle, firefighters step only while moving, everything freezes on pause) and the draw order.
- `scripts/check_art.py`: checks every PNG is pure 1-bit and that sheets divide into whole frames (`uv run --with pillow python scripts/check_art.py`).
- `scripts/make_title.py`: crops the title lettering out of the launcher card into `source/images/title.png`, which the menu uses. Re-run it after changing the card.
- `scripts/prep_sounds.py`: turns source audio (mp3 and others) into trimmed Playdate WAVs.
- `scripts/fairness.lua`: simulates the multi-jumper stages at a capped crank speed and reports how many misses no player could have avoided (`FAIR_OFF=1` for the baseline without fair spawning).
- `scripts/screenshots.sh`: captures real screenshots from the simulator. A driver (`scripts/capture/`) plays a copy of the game and saves the frame at set moments, into `screenshots/` at 400×240 and 800×480.
- `scripts/tune.lua`: a parameter sweep that prints bounces-to-rescue by aim for a grid of bounce speeds and angles. Use it before changing the physics numbers.

## 📁 Layout

```
source/
├── main.lua                 # state machine, game loop, scoring, UI
├── pdxinfo                  # name, bundle ID, version
└── game/
    ├── config.lua           # every layout and tuning constant (pure Lua)
    ├── physics.lua          # motion, catch detection, bounce-by-hit-position (pure Lua)
    ├── rules.lua            # scoring and difficulty ramp (pure Lua)
    ├── assets.lua           # loads source/images/* if present, else placeholder
    ├── sound.lua            # synth effects; source/sounds/*.wav override them
    ├── effects.lua          # score popups, screen shake
    └── entities/            # building, firefighters (net), ambulance, victim sprites
tests/                       # unit + smoke tests (see above)
scripts/                     # build.sh, tune.lua
docs/art-brief.md            # specs for original art and sound
```

### How the bounce works

Each catch launches the victim at a fixed speed (`BOUNCE_SPEED`). Only the angle depends on where they land. With hit position `h` from −1 (left edge) to +1 (right edge), the angle from vertical is `BOUNCE_BIAS_DEG + h × BOUNCE_SPREAD_DEG` (5° ± 15° today, at 280 px/s: high, readable arcs of about 1.4 s each). Constant speed keeps it predictable, so the player aims by positioning alone. The right edge of the screen is the ambulance's back door: an overshoot drops in rather than ricocheting back.

## 🎨 Art and sound

The art is in `source/images/` (several pieces are 4-frame animated sheets) and the sounds are in `source/sounds/`. Anything missing falls back to a placeholder drawn in code or a synth beep. To replace a piece, drop in correctly sized PNGs into `source/images/` and WAVs into `source/sounds/`, and they replace the placeholders automatically, one file at a time. Sizes, formats and must-haves are in [`docs/art-brief.md`](docs/art-brief.md).

## 📄 License

MIT. See [LICENSE.md](LICENSE.md).
