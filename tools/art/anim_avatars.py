"""
الشخصيات اللي تتحرك: كل شخصية طبقات من نفس الرسمة (الجسم، الرمشة، الإكسسوار…) بلوحة أكبر من الدائرة
(viewBox ‎-20 -20 240 240) عشان الأجنحة وغيرها تقدر تطلع برا الإطار. التطبيق يحركها (widgets/anim_avatar.dart).
الطبقات الداخلية مقصوصة على الدائرة، وطبقات «pop_» بدون قص (تنرسم فوق الإطار).
ويطلع معها الشكل الثابت (assets/avatars/<id>.webp) بنفس الرسمة للقوائم.
تشغيل:  python3 tools/art/anim_avatars.py app/assets/avatars
"""
import io, os, subprocess, sys

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = sys.argv[1] if len(sys.argv) > 1 else 'app/assets/avatars'
SRC = os.path.join(HERE, 'build', 'anim')

src = open(os.path.join(HERE, 'avatars.py')).read()
exec(src[src.index('SKIN ='):src.index('CHARACTERS =')])  # face, thobe, ghutra, wrap…

DEFS = '''<defs>
  <pattern id="shemagh" width="10" height="10" patternUnits="userSpaceOnUse" patternTransform="rotate(45)">
    <rect width="10" height="10" fill="#FBF7F2"/><rect width="5" height="5" fill="#C8262E"/><rect x="5" y="5" width="5" height="5" fill="#C8262E"/>
  </pattern>
  <linearGradient id="chest" x1="0" y1="0" x2="1" y2="0">
    <stop offset="0" stop-color="#FAF1DF"/><stop offset=".62" stop-color="#E8D3AC"/><stop offset="1" stop-color="#8E6A47"/>
  </linearGradient>
  <linearGradient id="leather" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0" stop-color="#A06A36"/><stop offset="1" stop-color="#6E4520"/>
  </linearGradient>
  <clipPath id="c"><circle cx="100" cy="100" r="100"/></clipPath>
</defs>'''


def canvas(body, clip=True):
    inner = f'<g clip-path="url(#c)">{body}</g>' if clip else body
    return f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="-20 -20 240 240" width="600" height="600">{DEFS}{inner}</svg>'


# ───────────── الصقّار ─────────────
BROWN, BROWN_D, BROWN_L = '#6E4B2F', '#3B2716', '#A27A52'
CREAM, YELLOW, BEAK = '#F6EBD6', '#F2C14E', '#2F2B35'


def glove():
    """كم الثوب والقفاز الجلد (المنقلة) اللي يوقف عليه الصقر."""
    return ('<path d="M104 206 Q110 186 128 176 L146 168 L160 184 Q148 194 142 206 Z" fill="#E8DCC4"/>'
            '<path d="M136 173 Q137 159 151 156 L166 157 Q176 160 175 171 L171 180 Q160 185 148 183 L138 181 Z" fill="url(#leather)"/>'
            '<path d="M138 177 Q154 184 172 176" stroke="#4A2D12" stroke-width="3" fill="none"/>'
            '<path d="M140 166 Q156 161 172 164" stroke="#E6C38C" stroke-width="1.2" stroke-dasharray="2.5 2" fill="none"/>'
            '<path d="M150 157 Q151 162 149 166 M157.5 156.5 Q158.5 161 157 165.5 M165 157.5 Q166 162 164.5 166" '
            'stroke="#4A2D12" stroke-width="1.6" fill="none" stroke-linecap="round"/>')


def falcon_tail():
    """الذيل ينزل ورا القفاز."""
    return (f'<path d="M150 150 L145 182 Q155 188 165 182 L162 150 Z" fill="{BROWN}"/>'
            f'<path d="M146.6 170 H163.4 M146 177 H164" stroke="{BROWN_D}" stroke-width="2"/>')


