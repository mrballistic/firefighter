#!/usr/bin/env bash
# Build the game, optionally open it in the Playdate Simulator.
#   scripts/build.sh          # build to build/CrankAndCatch.pdx
#   scripts/build.sh --run    # build, then launch the simulator
#   scripts/build.sh --test   # run the SDK-free tests only (unit + headless smoke)
set -euo pipefail
cd "$(dirname "$0")/.."

if [[ "${1:-}" == "--test" ]]; then
    lua tests/run.lua && lua tests/smoke.lua && SMOKE_ART=1 exec lua tests/smoke.lua
fi

SDK="${PLAYDATE_SDK_PATH:-$HOME/Developer/PlaydateSDK}"
if [[ ! -x "$SDK/bin/pdc" ]]; then
    echo "Playdate SDK not found at $SDK (set PLAYDATE_SDK_PATH). Download: https://play.date/dev/" >&2
    exit 1
fi

lua tests/run.lua
lua tests/smoke.lua
SMOKE_ART=1 lua tests/smoke.lua
mkdir -p build
"$SDK/bin/pdc" source build/CrankAndCatch.pdx
echo "Built build/CrankAndCatch.pdx"

if [[ "${1:-}" == "--run" ]]; then
    open -a "$SDK/bin/Playdate Simulator.app" build/CrankAndCatch.pdx
fi
