"""Contact sheet of rendered characters for quick review.

    python -I app/tool/chars/contact_sheet.py --src <png dir> --out sheet.png [--size 128] [--cols 8] [--ids a,b,c]
    python -I app/tool/chars/contact_sheet.py --assets --out sheet.png          # sheet of the shipped webp assets

Each cell shows the avatar on a dark background with its id underneath.
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
ASSETS = os.path.normpath(os.path.join(HERE, '..', '..', 'assets', 'avatars'))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--src', default='', help='directory with <id>.png (renders) ')
    ap.add_argument('--assets', action='store_true', help='read app/assets/avatars/*.webp instead')
    ap.add_argument('--out', required=True)
    ap.add_argument('--size', type=int, default=128)
    ap.add_argument('--cols', type=int, default=8)
    ap.add_argument('--ids', default='')
    a = ap.parse_args()

    folder, ext = (ASSETS, '.webp') if a.assets else (a.src, '.png')
    ids = [i for i in a.ids.split(',') if i] or sorted(f[:-len(ext)] for f in os.listdir(folder) if f.endswith(ext))
    cell = a.size
    label = 16
    rows = (len(ids) + a.cols - 1) // a.cols
    sheet = Image.new('RGBA', (a.cols * cell, rows * (cell + label)), (36, 28, 38, 255))
    d = ImageDraw.Draw(sheet)
    for k, i in enumerate(ids):
        p = os.path.join(folder, i + ext)
        if not os.path.exists(p):
            continue
        im = Image.open(p).convert('RGBA').resize((cell, cell), Image.LANCZOS)
        x, y = (k % a.cols) * cell, (k // a.cols) * (cell + label)
        sheet.alpha_composite(im, (x, y))
        d.text((x + 4, y + cell + 2), i, fill=(230, 220, 200, 255))
    sheet.convert('RGB').save(a.out)
    print(a.out, len(ids), 'avatars')
    return 0


if __name__ == '__main__':
    sys.exit(main())
