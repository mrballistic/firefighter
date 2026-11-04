#!/usr/bin/env bash
# Capture real gameplay screenshots from the Playdate Simulator.
#   scripts/screenshots.sh
#
# Builds a copy of the game with scripts/capture/capture_driver.lua appended
# (the real source/ is untouched), runs it in the simulator, where it plays
# itself at 8x speed and writes PNGs at set moments, then quits. Outputs, in
# screenshots/:
#   NN-name.png       400x240, the Playdate's native resolution (1-bit)
#   NN-name@2x.png    800x480, pixel-doubled for web/store use (needs uv + Pillow)
set -euo pipefail
cd "$(dirname "$0")/.."
ROOT="$(pwd)"

SDK="${PLAYDATE_SDK_PATH:-$HOME/Developer/PlaydateSDK}"
OUT="$ROOT/screenshots"
SHOTS=(01-menu 02-two-up)

PDX="$(scripts/capture/build_capture.sh shots "$OUT" | tail -1)"

# Only files written after this moment count as this run's output.
STAMP="$(date +%s)"

open -a "$SDK/bin/Playdate Simulator.app" "$PDX"
echo "Simulator running the capture build..."

for _ in $(seq 1 180); do
    done_count=0
    for s in "${SHOTS[@]}"; do
        f="$OUT/$s.png"
        if [[ -f "$f" && "$(stat -f %m "$f")" -ge "$STAMP" ]]; then done_count=$((done_count + 1)); fi
    done
    [[ $done_count -eq ${#SHOTS[@]} ]] && break
    sleep 1
done

missing=0
for s in "${SHOTS[@]}"; do
    f="$OUT/$s.png"
    if [[ -f "$f" && "$(stat -f %m "$f")" -ge "$STAMP" ]]; then echo "  $f"; else echo "  MISSING $s"; missing=1; fi
done
[[ $missing -eq 0 ]] || { echo "Some shots were not captured (check the simulator console)." >&2; exit 1; }

if command -v uv >/dev/null; then
    uv run -q --with pillow python - "$OUT" "${SHOTS[@]}" <<'EOF'
import sys
from PIL import Image
out, names = sys.argv[1], sys.argv[2:]
for n in names:
    im = Image.open(f"{out}/{n}.png")
    im.resize((im.width * 2, im.height * 2), Image.NEAREST).save(f"{out}/{n}@2x.png")
    print(f"  {out}/{n}@2x.png")
EOF
fi
