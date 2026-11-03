# Tech Context

## Toolchain
- Playdate SDK 3.1.2 at `~/Developer/PlaydateSDK` (override with `PLAYDATE_SDK_PATH`). Not on Homebrew; download from play.date/dev.
- `scripts/build.sh` runs the tests, then `pdc source build/CrankAndCatch.pdx`; `--run` opens the simulator; `--test` runs the tests only.
- Tests use Homebrew `lua` (5.5 locally). The device runs 5.4, so the pure modules stick to the shared subset. Don't use Playdate's `+=` extension in those files.

## Tests
- `tests/run.lua`: unit and playability tests for physics and rules (shared harness in `tests/harness.lua`).
- `tests/smoke.lua`: headless run of the real `main.lua` against stubs. It catches logic and runtime errors in our code. It cannot catch wrong SDK API names or signatures, so verify those in the simulator.
- `scripts/tune.lua`: bounce-parameter sweep.

## Config
All layout and tuning numbers live in `source/game/config.lua`. Derived values (net range, catch line, ambulance edges, spawn points) are computed there, so moving or resizing one thing keeps the others consistent.

## Repo notes
- `source/pdxinfo` is committed (it used to be gitignored, which broke builds).
- `build/` and `*.pdx` are ignored.
