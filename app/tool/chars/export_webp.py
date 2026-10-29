"""Convert rendered character PNGs into the game's webp assets.

Run (always with -I, no site/user paths):

    python -I app/tool/chars/export_webp.py --src <png dir> [--ids youth,rose] [--out app/assets/avatars]
    python -I app/tool/chars/export_webp.py --src <png dir> --layers [--ids tycoon]

Composite  : <src>/<id>.png (1024x1024 RGBA, from render_test.dart)
             -> <out>/<id>.webp   512x512 RGBA, quality 92, method 6.
Rig layers : <src>/layers/<id>/<layer>.png (1200x1200, covers -20..220 units)
             -> <out>/anim/<id>/<layer>.webp   600x600 RGBA (same size as the old rig layers).

Corners outside the avatar circle stay transparent: the renderer clips to the circle
(or draws no background at all for `cutout` characters).
"""
import argparse
import os
import sys

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
DEFAULT_OUT = os.path.normpath(os.path.join(HERE, '..', '..', 'assets', 'avatars'))


def save_webp(img, path, size):
    img = img.convert('RGBA')
    if img.size != (size, size):
        img = img.resize((size, size), Image.LANCZOS)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.save(path, 'WEBP', quality=92, method=6, lossless=False, exact=True)
    return os.path.getsize(path)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--src', required=True, help='directory holding <id>.png (and layers/<id>/*.png)')
    ap.add_argument('--out', default=DEFAULT_OUT, help='assets/avatars directory')
    ap.add_argument('--ids', default='', help='comma separated ids (default: every png found)')
    ap.add_argument('--layers', action='store_true', help='export rig layers instead of the composite')
    args = ap.parse_args()

    ids = [i for i in args.ids.split(',') if i]
    if args.layers:
        root = os.path.join(args.src, 'layers')
        ids = ids or sorted(d for d in os.listdir(root) if os.path.isdir(os.path.join(root, d)))
        for i in ids:
            for f in sorted(os.listdir(os.path.join(root, i))):
                if not f.endswith('.png'):
                    continue
                name = f[:-4]
                dst = os.path.join(args.out, 'anim', i, name + '.webp')
                n = save_webp(Image.open(os.path.join(root, i, f)), dst, 600)
                print(f'{i}/{name}: {n} bytes')
        return 0

    ids = ids or sorted(f[:-4] for f in os.listdir(args.src) if f.endswith('.png'))
    for i in ids:
        p = os.path.join(args.src, i + '.png')
        if not os.path.exists(p):
            print('missing', p, file=sys.stderr)
            continue
        n = save_webp(Image.open(p), os.path.join(args.out, i + '.webp'), 512)
        print(f'{i}: {n} bytes')
    return 0


if __name__ == '__main__':
    sys.exit(main())
