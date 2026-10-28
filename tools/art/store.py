"""
صور المتجر: كل لقطة بإطار وعنوان قصير فوقها (١٩٢٠×١٠٨٠)، وصورة الواجهة (Feature graphic ١٠٢٤×٥٠٠)،
وأيقونة المتجر (٥١٢×٥١٢) من أيقونة أندرويد المتكيفة.
تشغيل:  python3 tools/art/store.py <مجلد اللقطات الخام> docs/store
"""
import base64, io, os, subprocess, sys

from PIL import Image

RAW = sys.argv[1]
OUT = sys.argv[2] if len(sys.argv) > 2 else 'docs/store'
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..')
BUILD = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'build', 'store')

SHOTS = [
    ('01-vote', 'لعبة خيانة وذكاء مع ربعك'),
    ('02-role', 'دورك سري… لا تثق بأحد'),
    ('03-talk', 'اتهم ودافع بالملصقات'),
    ('04-cards', 'مرّر القرار… أو اكذب!'),
    ('05-lies', 'آخر اللعبة ينكشف مين كذب'),
    ('06-clan', 'سوّ ديوانك وسولف مع ربعك'),
    ('07-home', 'روم خاص لربعك أو العب مع الكل'),
    ('08-shop', 'شخصيات وإطارات متحركة'),
]  # قوقل تقبل ٨ لقطات بالكثير، والملفات تنحفظ بترتيب الرفع (screenshot-1-vote …).


def data_uri(path, max_w=None):
    im = Image.open(path).convert('RGBA')
    if max_w and im.width > max_w:
        im = im.resize((max_w, round(im.height * max_w / im.width)), Image.LANCZOS)
    buf = io.BytesIO()
    im.save(buf, 'PNG', optimize=True)
    return f'data:image/png;base64,{base64.b64encode(buf.getvalue()).decode()}', im.size


def render(svg, out, w, h):
    os.makedirs(BUILD, exist_ok=True)
    src = os.path.join(BUILD, os.path.basename(out) + '.svg')
    open(src, 'w').write(svg)
    subprocess.run(['inkscape', src, '-o', out, '-w', str(w), '-h', str(h)], check=True, capture_output=True)
    # المتجر يبي لقطات وصورة واجهة بدون شفافية (PNG ٢٤ بت).
    Image.open(out).convert('RGB').save(out, optimize=True)


BG = '''<defs>
  <radialGradient id="bg" cx="50%" cy="20%" r="90%"><stop offset="0" stop-color="#5B3AB0"/><stop offset=".6" stop-color="#2A1B5E"/><stop offset="1" stop-color="#120E24"/></radialGradient>
  <linearGradient id="gold" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FFE7A3"/><stop offset=".55" stop-color="#F2C14E"/><stop offset="1" stop-color="#B87A12"/></linearGradient>
  <clipPath id="clip"><rect x="144" y="150" width="1632" height="918" rx="34"/></clipPath>
</defs>'''


def framed(name, caption, order):
    uri, _ = data_uri(os.path.join(RAW, name + '.png'))
    svg = f'''<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="1920" height="1080" viewBox="0 0 1920 1080">
{BG}
<rect width="1920" height="1080" fill="url(#bg)"/>
<text x="960" y="108" font-family="Marhey" font-weight="bold" font-size="76" fill="url(#gold)" stroke="#3A2400" stroke-width="3" paint-order="stroke" text-anchor="middle" direction="rtl">{caption}</text>
<rect x="138" y="144" width="1644" height="930" rx="40" fill="#F2C14E" opacity=".9"/>
<image xlink:href="{uri}" x="144" y="150" width="1632" height="918" preserveAspectRatio="xMidYMid slice" clip-path="url(#clip)"/>
</svg>'''
    render(svg, os.path.join(OUT, f"screenshot-{order}-{name.split('-', 1)[1]}.png"), 1920, 1080)


