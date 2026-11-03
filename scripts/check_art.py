"""Check that every image in source/images is Playdate-safe 1-bit art.

Usage (needs Pillow; uv fetches it on the fly):
    uv run --with pillow python scripts/check_art.py

Reports, per PNG: its size, and pixel counts of pure black, pure white,
fully transparent, and anything else (greys, colours, partial alpha). Anything
in the last two columns will be thresholded unpredictably by pdc.
Also checks each *-table-W-H.png divides evenly into W x H frames.
"""
import glob
import re
import sys

from PIL import Image

bad = False
for f in sorted(glob.glob("source/images/**/*.png", recursive=True)):
    im = Image.open(f).convert("RGBA")
    counts = {"black": 0, "white": 0, "clear": 0, "other": 0, "semi": 0}
    data = im.tobytes()
    for i in range(0, len(data), 4):
        r, g, b, a = data[i], data[i + 1], data[i + 2], data[i + 3]
        if a == 0:
            counts["clear"] += 1
        elif a < 255:
            counts["semi"] += 1
        elif (r, g, b) == (0, 0, 0):
            counts["black"] += 1
        elif (r, g, b) == (255, 255, 255):
            counts["white"] += 1
        else:
            counts["other"] += 1
    note = ""
    m = re.search(r"-table-(\d+)-(\d+)\.png$", f)
    if m:
        fw, fh = int(m.group(1)), int(m.group(2))
        if im.width % fw or im.height % fh:
            note = f"  !! does not divide into {fw}x{fh} frames"
            bad = True
        else:
            note = f"  ({(im.width // fw) * (im.height // fh)} frames)"
    if counts["other"] or counts["semi"]:
        bad = True
    print(f"{f:46} {im.width:>3}x{im.height:<3} "
          f"black={counts['black']:<6} white={counts['white']:<6} clear={counts['clear']:<6} "
          f"other={counts['other']:<5} semi-alpha={counts['semi']:<5}{note}")

sys.exit(1 if bad else 0)
