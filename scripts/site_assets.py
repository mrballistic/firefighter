"""Build the static web assets for the game's web page into www/assets/.

    uv run --with pillow python scripts/site_assets.py

Inputs: screenshots/ (scripts/screenshots.sh), build/video/frames/
(scripts/video.sh) and source/images/. Run those first.

Two looks throughout:
  1bit  pure black and white, exactly as the game draws it
  lcd   Playdate screen tones: black -> #312f28, white -> #b1afa8
Pixel art is only ever scaled by whole numbers with nearest-neighbor, so
every game pixel stays a crisp square.
"""
import os
from PIL import Image

OUT = "www/assets"
DARK, LIGHT = (0x31, 0x2F, 0x28), (0xB1, 0xAF, 0xA8)
PAGE_BG = (0x1D, 0x1C, 0x18)  # darkest gray, for composed images

# Moments picked from the recorded video (frame numbers from its highlight log).
VIDEO_STILLS = {
    "03-express": 625,         # EXPRESS +150 popup by the ambulance
    "04-net-narrows": 756,     # first net narrowing, popups stacked
    "05-late-game": 1222,      # 1,000+ points, narrower net
}


def up(img, k):
    return img.resize((img.width * k, img.height * k), Image.NEAREST)


def lcd(img):
    """Map black/white to the LCD tones, keeping any transparency."""
    rgba = img.convert("RGBA")
    out = Image.new("RGBA", rgba.size)
    px, po = rgba.load(), out.load()
    for y in range(rgba.height):
        for x in range(rgba.width):
            r, g, b, a = px[x, y]
            c = LIGHT if (r + g + b) > 382 else DARK
            po[x, y] = (*c, a)
    return out


def save(img, path):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.save(path)
    print(f"  {path}  {img.width}x{img.height}")


def screenshots():
    print("screenshots/")
    sources = {"01-menu": "screenshots/01-menu.png", "02-two-up": "screenshots/02-two-up.png"}
    for name, frame in VIDEO_STILLS.items():
        sources[name] = f"build/video/frames/f{frame:05d}.png"
    for name, path in sources.items():
        img = Image.open(path).convert("RGB")
        save(img, f"{OUT}/screenshots/{name}-1bit.png")
        save(up(img, 3), f"{OUT}/screenshots/{name}-1bit@3x.png")
        save(up(lcd(img), 3).convert("RGB"), f"{OUT}/screenshots/{name}-lcd@3x.png")


def art():
    print("art/")
    pieces = {  # file in source/images -> scale
        "title.png": 4,
        "victim-table-15-15.png": 8,
        "firefighters-table-48-20.png": 6,
        "building-table-40-200.png": 3,
        "ambulance.png": 6,
        "smoke-table-64-24.png": 4,
        "launcher/card.png": 3,
        "launcher/icon.png": 8,
    }
    for src, k in pieces.items():
        img = Image.open(f"source/images/{src}").convert("RGBA")
        base = os.path.splitext(os.path.basename(src))[0]
        save(up(img, k), f"{OUT}/art/{base}-1bit@{k}x.png")
        save(up(lcd(img), k), f"{OUT}/art/{base}-lcd@{k}x.png")
    # Individual jumper frames, handy as decorative "falling people"
    sheet = Image.open("source/images/victim-table-15-15.png").convert("RGBA")
    for i in range(sheet.width // 15):
        frame = sheet.crop((i * 15, 0, i * 15 + 15, 15))
        save(up(lcd(frame), 8), f"{OUT}/art/jumper-frame{i + 1}-lcd@8x.png")


def icons():
    print("icons/")
    icon = lcd(Image.open("source/images/launcher/icon.png")).convert("RGB")  # 32x32
    save(icon, f"{OUT}/icons/favicon-32.png")
    up(icon, 2).save(f"{OUT}/icons/favicon.ico", sizes=[(16, 16), (32, 32), (48, 48), (64, 64)])
    print(f"  {OUT}/icons/favicon.ico  16/32/48/64")
    save(up(icon, 6), f"{OUT}/icons/icon-192.png")
    save(up(icon, 16), f"{OUT}/icons/icon-512.png")
    touch = Image.new("RGB", (180, 180), DARK)  # 5x = 160, centered with a margin
    touch.paste(up(icon, 5), (10, 10))
    save(touch, f"{OUT}/icons/apple-touch-icon.png")


def social():
    print("social/")
    menu = lcd(Image.open("screenshots/01-menu.png")).convert("RGB")
    game = lcd(Image.open(f"build/video/frames/f{VIDEO_STILLS['04-net-narrows']:05d}.png")).convert("RGB")
    og = Image.new("RGB", (1200, 630), PAGE_BG)
    og.paste(up(menu, 2), (200, 75))  # 800x480, centered
    save(og, f"{OUT}/social/og-image-1200x630.png")
    hero = Image.new("RGB", (2520, 1080), PAGE_BG)
    hero.paste(up(game, 4), (460, 60))  # 1600x960, centered
    save(hero, f"{OUT}/social/hero-21x9-2520x1080.png")


if __name__ == "__main__":
    screenshots()
    art()
    icons()
    social()
