"""
Launcher icons from the Spendroo brand kit.

Sources in assets/icon/source/ are copied from
"Spendroo Business Files/Brand/Spendroo Logo" (png/mark/spendroo-mark-1024w.png,
app-icon/android-adaptive/foreground-1024.png and monochrome-1024.png). Prod
gets the brand icon as is: the mark on white. Dev and staging get a tinted
background and a labelled band, so test builds are easy to tell apart on a
phone. Writes 1024px images into assets/icon/; flutter_launcher_icons turns
them into the Android sizes:

    python tool/make_icons.py          (needs Pillow)
    dart run flutter_launcher_icons
"""
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT / 'assets' / 'icon' / 'source'
OUT = ROOT / 'assets' / 'icon'
FONT = ROOT / 'fonts' / 'HindSiliguri' / 'HindSiliguri-Bold.ttf'
SIZE = 1024
MARK_SCALE = 0.68  # the brand kit's app icon: mark spans 68% of the square

# flavour: (background, band label, band colour)
FLAVOURS = {
    'prod': ('#FFFFFF', None, None),
    'dev': ('#FFE7C7', 'DEV', '#D97706'),
    'staging': ('#E6DCFF', 'STG', '#6F32FD'),
}


def full_icon(background):
    """The mark centred on a solid square, as in app-icon/spendroo-icon-1024.png."""
    icon = Image.new('RGBA', (SIZE, SIZE), background)
    mark = Image.open(SOURCE / 'mark-1024.png').convert('RGBA')
    scale = SIZE * MARK_SCALE / max(mark.size)
    mark = mark.resize((round(mark.width * scale), round(mark.height * scale)), Image.LANCZOS)
    icon.alpha_composite(mark, ((SIZE - mark.width) // 2, (SIZE - mark.height) // 2))
    return icon


def band(image, label, colour, top, height):
    draw = ImageDraw.Draw(image)
    draw.rectangle([0, top, SIZE, top + height], fill=colour)
    font = ImageFont.truetype(str(FONT), int(height * 0.7))
    left, t, right, bottom = draw.textbbox((0, 0), label, font=font)
    draw.text(((SIZE - (right - left)) / 2 - left, top + (height - (bottom - t)) / 2 - t), label, font=font, fill='white')


def main():
    for flavour, (background, label, colour) in FLAVOURS.items():
        full = full_icon(background)
        # Adaptive foreground: already sized by the brand kit for the launcher's safe zone
        foreground = Image.open(SOURCE / 'foreground-1024.png').convert('RGBA')
        if label:
            band(full, label, colour, SIZE - SIZE // 5, SIZE // 5)
            # Launchers crop the outer sixth and round the rest, so keep the band central
            band(foreground, label, colour, int(SIZE * 0.66), SIZE // 8)
        full.convert('RGB').save(OUT / f'icon_{flavour}.png')
        foreground.save(OUT / f'foreground_{flavour}.png')
    print(f'wrote {OUT}')


if __name__ == '__main__':
    main()
