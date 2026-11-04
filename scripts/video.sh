#!/usr/bin/env bash
# Record a gameplay video from the Playdate Simulator and encode it for the web.
#   scripts/video.sh
#
# The capture driver (scripts/capture/capture_driver.lua, "video" mode) plays
# the attract-mode menu for 5 s, presses Start, plays a real game, and writes
# every frame. Highlight moments (Express, net narrowing, misses) are logged.
# This script then encodes, into www/assets/video/:
#   crank-and-catch-lcd.{mp4,webm}    Playdate screen tones (#312f28 / #b1afa8), 1200x720
#   crank-and-catch-1bit.{mp4,webm}   pure black and white, 1200x720
#   crank-and-catch-poster-lcd.png    first gameplay frame, for the <video> poster
#   crank-and-catch-loop-lcd.gif      short silent loop, 800x480
#   crank-and-catch-screen-400x240.{mp4,webm}  native size in the device photo's
#                                     LCD tones, for overlaying on that photo
# Needs ffmpeg. The video is silent (the driver mutes sound), which suits
# autoplaying muted web video.
set -euo pipefail
cd "$(dirname "$0")/.."
ROOT="$(pwd)"
SDK="${PLAYDATE_SDK_PATH:-$HOME/Developer/PlaydateSDK}"
RAW="$ROOT/build/video"
DEST="$ROOT/www/assets/video"
LOG="$SDK/Disk/Data/com.mrballistic.crankandcatch.capture/capturelog.json"

command -v ffmpeg >/dev/null || { echo "ffmpeg not found (brew install ffmpeg)" >&2; exit 1; }
mkdir -p "$RAW/frames" "$DEST"
find "$RAW/frames" -name 'f*.png' -delete
# Start from no high score, so the menu shows its hints rather than a score
# left over from earlier capture runs. (Only the capture build's own save.)
rm -f "$SDK/Disk/Data/com.mrballistic.crankandcatch.capture/data.json"

PDX="$(scripts/capture/build_capture.sh video "$RAW" | tail -1)"
STAMP="$(date +%s)"
open -a "$SDK/bin/Playdate Simulator.app" "$PDX"
echo "Recording in the simulator..."

for _ in $(seq 1 300); do
    if [[ -f "$LOG" && "$(stat -f %m "$LOG")" -ge "$STAMP" ]] && grep -q '"video done"' "$LOG"; then break; fi
    sleep 1
done
grep -q '"video done"' "$LOG" || { echo "Recording did not finish (check the simulator console)." >&2; exit 1; }
COUNT="$(find "$RAW/frames" -name 'f*.png' | wc -l | tr -d ' ')"
echo "Captured $COUNT frames."
cp "$LOG" "$RAW/capturelog.json"

# 1-bit frames: black -> #312f28 (49,47,40), white -> #b1afa8 (177,175,168).
LCD="lutrgb=r='49+val*128/255':g='47+val*128/255':b='40+val*128/255'"
UP="scale=iw*3:ih*3:flags=neighbor"
IN=(-framerate 30 -start_number 1 -i "$RAW/frames/f%05d.png")

for look in lcd 1bit; do
    if [[ $look == lcd ]]; then VF="$LCD,$UP"; else VF="$UP"; fi
    ffmpeg -loglevel error -y "${IN[@]}" -vf "$VF,format=yuv420p" \
        -c:v libx264 -preset slow -crf 14 -tune animation -movflags +faststart \
        "$DEST/crank-and-catch-$look.mp4"
    ffmpeg -loglevel error -y "${IN[@]}" -vf "$VF,format=yuv420p" \
        -c:v libvpx-vp9 -b:v 0 -crf 24 -row-mt 1 \
        "$DEST/crank-and-catch-$look.webm"
done

# Native-size variant in the tones of the lit LCD in Panic's device photo
# (#202122 / #cbccc7), for overlaying on that photo with a CSS matrix3d.
DEV="lutrgb=r='32+val*171/255':g='33+val*171/255':b='34+val*165/255'"
ffmpeg -loglevel error -y "${IN[@]}" -vf "$DEV,format=yuv420p" \
    -c:v libx264 -preset slow -crf 12 -tune animation -movflags +faststart \
    "$DEST/crank-and-catch-screen-400x240.mp4"
ffmpeg -loglevel error -y "${IN[@]}" -vf "$DEV,format=yuv420p" \
    -c:v libvpx-vp9 -b:v 0 -crf 20 -row-mt 1 \
    "$DEST/crank-and-catch-screen-400x240.webm"

# Screen-sized poster for the native-size variant (a <video> poster fills the
# video's own box, so it must match the 400x240 screen, not the device photo).
ffmpeg -loglevel error -y -i "$RAW/frames/$(printf 'f%05d.png' 160)" -vf "$DEV" \
    "$DEST/crank-and-catch-screen-poster-400x240.png"

# Poster: the first frame after Start (frame 150 is the press), LCD tones.
ffmpeg -loglevel error -y -i "$RAW/frames/$(printf 'f%05d.png' 160)" -vf "$LCD,$UP" \
    "$DEST/crank-and-catch-poster-lcd.png"

# GIF loop: 6 s of gameplay from 10 s in, 2x, 15 fps, two-color palette.
ffmpeg -loglevel error -y -framerate 30 -start_number 300 -i "$RAW/frames/f%05d.png" -t 6 \
    -vf "$LCD,fps=15,scale=iw*2:ih*2:flags=neighbor,split[a][b];[a]palettegen=max_colors=4[p];[b][p]paletteuse=dither=none" \
    "$DEST/crank-and-catch-loop-lcd.gif"

ls -la "$DEST"
echo "Highlights (frame: popup):"
python3 -c "import json,sys; [print(f\"  {e['frame']}: {e['text']}\") for e in json.load(open(sys.argv[1])).get('events', [])]" "$RAW/capturelog.json"
