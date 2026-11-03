"""Crop the title lettering out of the launcher card into source/images/title.png.

    uv run --with pillow python scripts/make_title.py

The menu screen shows this image as its title, so the game and its card share
the same lettering. Re-run after changing the card. The title and subtitle
are cropped separately and the subtitle is centered under the title (on the
card it's left-aligned); adjust the boxes if the card layout moves. Output is opaque black with padding, so stars in the
background art never touch the letters.
"""
from PIL import Image

CARD = "source/images/launcher/card.png"
OUT = "source/images/title.png"
# Boxes on the current card: left, top, right (exclusive), bottom (exclusive).
TITLE_BOX = (64, 14, 295, 40)     # "CRANK & CATCH" plus its underline
SUBTITLE_BOX = (64, 45, 254, 59)  # "BOUNCE TO SAFETY" (left-aligned on the card)
GAP = 5                            # rows between underline and subtitle, as on the card
PAD = 4

card = Image.open(CARD).convert("RGBA")
title = card.crop(TITLE_BOX)
subtitle = card.crop(SUBTITLE_BOX)

width = max(title.width, subtitle.width) + 2 * PAD
height = title.height + GAP + subtitle.height + 2 * PAD
out = Image.new("RGBA", (width, height), (0, 0, 0, 255))
out.paste(title, ((width - title.width) // 2, PAD))
# The menu centers everything, so center the subtitle under the title.
out.paste(subtitle, ((width - subtitle.width) // 2, PAD + title.height + GAP))
out.save(OUT)
print(f"{OUT}: {out.width}x{out.height}")
