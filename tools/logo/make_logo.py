"""يركّب أيقونة اللعبة: نفس الأيقونة القديمة (الخاين بالقلنسوة والعيون والهلال) لكن بكروت اللعبة الحقيقية
(ورقة بيضاء، نجمة زرقا للأوفياء ونجمة حمرا بخنجر للخونة) بدل الكروت الملوّنة القديمة.

الخطوات:
  1) كروت اللعبة: SHOT_DIR=<مجلد> flutter test tool/shots/logo_cards_test.dart   (يطلع logo_card_loyal.png و logo_card_traitor.png)
  2) python -I tools/logo/make_logo.py <مجلد الكروت> <الأيقونة القديمة> <المخرجات>
الأيقونة القديمة نحتفظ بنسخة منها في tools/logo/logo_old.png (الخاين والهلال والخلفية منها، والكروت القديمة تنشال).
"""

import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

cards_dir, old_path, out_dir = sys.argv[1], sys.argv[2], sys.argv[3]
os.makedirs(out_dir, exist_ok=True)

old = Image.open(old_path).convert('RGBA')
W = old.width
a = np.array(old).astype(np.float32)
alpha = a[..., 3]
rgb = a[..., :3]

# خلفية متدرجة عمودياً: نقرأها من عمود نظيف (يسار فوق الكروت) ونمددها لتحت
ys = np.arange(30, 285)
col = rgb[ys, 40]
coef = [np.polyfit(ys, col[:, c], 1) for c in range(3)]
bg = np.zeros_like(rgb)
for y in range(W):
    bg[y, :, :] = [np.polyval(coef[c], y) for c in range(3)]
bg = np.clip(bg, 0, 255)

# بكسلات الخاين: داكنة جداً أو إطار ذهبي (الكروت فاتحة أو ملونة)
dark = rgb.max(axis=2) < 70
gold = (rgb[..., 0] > 190) & (rgb[..., 1] > 130) & (rgb[..., 2] < 120) & (rgb[..., 0] - rgb[..., 2] > 100)
hoodish = (dark | gold) & (alpha > 128)

# المكوّن المتصل من نص الخاين = الخاين نفسه (من غير زخارف الكروت)
import cv2  # noqa: E402

n, lab = cv2.connectedComponents(hoodish.astype(np.uint8), connectivity=4)
hood = (lab == lab[420, 256]).astype(np.uint8)
hood = cv2.morphologyEx(hood, cv2.MORPH_CLOSE, np.ones((5, 5), np.uint8))
# نسد الثقوب (العيون والوجه): نملّي من الزاوية البرانية ونعكس
flood = hood.copy()
ff = np.zeros((W + 2, W + 2), np.uint8)
cv2.floodFill(flood, ff, (0, 0), 2)
hood = (flood != 2).astype(bool)
# الهلال: ذهبي فوق يمين، ما نلمسه (فوق الكروت)
crescent_zone = np.zeros_like(hood)
crescent_zone[:300, 300:] = True

# منطقة الكروت القديمة: أي بكسل فيه ألوان زاهية تحت y=280 مو من الخاين
yy, xx = np.mgrid[0:W, 0:W]
cardzone = (yy > 270) & (~hood) & (alpha > 0)