def falcon_body():
    """الجسم والأرجل (الصقر يطالع يسار، صدره الفاتح لقدام)."""
    streaks = ''.join(f'<path d="M{x} {y} q1.5 2.5 0 4.8 q-1.5 -2.3 0 -4.8 Z" fill="{BROWN_D}" opacity=".7"/>'
                      for x, y in [(144, 124), (150, 121), (156, 124), (142, 132), (148, 130), (154, 132),
                                   (145, 140), (151, 139), (157, 141), (148, 148), (154, 148)])
    return (f'<path d="M140 156 Q131 138 136 121 Q141 106 154 104 Q168 104 172 119 Q177 138 168 156 Q155 163 140 156 Z" fill="url(#chest)"/>'
            + streaks +
            f'<path d="M147 151 L146 158 M159 151 L160 158" stroke="{YELLOW}" stroke-width="3.4" stroke-linecap="round"/>'
            f'<path d="M141.5 158.6 Q146 155.6 150.5 158.6 M155 158.6 Q159.5 155.6 164.5 158.6" stroke="{YELLOW}" stroke-width="2.6" fill="none" stroke-linecap="round"/>'
            '<path d="M141.5 158.6 l-1.5 1.7 M164.5 158.6 l1.5 1.7 M150.5 158.6 l1 1.7 M155 158.6 l-1 1.7" stroke="#1E1A16" stroke-width="1.3" stroke-linecap="round"/>')


def falcon_wing_folded():
    return (f'<path d="M156 107 Q177 113 179 136 Q180 155 167 173 Q161 151 158 132 Q156 117 156 107 Z" fill="{BROWN}"/>'
            f'<path d="M156 107 Q170 110 175 122 Q165 118 158 120 Z" fill="{BROWN_L}" opacity=".8"/>'
            f'<path d="M160 118 Q172 124 172 138 M161 130 Q170 136 169 150 M162 142 Q168 150 166 162" stroke="{BROWN_L}" stroke-width="1.6" fill="none"/>'
            f'<path d="M162.5 158 Q169 165 167 173 Q163 168 162.5 158 Z" fill="{BROWN_D}"/>')


def falcon_wing_open():
    """الجناح مفرود لفوق وورا (يمين) من الكتف (162، 112): يطلع برا الدائرة شوي."""
    tips = [(208, 64), (210, 77), (205, 90), (194, 99), (180, 106)]
    notch = [(201, 74), (198, 83), (191, 91), (181, 97), (170, 104)]
    d = 'M160 117 Q161 97 175 82 Q189 69 208 64'
    for (tx, ty), (nx, ny) in zip(tips[1:], notch):
        d += f' Q{nx + 3} {ny - 1} {nx} {ny} Q{(nx + tx) / 2 + 4} {(ny + ty) / 2 - 1} {tx} {ty}'
    d += ' Q174 108 170 106 Q169 112 167 117 Z'
    feathers = ''.join(f'<path d="M{nx} {ny} Q{(nx + 176) / 2} {(ny + 92) / 2 + 3} 176 92" stroke="{BROWN_D}" stroke-width="1.4" fill="none" opacity=".7"/>'
                       for nx, ny in notch)
    dark = ''.join(f'<path d="M{tx} {ty} Q{tx - 6} {ty + 2} {nx} {ny} Q{tx - 3} {ty - 4} {tx} {ty} Z" fill="{BROWN_D}"/>'
                   for (tx, ty), (nx, ny) in zip(tips, notch))
    coverts = f'<path d="M161 113 Q164 97 176 86 Q185 79 194 76 Q189 86 182 92 Q173 99 167 110 Z" fill="{BROWN_L}"/>'
    bars = ''.join(f'<path d="M{170 + i * 5} {98 - i * 3} q4 -2 7 1" stroke="{BROWN}" stroke-width="1.4" fill="none"/>' for i in range(4))
    return f'<path d="{d}" fill="{BROWN}"/>' + dark + feathers + coverts + bars


