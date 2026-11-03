# Tech Context

## Toolchain
- Playdate SDK 3.1.2 at `~/Developer/PlaydateSDK` (override with `PLAYDATE_SDK_PATH`). Not on Homebrew; download from play.date/dev.
- `scripts/build.sh` runs all tests, then `pdc source build/CrankAndCatch.pdx`; `--run` opens the simulator; `--test` runs the tests only.
- Tests use Homebrew `lua` (5.5 locally). The device runs 5.4, so the pure modules stick to the shared subset. Don't use Playdate's `+=` extension in those files.
- Python tools use `uv run --with pillow` where they need Pillow (`check_art.py`, `make_title.py`, the screenshot upscale); `prep_sounds.py` needs only the standard library and macOS `afconvert`.

## Tests
- `tests/run.lua`: unit and playability tests for physics and rules, sharing `tests/harness.lua`. Reachability and aim are checked at both the widest and narrowest net.
- `tests/smoke.lua`: headless run of the real `main.lua` against stubs, in two modes: placeholders, and `SMOKE_ART=1` (every image present as a 4-frame sheet). It catches logic and runtime errors in game code. It cannot catch wrong SDK API names or signatures, so verify those in the simulator. The stub sprites reject writes to `width`/`height`, matching the device.

## Tools
- `scripts/tune.lua`: bounce-parameter sweep (bounces-to-rescue by aim).
- `scripts/fairness.lua`: multi-jumper miss rates and the unavoidable share at a capped crank speed; `FAIR_OFF=1`, `FAIR_SPEED`, `FAIR_REACTION` overrides.
- `scripts/screenshots.sh` + `scripts/capture/capture_driver.lua`: builds a copy of the game with a driver appended (own bundle ID, so real saves are untouched), plays it in the simulator at 8x and writes PNGs via `playdate.simulator.writeToFile`. The driver logs progress to `<SDK>/Disk/Data/com.mrballistic.crankandcatch.capture/capturelog.json`.
- Simulator Lua errors appear only in its Console window (not stdout or the system log); take a screenshot of it to read them.

## Installing on hardware
- Sideload: zip the `.pdx`, upload at play.date/account/sideload, then Settings > Games on the device. The GitHub release carries the zip.
- USB: `scripts/install_device.sh` (pdutil data-disk mode). Blocked on the main dev machine by corporate endpoint security, which rejects the Playdate's disk as unreadable.

## Config
All layout and tuning numbers live in `source/game/config.lua`. Derived values (catch line, ambulance edges, spawn points) are computed there; net range depends on the current width via `Physics.netRange(half)`.

## Repo notes
- `source/pdxinfo` is committed (it used to be gitignored, which broke builds).
- `build/` and `*.pdx` are ignored; `screenshots/` is committed.
- Source audio (MP3) lives in `docs/`, outside `source/`, so pdc doesn't bundle it.
