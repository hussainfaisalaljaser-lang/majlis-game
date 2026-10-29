"""Sticker export (worker S2): die-cut border + shadow + 256 webp, contact sheets, crop metadata.

    python -I tool/chars/s2_export.py --src <png dir> [--ids a,b] [--out app/assets/stickers] [--dev <dir>]
    python -I tool/chars/s2_export.py --sheet <out.png> [--ids a,b] [--size 128] [--cols 6]

Input  : <src>/<id>.png  (1024x1024 RGBA from s2_sticker_test.dart: figure + caption banner)
Output : <out>/<id>.webp  256x256 RGBA (white die-cut border, soft shadow), quality 90, method 6
         <dev>/meta.json  per id: the window of the 200-unit sticker canvas that ended up in the 256 image
                          (x0, y0, side): a canvas point (x, y) sits at ((x-x0)/side, (y-y0)/side) of the image.
"""
import argparse
import json
import os
import sys

import cv2
import numpy as np
from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
ASSETS = os.path.normpath(os.path.join(HERE, '..', '..', 'assets', 'stickers'))


def diecut(path, out=256, border=0.030):
    im = np.array(Image.open(path).convert('RGBA'))
    H, W = im.shape[:2]
    a = im[..., 3]
    ys, xs = np.nonzero(a > 10)
    x0, x1, y0, y1 = xs.min(), xs.max(), ys.min(), ys.max()
    size = max(x1 - x0, y1 - y0)
    B = int(round(border * size))
    sh = int(round(B * 0.9))
    pad = B * 2 + sh + 6
    side = size + 2 * pad
    cx, cy = (x0 + x1) / 2.0, (y0 + y1) / 2.0
    ox, oy = int(round(cx - side / 2)), int(round(cy - side / 2))
    can = np.zeros((side, side, 4), np.uint8)
    sx0, sy0 = max(ox, 0), max(oy, 0)
    sx1, sy1 = min(ox + side, W), min(oy + side, H)
    can[sy0 - oy:sy1 - oy, sx0 - ox:sx1 - ox] = im[sy0:sy1, sx0:sx1]
    art = can.astype(np.float32) / 255.0
    alpha = art[..., 3]
    mask = (alpha > 0.04).astype(np.uint8) * 255
    k = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (2 * B + 1, 2 * B + 1))
    dil = cv2.dilate(mask, k)
    # close small gaps / concave pockets so the die-cut reads as one clean sticker shape
    dil = cv2.morphologyEx(dil, cv2.MORPH_CLOSE, k)
    soft = cv2.GaussianBlur(dil.astype(np.float32) / 255.0, (0, 0), max(B * 0.18, 0.8))
    white_a = np.clip((soft - 0.5) * 3.0 + 0.5, 0, 1)
    shadow_a = cv2.GaussianBlur(white_a, (0, 0), B * 0.75) * 0.42
    shadow_a = np.roll(shadow_a, sh, axis=0)
    # premultiplied accumulation of the three layers (shadow, white border, art)
    pm = np.zeros((side, side, 4), np.float32)

    def put(rgb, a):
        a3 = a[..., None]
        pm[..., :3] = rgb * a3 + pm[..., :3] * (1 - a3)
        pm[..., 3] = a + pm[..., 3] * (1 - a)

    put(np.array([0.12, 0.05, 0.08], np.float32), shadow_a)
    put(np.array([1.0, 1.0, 1.0], np.float32), white_a)
    put(art[..., :3], alpha)
    small = cv2.resize(pm, (out, out), interpolation=cv2.INTER_AREA)
    sa = small[..., 3:4]
    rgb = np.where(sa > 1e-4, small[..., :3] / np.maximum(sa, 1e-4), 0)
    fin = np.concatenate([np.clip(rgb, 0, 1), np.clip(sa, 0, 1)], axis=2)
    img = Image.fromarray((fin * 255 + 0.5).astype(np.uint8), 'RGBA')
    u = 200.0 / W
    return img, dict(x0=ox * u, y0=oy * u, side=side * u)


def sheet(ids, folder, out, size, cols):
    label = 14
    rows = (len(ids) + cols - 1) // cols
    sh = Image.new('RGBA', (cols * size, rows * (size + label)), (200, 170, 120, 255))
    d = ImageDraw.Draw(sh)
    for k, i in enumerate(ids):
        p = os.path.join(folder, i + '.webp')
        if not os.path.exists(p):
            continue
        im = Image.open(p).convert('RGBA').resize((size, size), Image.LANCZOS)
        x, y = (k % cols) * size, (k // cols) * (size + label)
        sh.alpha_composite(im, (x, y))
        d.text((x + 3, y + size), i, fill=(30, 20, 10, 255))
    sh.convert('RGB').save(out)
    print(out, len(ids))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--src', default='')
    ap.add_argument('--out', default=ASSETS)
    ap.add_argument('--dev', default='')
    ap.add_argument('--ids', default='')
    ap.add_argument('--sheet', default='')
    ap.add_argument('--size', type=int, default=128)
    ap.add_argument('--cols', type=int, default=6)
    ap.add_argument('--no-write', action='store_true', help='only write the dev preview, not the assets')
    a = ap.parse_args()
    ids = [i for i in a.ids.split(',') if i]
    if a.sheet:
        if not ids:
            ids = sorted(f[:-5] for f in os.listdir(a.out) if f.endswith('.webp'))
        sheet(ids, a.out, a.sheet, a.size, a.cols)
        return 0
    ids = ids or sorted(f[:-4] for f in os.listdir(a.src) if f.endswith('.png'))
    meta_path = os.path.join(a.dev or a.src, 'meta.json')
    meta = json.load(open(meta_path)) if os.path.exists(meta_path) else {}
    for i in ids:
        p = os.path.join(a.src, i + '.png')
        if not os.path.exists(p):
            print('missing', p, file=sys.stderr)
            continue
        img, m = diecut(p)
        meta[i] = m
        if not a.no_write:
            os.makedirs(a.out, exist_ok=True)
            img.save(os.path.join(a.out, i + '.webp'), 'WEBP', quality=90, method=6, exact=True)
        if a.dev:
            os.makedirs(a.dev, exist_ok=True)
            img.save(os.path.join(a.dev, i + '_256.png'))
    os.makedirs(os.path.dirname(meta_path), exist_ok=True)
    json.dump(meta, open(meta_path, 'w'), indent=1)
    print('exported', len(ids))
    return 0


if __name__ == '__main__':
    sys.exit(main())
