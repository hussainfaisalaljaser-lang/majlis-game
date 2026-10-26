"""
صورة المعاينة لروابط الدعوة (لما ترسل الرابط في واتساب): ١٢٠٠×٦٣٠.
تشغيل:  python3 tools/art/og.py site/og.png
"""
import base64, io, os, subprocess, sys

from PIL import Image

OUT = sys.argv[1] if len(sys.argv) > 1 else 'site/og.png'
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..')
BUILD = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'build')


def img(path):
    # إنكسكيب ما يقرا webp، فنحوّل كل شي PNG.
    buf = io.BytesIO()
    Image.open(os.path.join(ROOT, path)).convert('RGBA').save(buf, 'PNG')
    return f'data:image/png;base64,{base64.b64encode(buf.getvalue()).decode()}'


def avatar(name, cx, cy, r, ring):
    return (f'<circle cx="{cx}" cy="{cy}" r="{r + 10}" fill="{ring}"/>'
            f'<clipPath id="c{name}"><circle cx="{cx}" cy="{cy}" r="{r}"/></clipPath>'
            f'<image xlink:href="{img(f"app/assets/avatars/{name}.webp")}" x="{cx - r}" y="{cy - r}" width="{2 * r}" height="{2 * r}" clip-path="url(#c{name})"/>')


svg = f'''<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="1200" height="630" viewBox="0 0 1200 630">
<defs>
  <radialGradient id="bg" cx="70%" cy="40%" r="80%"><stop offset="0" stop-color="#5B3AB0"/><stop offset=".55" stop-color="#2A1B5E"/><stop offset="1" stop-color="#120E24"/></radialGradient>
  <linearGradient id="gold" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FFE7A3"/><stop offset=".55" stop-color="#F2C14E"/><stop offset="1" stop-color="#B87A12"/></linearGradient>
  <filter id="glow"><feGaussianBlur stdDeviation="18"/></filter>
</defs>
<rect width="1200" height="630" fill="url(#bg)"/>
<circle cx="340" cy="300" r="230" fill="#E0314B" opacity=".35" filter="url(#glow)"/>
{avatar("pearl", 180, 375, 88, "#8FC1FF")}
{avatar("desert", 495, 375, 88, "#8FC1FF")}
{avatar("masked", 340, 290, 140, "#E0314B")}
<image xlink:href="{img("app/assets/images/seal_leader.png")}" x="395" y="400" width="120" height="125"/>
<text x="1140" y="230" font-family="Marhey" font-weight="bold" font-size="104" fill="url(#gold)" stroke="#3A2400" stroke-width="4" paint-order="stroke" text-anchor="start" direction="rtl">مجلس الخونة</text>
<text x="1140" y="325" font-family="Tajawal" font-weight="bold" font-size="48" fill="#F5F1FF" text-anchor="start" direction="rtl">مين الخاين فينا؟</text>
<text x="1140" y="395" font-family="Tajawal" font-weight="bold" font-size="31" fill="#D9CFFF" text-anchor="start" direction="rtl">أصحابك يبونك في المجلس… تعال العب</text>
<rect x="830" y="450" width="310" height="80" rx="40" fill="url(#gold)" stroke="#8E5A07" stroke-width="4"/>
<text x="985" y="503" font-family="Marhey" font-weight="bold" font-size="40" fill="#3A2400" text-anchor="middle" direction="rtl">ادخل الروم</text>
</svg>'''
os.makedirs(BUILD, exist_ok=True)
src = os.path.join(BUILD, 'og.svg')
open(src, 'w').write(svg)
subprocess.run(['inkscape', src, '-o', OUT, '-w', '1200', '-h', '630'], check=True, capture_output=True)
print('og', OUT)
