"""أختام الشمع: الأوفياء (درع) والخونة (خنجر) والزعيم (خنجر وتاج). الرموز من أيقوناتنا (tools/art/icons.py).
تشغيل بعد icons.py:  python3 tools/art/seals.py app/assets/images"""
import io, sys, math
import numpy as np
import cairosvg
from PIL import Image, ImageFilter

import os
TW = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'build', 'icons') + '/'
S = 1024  # حجم الرسم (نصغره بعدين)

def blur(a, sigma):
    """تنعيم Gaussian على مصفوفة float (بدون تقريب لـ ٨ بت عشان ما تطلع خطوط)."""
    k = np.arange(-int(3 * sigma) - 1, int(3 * sigma) + 2)
    g = np.exp(-(k ** 2) / (2 * sigma ** 2)); g /= g.sum()
    a = np.apply_along_axis(lambda m: np.convolve(m, g, mode='same'), 0, a)
    return np.apply_along_axis(lambda m: np.convolve(m, g, mode='same'), 1, a)

def symbol_height(code, size, flip=False):
    png = cairosvg.svg2png(url=TW + code + '.svg', output_width=size, output_height=size)  # بدون الظل (cairosvg يتجاهل الفلاتر)
    im = Image.open(io.BytesIO(png)).convert('RGBA')
    if flip: im = im.transpose(Image.FLIP_LEFT_RIGHT)
    a = np.asarray(im).astype(float) / 255
    alpha = a[..., 3]
    lum = (0.3 * a[..., 0] + 0.59 * a[..., 1] + 0.11 * a[..., 2])
    # الشكل بارز، والتفاصيل الغامقة أعمق شوي
    h = alpha * (0.75 + 0.25 * lum)
    return blur(h, 2.4)

def seal(code, color, seed=1, flip=False, scale=0.52):
    rng = np.random.default_rng(seed)
    y, x = np.mgrid[0:S, 0:S].astype(float)
    cx = cy = S / 2
    dx, dy = x - cx, y - cy
    r = np.hypot(dx, dy)
    th = np.arctan2(dy, dx)
    R = S * 0.44
    ph = rng.uniform(0, 6.28, 4)
    edge = R * (1 + 0.035 * np.sin(5 * th + ph[0]) + 0.025 * np.sin(9 * th + ph[1]) + 0.015 * np.sin(17 * th + ph[2]))
    inside = np.clip((edge - r) / 2.0, 0, 1)  # حافة ناعمة
    d = np.clip(r / edge, 0, 1)
    height = np.sqrt(np.clip(1 - d ** 2, 0, 1)) * 0.6  # قبة
    height += np.exp(-((d - 0.80) / 0.045) ** 2) * 0.35  # الحلقة البارزة
    height -= (d < 0.74) * 0.12  # النص منخفض شوي (مكان الختم)
    # الرمز
    sym_size = int(R * 2 * scale)
    sh = np.zeros((S, S))
    sym = np.clip(symbol_height(code, sym_size, flip), 0, 1)
    o = (S - sym_size) // 2
    sh[o:o + sym_size, o:o + sym_size] = sym
    height += sh * 0.32
    height = blur(height, 2.0)
    # الإضاءة من فوق يسار
    gy, gx = np.gradient(height * 60)
    n = np.dstack([-gx, -gy, np.ones_like(gx)])
    n /= np.linalg.norm(n, axis=2, keepdims=True)
    L = np.array([-0.5, -0.6, 0.62]); L /= np.linalg.norm(L)
    diff = np.clip((n * L).sum(2), 0, 1)
    Hh = (L + np.array([0, 0, 1])); Hh /= np.linalg.norm(Hh)
    spec = np.clip((n * Hh).sum(2), 0, 1) ** 40
    base = np.array(color, float) / 255
    # الرمز ذهبي (كأنه مطبوع بورق ذهب) عشان يبان حتى وهو صغير
    gold = np.array([1.0, 0.80, 0.36])
    m = np.clip((sh - 0.15) * 3, 0, 1)[..., None]
    tint = base * (1 - m) + gold * m
    rgb = tint * (0.35 + 0.8 * diff[..., None]) + spec[..., None] * 0.55
    rgb = np.clip(rgb, 0, 1)
    out = np.dstack([rgb, inside])
    img = Image.fromarray((out * 255).astype(np.uint8), 'RGBA')
    # ظل خفيف تحت الختم
    shadow = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    sa = Image.fromarray((inside * 120).astype(np.uint8)).filter(ImageFilter.GaussianBlur(20))
    shadow.putalpha(sa)
    canvas = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    canvas.alpha_composite(shadow, (8, 16))
    canvas.alpha_composite(img)
    return canvas

if __name__ == '__main__':
    import io as _io
    out = sys.argv[1]
    BLUE, RED = (52, 110, 225), (196, 30, 52)
    seal('shield', BLUE, 3, scale=.5).resize((512, 512), Image.LANCZOS).save(f'{out}/seal_loyal.png', optimize=True)
    traitor = seal('dagger', RED, 7, scale=.56)
    traitor.resize((512, 512), Image.LANCZOS).save(f'{out}/seal_traitor.png', optimize=True)
    # الزعيم: ختم الخونة وتاجنا مايل على حافته
    crown = Image.open(_io.BytesIO(cairosvg.svg2png(url=TW + 'crown.svg', output_width=360, output_height=360))).convert('RGBA')
    crown = crown.rotate(-16, resample=Image.BICUBIC, expand=True)
    base = traitor.resize((840, 840), Image.LANCZOS)
    canvas = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    canvas.alpha_composite(base, ((S - 840) // 2 - 40, S - 840))
    shadow = Image.new('RGBA', crown.size, (0, 0, 0, 0))
    shadow.putalpha(crown.getchannel('A').point(lambda a: int(a * .5)).filter(ImageFilter.GaussianBlur(12)))
    canvas.alpha_composite(shadow, (470, 40))
    canvas.alpha_composite(crown, (458, 16))
    canvas.resize((512, 512), Image.LANCZOS).save(f'{out}/seal_leader.png', optimize=True)
    print('ok')
