"""ملصقات S1: PNG شفاف (من s1_sticker_render_test.dart) -> قص أبيض (die-cut) + ظل -> webp ٢٥٦.

Run (always with -I):

    python -I app/tool/chars/s1_sticker_export.py --src <png dir> [--ids b_laugh,b_think] [--out app/assets/stickers]
    python -I app/tool/chars/s1_sticker_export.py --src <png dir> --sheet <out.png> [--cell 256] [--cols 6] [--bg parchment|dark]

The white border is built from the alpha of the render: distance-transform dilation, holes filled,
corners smoothed; then a faint dark edge and a soft shadow so it also reads on parchment.
"""
import argparse
import os
import sys

import cv2
import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
DEFAULT_OUT = os.path.normpath(os.path.join(HERE, '..', '..', 'assets', 'stickers'))

SRC_PX = 1024
FRAME = 216.0           # units across the render (see s1_sticker.dart)
BORDER_UNITS = 6.2      # white border width in frame units
EDGE_UNITS = 1.0        # faint dark edge outside the white
INK = np.array([0x20, 0x15, 0x2A], np.float32) / 255.0  # BGR of #2A1520


def die_cut(rgba):
    """rgba: float32 HxWx4 straight alpha 0..1 (BGRA). Returns premultiplied float32 BGRA."""
    s = rgba.shape[0] / FRAME
    a = rgba[..., 3]
    mask = a > 0.04
    r = BORDER_UNITS * s
    inv = (~mask).astype(np.uint8)
    dist = cv2.distanceTransform(inv, cv2.DIST_L2, 5)
    cut = (dist <= r).astype(np.float32)
    # round off notches / small concave corners
    k = max(3, int(r * 0.55) | 1)
    cut = cv2.GaussianBlur(cut, (0, 0), r * 0.42)
    cut = (cut > 0.5).astype(np.uint8)
    # fill holes: everything not reachable from the border is inside
    h, w = cut.shape
    ff = cut.copy() * 255
    pad = np.zeros((h + 2, w + 2), np.uint8)
    cv2.floodFill(ff, pad, (0, 0), 128)
    cut = (ff != 128).astype(np.uint8)
    cutf = cv2.GaussianBlur(cut.astype(np.float32), (0, 0), 0.9 * s)  # anti-aliased edge
    # faint dark edge
    e = EDGE_UNITS * s
    edge_mask = (cv2.distanceTransform((1 - cut).astype(np.uint8), cv2.DIST_L2, 5) <= e).astype(np.float32)
    edge_mask = cv2.GaussianBlur(edge_mask, (0, 0), 0.9 * s)
    # soft shadow
    sh = cv2.GaussianBlur(cut.astype(np.float32), (0, 0), 2.6 * s)
    M = np.float32([[1, 0, 0.0], [0, 1, 1.9 * s]])
    sh = cv2.warpAffine(sh, M, (w, h))

    out = np.zeros((h, w, 4), np.float32)   # premultiplied BGRA

    def over(layer_rgb, layer_a):
        nonlocal out
        la = layer_a[..., None]
        out = out * (1 - la) + np.concatenate([layer_rgb * la, la], axis=2)

    over(np.broadcast_to(np.float32([0.1, 0.07, 0.12]), (h, w, 3)), sh * 0.30)
    over(np.broadcast_to(INK, (h, w, 3)), np.clip(edge_mask, 0, 1) * 0.55)
    over(np.broadcast_to(np.float32([0.985, 0.99, 1.0]), (h, w, 3)), cutf)
    fa = rgba[..., 3]
    over(rgba[..., :3], fa)
    return out


def export_one(src, dst, size=256):
    im = cv2.imread(src, cv2.IMREAD_UNCHANGED)
    if im is None:
        raise SystemExit(f'cannot read {src}')
    if im.shape[2] == 3:
        im = np.dstack([im, np.full(im.shape[:2], 255, np.uint8)])
    f = im.astype(np.float32) / 255.0
    out = die_cut(f)
    out = cv2.resize(out, (size, size), interpolation=cv2.INTER_AREA)
    a = out[..., 3:4]
    rgb = np.where(a > 1e-4, out[..., :3] / np.maximum(a, 1e-4), 0)
    bgra = np.concatenate([np.clip(rgb, 0, 1), np.clip(a, 0, 1)], axis=2)
    u8 = (bgra * 255 + 0.5).astype(np.uint8)
    rgba = cv2.cvtColor(u8, cv2.COLOR_BGRA2RGBA)
    img = Image.fromarray(rgba, 'RGBA')
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    img.save(dst, 'WEBP', quality=90, method=6, lossless=False, exact=True)
    return os.path.getsize(dst)


def sheet(files, out, cell=256, cols=6, bg='parchment', labels=True):
    from PIL import ImageDraw
    rows = (len(files) + cols - 1) // cols
    colors = {'parchment': (226, 196, 142, 255), 'dark': (46, 26, 30, 255), 'wood': (92, 62, 40, 255)}
    im = Image.new('RGBA', (cell * cols, cell * rows), colors.get(bg, colors['parchment']))
    d = ImageDraw.Draw(im)
    for i, f in enumerate(files):
        s = Image.open(f).convert('RGBA')
        if s.size != (cell, cell):
            s = s.resize((cell, cell), Image.LANCZOS)
        x, y = (i % cols) * cell, (i // cols) * cell
        im.alpha_composite(s, (x, y))
        if labels:
            d.text((x + 3, y + 2), os.path.basename(f)[:-5], fill=(40, 20, 10, 255))
    im.save(out)
    print(out)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--src', required=True, help='directory with <id>.png from s1_sticker_render_test.dart')
    ap.add_argument('--out', default=DEFAULT_OUT, help='assets/stickers directory')
    ap.add_argument('--ids', default='', help='comma separated ids (default: every png)')
    ap.add_argument('--sheet', default='', help='write a contact sheet of the exported webp files instead of exporting')
    ap.add_argument('--cell', type=int, default=256)
    ap.add_argument('--cols', type=int, default=6)
    ap.add_argument('--bg', default='parchment')
    ap.add_argument('--nolabels', action='store_true')
    args = ap.parse_args()
    ids = [i for i in args.ids.split(',') if i] or sorted(f[:-4] for f in os.listdir(args.src) if f.endswith('.png'))
    if args.sheet:
        sheet([os.path.join(args.out, i + '.webp') for i in ids], args.sheet, args.cell, args.cols, args.bg, not args.nolabels)
        return 0
    for i in ids:
        p = os.path.join(args.src, i + '.png')
        if not os.path.exists(p):
            print('missing', p)
            continue
        n = export_one(p, os.path.join(args.out, i + '.webp'))
        print(f'{i}: {n} bytes')
    return 0


if __name__ == '__main__':
    sys.exit(main())