def falcon_head():
    """الراس يطالع يسار (المنقار لجهة الصقّار)، ويلف حول الرقبة (156، 112)."""
    return (f'<path d="M168 109 Q171 93 158 88 Q144 85 140 97 Q137 107 144 113 Q156 118 168 109 Z" fill="{BROWN_D}"/>'
            f'<path d="M144.5 106 Q145.5 99 151 98 Q157 98.5 158 105 Q156.5 112 150.5 112.5 Q146 111.5 144.5 106 Z" fill="{CREAM}"/>'
            f'<path d="M156.5 99.5 Q159.5 105.5 157.5 112" stroke="{BROWN_D}" stroke-width="3.2" fill="none" stroke-linecap="round"/>'
            f'<circle cx="149" cy="97.5" r="4.5" fill="{YELLOW}"/><circle cx="148.8" cy="97.6" r="3.4" fill="#141217"/>'
            '<circle cx="147.6" cy="96.3" r="1.2" fill="#fff"/>'
            f'<path d="M144.5 97.2 Q140.5 95.3 138 98.4 L141.6 101.4 Z" fill="{YELLOW}"/>'
            f'<path d="M142 96.8 Q133.5 97.3 133.5 102.8 Q134.5 107.3 138.5 105.3 Q137.6 102.4 142 101.7 Z" fill="{BEAK}"/>'
            '<path d="M136.5 99.2 Q135.5 100.8 136.4 102.6" stroke="#6B6577" stroke-width=".9" fill="none"/>')


def falcon_head_blink():
    return (f'<circle cx="149" cy="97.5" r="4.8" fill="{BROWN_D}"/>'
            f'<path d="M144.6 98.2 Q149 100.6 153.4 98.2" stroke="{YELLOW}" stroke-width="1.1" fill="none" stroke-linecap="round"/>')


def man_blink(skin='#D9A274'):
    def lid(x):
        return (f'<ellipse cx="{x}" cy="103" rx="5.4" ry="5.9" fill="{skin}"/>'
                f'<path d="M{x - 4.6} 103.8 Q{x} 106.8 {x + 4.6} 103.8" stroke="#1D1A24" stroke-width="1.8" fill="none" stroke-linecap="round"/>')
    return lid(88) + lid(112)


FALCONER = {
    'man': (thobe('#E8DCC4') + face('tan', beard='full') + ghutra('red'), True),
    'man_blink': (man_blink(), True),
    'tail': (falcon_tail(), True),
    'glove': (glove(), True),
    'bird': (falcon_body(), True),
    'wing': (falcon_wing_folded(), True),
    'head': (falcon_head(), True),
    'head_blink': (falcon_head_blink(), True),
    'pop_wing': (falcon_wing_open(), False),
}
STILL = {'falconer': ['man', 'tail', 'glove', 'bird', 'wing', 'head']}

ANIMS = {'falconer': FALCONER}


def render(svg, path, size=600):
    open(path + '.svg', 'w').write(svg)
    png = subprocess.run(['inkscape', path + '.svg', '--export-type=png', '--export-filename=-', '-w', str(size), '-h', str(size)],
                         check=True, capture_output=True).stdout
    return Image.open(io.BytesIO(png)).convert('RGBA')


if __name__ == '__main__':
    os.makedirs(SRC, exist_ok=True)
    for name, layers in ANIMS.items():
        out = os.path.join(OUT, 'anim', name)
        os.makedirs(out, exist_ok=True)
        for layer, (body, clip) in layers.items():
            im = render(canvas(body, clip), os.path.join(SRC, f'{name}_{layer}'))
            im.save(os.path.join(out, f'{layer}.webp'), quality=90, method=6)
        # الشكل الثابت (القوائم وغيرها): نفس الطبقات بدون الرمشة، مقصوص على الدائرة بحجم ٥١٢
        body = ''.join(layers[l][0] for l in STILL[name])
        svg = (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 200" width="512" height="512">'
               f'{DEFS}<g clip-path="url(#c)">{body}</g></svg>')
        render(svg, os.path.join(SRC, f'{name}_still'), 512).save(os.path.join(OUT, f'{name}.webp'), quality=92, method=6)
        print(name, len(layers), 'layers')
