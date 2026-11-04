#!/usr/bin/env bash
# Build the capture copy of the game used by screenshots.sh and video.sh.
#   scripts/capture/build_capture.sh <mode> <absolute output dir>
# mode: "shots" or "video". The real source/ is untouched: the game is copied
# to build/capture-src, the driver appended to main.lua there, and the copy
# given its own bundle ID so it never touches the real game's saved data.
set -euo pipefail
cd "$(dirname "$0")/../.."
MODE="$1"
OUT="$2"
SDK="${PLAYDATE_SDK_PATH:-$HOME/Developer/PlaydateSDK}"
SRC="build/capture-src"
PDX="build/CrankAndCatchCapture.pdx"

mkdir -p "$OUT" build
rsync -a --delete --exclude '*.mp3' source/ "$SRC/"
cp scripts/capture/capture_driver.lua "$SRC/capture_driver.lua"
printf 'CAPTURE_OUT = "%s"\nCAPTURE_MODE = "%s"\n' "$OUT" "$MODE" > "$SRC/capture_config.lua"
printf '\nimport "capture_driver"\n' >> "$SRC/main.lua"
sed -i '' 's/^bundleID=.*/bundleID=com.mrballistic.crankandcatch.capture/; s/^name=.*/name=Crank \& Catch (capture)/' "$SRC/pdxinfo"
"$SDK/bin/pdc" "$SRC" "$PDX"
echo "$PDX"
