"""
Placeholder launcher icons until real branding exists.

Draws a white "৳" on the theme blue (#136AEE) and, for the dev and staging
flavours, a coloured band so test builds are easy to tell apart on a phone.
Writes 1024px sources into assets/icon/; flutter_launcher_icons turns them
into the Android and iOS sizes:

    python tool/make_icons.py          (needs Pillow)
    dart run flutter_launcher_icons
"""
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / 'assets' / 'icon'
FONT = ROOT / 'fonts' / 'HindSiliguri' / 'HindSiliguri-Bold.ttf'
BLUE = (0x13, 0x6A, 0xEE, 255)
SIZE = 1024

BANDS = {'dev': ('DEV', (0xF5, 0x9E, 0x0B, 255)), 'staging': ('STG', (0x6F, 0x32, 0xFD, 255))}


def glyph(draw, box_size, scale):
    font = ImageFont.truetype(str(FONT), int(box_size * scale))
    left, top, right, bottom = draw.textbbox((0, 0), '৳', font=font)
    x = (box_size - (right - left)) / 2 - left
    y = (box_size - (bottom - top)) / 2 - top
    draw.text((x, y), '৳', font=font, fill='white')


def band(image, label, colour):
    draw = ImageDraw.Draw(image)
    height = SIZE // 5
    draw.rectangle([0, SIZE - height, SIZE, SIZE], fill=colour)
    font = ImageFont.truetype(str(FONT), int(height * 0.7))
    left, top, right, bottom = draw.textbbox((0, 0), label, font=font)
    draw.text(((SIZE - (right - left)) / 2 - left, SIZE - height + (height - (bottom - top)) / 2 - top),
              label, font=font, fill='white')


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    for flavour in ('prod', 'dev', 'staging'):
        # Full icon (iOS, legacy Android): blue square, glyph in the middle
        full = Image.new('RGBA', (SIZE, SIZE), BLUE)
        glyph(ImageDraw.Draw(full), SIZE, 0.62)
        # Adaptive foreground: the launcher masks to a circle or squircle, so
        # keep the glyph inside the central safe zone
        foreground = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
        glyph(ImageDraw.Draw(foreground), SIZE, 0.40)
        if flavour in BANDS:
            band(full, *BANDS[flavour])
            band(foreground, *BANDS[flavour])
        full.save(OUT / f'icon_{flavour}.png')
        foreground.save(OUT / f'foreground_{flavour}.png')
    print(f'wrote {OUT}')


if __name__ == '__main__':
    main()