def feature():
    """صورة الواجهة ١٠٢٤×٥٠٠: نفس صورة روابط الدعوة بس بقياس المتجر."""
    def av(n):
        return data_uri(os.path.join(ROOT, f'app/assets/avatars/{n}.webp'), 400)[0]
    seal = data_uri(os.path.join(ROOT, 'app/assets/images/seal_leader.png'), 300)[0]
    svg = f'''<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="1024" height="500" viewBox="0 0 1024 500">
<defs>
  <radialGradient id="bg" cx="30%" cy="40%" r="90%"><stop offset="0" stop-color="#5B3AB0"/><stop offset=".55" stop-color="#2A1B5E"/><stop offset="1" stop-color="#120E24"/></radialGradient>
  <linearGradient id="gold" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FFE7A3"/><stop offset=".55" stop-color="#F2C14E"/><stop offset="1" stop-color="#B87A12"/></linearGradient>
  <filter id="glow"><feGaussianBlur stdDeviation="16"/></filter>
  <clipPath id="a"><circle cx="140" cy="300" r="78"/></clipPath>
  <clipPath id="b"><circle cx="420" cy="300" r="78"/></clipPath>
  <clipPath id="c"><circle cx="280" cy="240" r="116"/></clipPath>
</defs>
<rect width="1024" height="500" fill="url(#bg)"/>
<circle cx="280" cy="250" r="190" fill="#E0314B" opacity=".35" filter="url(#glow)"/>
<circle cx="140" cy="300" r="86" fill="#8FC1FF"/><image xlink:href="{av('pearl')}" x="62" y="222" width="156" height="156" clip-path="url(#a)"/>
<circle cx="420" cy="300" r="86" fill="#8FC1FF"/><image xlink:href="{av('desert')}" x="342" y="222" width="156" height="156" clip-path="url(#b)"/>
<circle cx="280" cy="240" r="125" fill="#E0314B"/><image xlink:href="{av('masked')}" x="164" y="124" width="232" height="232" clip-path="url(#c)"/>
<image xlink:href="{seal}" x="330" y="318" width="104" height="104"/>
<text x="975" y="205" font-family="Marhey" font-weight="bold" font-size="92" fill="url(#gold)" stroke="#3A2400" stroke-width="4" paint-order="stroke" text-anchor="start" direction="rtl">مجلس الخونة</text>
<text x="975" y="290" font-family="Tajawal" font-weight="bold" font-size="40" fill="#F5F1FF" text-anchor="start" direction="rtl">مين الخاين فينا؟</text>
<text x="975" y="350" font-family="Tajawal" font-weight="bold" font-size="28" fill="#D9CFFF" text-anchor="start" direction="rtl">لعبة خيانة وذكاء من ٥ إلى ١٠ لاعبين</text>
</svg>'''
    render(svg, os.path.join(OUT, 'feature-graphic.png'), 1024, 500)


def icon():
    """أيقونة المتجر: خلفية الأيقونة المتكيفة + الواجهة الأمامية بكامل المساحة (قوقل تدوّر الزوايا بنفسها)."""
    res = os.path.join(ROOT, 'app', 'android', 'app', 'src', 'main', 'res')
    fg = Image.open(os.path.join(res, 'mipmap-xxxhdpi', 'ic_launcher_foreground.png')).convert('RGBA')
    out = Image.new('RGBA', (512, 512), (0x12, 0x15, 0x2A, 255))
    out.alpha_composite(fg.resize((512, 512), Image.LANCZOS))
    out.save(os.path.join(OUT, 'icon-512.png'))


if __name__ == '__main__':
    os.makedirs(OUT, exist_ok=True)
    for order, (name, cap) in enumerate(SHOTS, 1):
        if os.path.exists(os.path.join(RAW, name + '.png')):
            framed(name, cap, order)
            print('framed', name)
    feature()
    print('feature graphic')
    icon()
    print('icon')