def build(cards, scale, clip):
    """تركيب الأيقونة. [clip]: نقص اللي برا الزوايا المدورة (للأيقونة)، وبدونه حواف كاملة (للأمامية المتكيفة)."""
    base = a.copy()
    base[..., :3] = np.where(cardzone[..., None], bg, base[..., :3])
    if not clip:
        # الزوايا الشفافة نملّيها بالتدرج
        corner = base[..., 3:4] < 255
        base[..., :3] = np.where(corner, bg, base[..., :3])
        base[..., 3] = 255
    out = Image.fromarray(np.clip(base, 0, 255).astype(np.uint8), 'RGBA')

    def card(name, angle, center):
        im = Image.open(os.path.join(cards_dir, f'logo_card_{name}.png')).convert('RGBA')
        im = im.crop(im.getchannel('A').getbbox())
        h = int(W * scale)
        im = im.resize((int(im.width * h / im.height), h), Image.LANCZOS)
        im = im.rotate(angle, expand=True, resample=Image.BICUBIC)
        return im, (int(center[0] - im.width / 2), int(center[1] - im.height / 2))

    layer = Image.new('RGBA', old.size, (0, 0, 0, 0))
    for name, angle, center in cards:
        im, pos = card(name, angle, center)
        layer.alpha_composite(im, pos)
    if clip:
        layer.putalpha(Image.fromarray(np.minimum(np.array(layer.getchannel('A')), alpha.astype(np.uint8))))
    out.alpha_composite(layer)
    # الخاين فوق الكروت (بحافة ناعمة)، والهلال من الأصل
    hood_img = Image.fromarray((hood * 255).astype(np.uint8), 'L').filter(ImageFilter.GaussianBlur(.6))
    out.paste(old, (0, 0), hood_img)
    cres = np.zeros(hood.shape, dtype=np.uint8)
    gold_sel = ((rgb[..., 0] > 150) & (rgb[..., 2] < 140) & (crescent_zone)) & (alpha > 128)
    cres[gold_sel] = 255
    out.paste(old, (0, 0), Image.fromarray(cres, 'L').filter(ImageFilter.GaussianBlur(.5)))
    return out


canvas = build([('loyal', 17, (84, 408)), ('traitor', -17, (428, 408))], .5, True)
canvas.save(os.path.join(out_dir, 'logo.png'))
print('saved logo.png', canvas.size)

# ───────── ملفات الأيقونة للأندرويد والموقع (بنفس تركيب الأيقونة القديمة)
# نسخة كاملة الحواف بكروت كلها داخل الإطار (للأمامية المتكيفة، لأن الأندرويد يقص الأطراف)
full_art = build([('loyal', 17, (112, 400)), ('traitor', -17, (400, 400))], .42, False).convert('RGB')

dens = {'mdpi': 1, 'hdpi': 1.5, 'xhdpi': 2, 'xxhdpi': 3, 'xxxhdpi': 4}
for name, k in dens.items():
    d = os.path.join(out_dir, 'android', f'mipmap-{name}')
    os.makedirs(d, exist_ok=True)
    s = int(48 * k)
    canvas.resize((s, s), Image.LANCZOS).save(os.path.join(d, 'ic_launcher.png'))
    # الدائرة
    sq = full_art.resize((s, s), Image.LANCZOS).convert('RGBA')
    m = Image.new('L', (s * 4, s * 4), 0)
    ImageDraw.Draw(m).ellipse((0, 0, s * 4 - 1, s * 4 - 1), fill=255)
    sq.putalpha(m.resize((s, s), Image.LANCZOS))
    sq.save(os.path.join(d, 'ic_launcher_round.png'))
    # الأمامية للأيقونة المتكيفة: الأيقونة مصغرة (٠٫٧١٥) والتدرج ممدود حواليها
    fs = int(108 * k)
    sc = .715
    art = int(round(fs * 366 / 432))
    fg = Image.new('RGB', (fs, fs))
    arr = np.zeros((fs, fs, 3), np.float32)
    for y in range(fs):
        ya = ((y / fs * 432) - 66) / sc  # الصف المقابل في الأيقونة الأصلية
        arr[y, :, :] = [np.polyval(coef[c], np.clip(ya, 0, W - 1)) for c in range(3)]
    fg = Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8), 'RGB')
    fg.paste(full_art.resize((art, art), Image.LANCZOS), (int(33 / 432 * fs), int(66 / 432 * fs)))
    fg.convert('RGBA').save(os.path.join(d, 'ic_launcher_foreground.png'))

canvas.resize((192, 192), Image.LANCZOS).save(os.path.join(out_dir, 'site_icon.png'))
print('android + site icons saved')
