"""Crop the title lettering out of the launcher card into source/images/title.png.

    uv run --with pillow python scripts/make_title.py

The menu screen shows this image as its title, so the game and its card share
the same lettering. Re-run after changing the card. The box below is the
"CRANK & CATCH / BOUNCE TO SAFETY" block on the current card; adjust it if the
card layout moves. Output is opaque black with padding, so stars in the
background art never touch the letters.
"""
from PIL import Image

CARD = "source/images/launcher/card.png"
OUT = "source/images/title.png"
BOX = (64, 14, 295, 59)  # left, top, right (exclusive), bottom (exclusive)
PAD = 4

card = Image.open(CARD).convert("RGBA")
title = card.crop(BOX)
out = Image.new("RGBA", (title.width + 2 * PAD, title.height + 2 * PAD), (0, 0, 0, 255))
out.paste(title, (PAD, PAD))
out.save(OUT)
print(f"{OUT}: {out.width}x{out.height}")
