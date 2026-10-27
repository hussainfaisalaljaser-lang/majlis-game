"""
ملصقات مجلس الخونة (ميمز مرسومة للعبة): شخصيات خليجية بتعابير مبالغ فيها وكلام عربي.
كل ملصق SVG ← PNG ← حافة بيضاء وظل ← WebP في app/assets/stickers.
تشغيل:  python3 tools/art/stickers.py app/assets/stickers [ids,...]
"""
import io, os, subprocess, sys
from concurrent.futures import ThreadPoolExecutor

from PIL import Image, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', 'catalog'))
import catalog  # noqa: E402

OUT = sys.argv[1] if len(sys.argv) > 1 else 'app/assets/stickers'
ONLY = set(sys.argv[2].split(',')) if len(sys.argv) > 2 else None
SRC = os.path.join(HERE, 'build', 'stickers')

SKIN = {'light': ('#F7D2AC', '#E0B088'), 'tan': ('#E2AE7E', '#C48A5E'), 'brown': ('#B87B50', '#96613D'), 'deep': ('#8E5A38', '#71452A')}
INK = '#2A1A14'

# ───────────── الشخصيات ─────────────
CHARS = {
    'A': dict(skin='tan', head='ghutra', beard=None),              # شاب بغترة بيضاء
    'B': dict(skin='brown', head='shemagh', beard='goatee'),       # بشماغ أحمر وسكسوكة
    'C': dict(skin='light', head='ghutra', beard='full', grey=True),  # شايب
    'D': dict(skin='light', head='hijab', hijab='#2A2433'),         # بحجاب أسود
    'E': dict(skin='tan', head='hijab', hijab='#B5446E'),           # بحجاب وردي
    'F': dict(skin='brown', head='hijab', hijab='#2C7A7B', glasses=True),  # بحجاب تركوازي ونظارة
    'G': dict(skin='deep', head='shemagh', beard='stubble'),        # بشماغ ولحية خفيفة
    'H': dict(skin='tan', head='shemagh', masked=True),             # ملثّم (الخونة)
    'I': dict(skin='light', head='ghutra', beard='mustache'),       # بشنب
}


def head_back(ch):
    if ch['head'] == 'hijab':
        c = ch['hijab']
        return (f'<path d="M50 104 Q46 40 100 34 Q154 40 150 104 Q154 156 132 172 Q100 188 68 172 Q46 156 50 104 Z" fill="{c}" stroke="{INK}" stroke-width="5"/>'
                f'<path d="M58 70 Q100 42 142 70" fill="none" stroke="#fff" stroke-opacity=".18" stroke-width="6"/>')
    fill = 'url(#shemagh)' if ch['head'] == 'shemagh' else '#FBFAF7'
    return (f'<path d="M48 104 Q42 36 100 30 Q158 36 152 104 L164 178 Q138 154 132 116 Q128 76 100 74 Q72 76 68 116 Q62 154 36 178 Z" '
            f'fill="{fill}" stroke="{INK}" stroke-width="5" stroke-linejoin="round"/>')


def head_front(ch):
    if ch['head'] == 'hijab':
        c = ch['hijab']
        outer = 'M50 104 Q46 40 100 34 Q154 40 150 104 Q154 156 132 172 Q100 188 68 172 Q46 156 50 104 Z'
        opening = 'M100 58 Q136 58 138 100 Q138 146 100 152 Q62 146 62 100 Q64 58 100 58 Z'
        return f'<path d="{outer} {opening}" fill="{c}" fill-rule="evenodd" stroke="{INK}" stroke-width="5"/>'
    # العقال
    return ('<path d="M54 62 Q100 36 146 62 L146 74 Q100 48 54 74 Z" fill="#1A1622" stroke="#000" stroke-width="2"/>'
            '<path d="M54 80 Q100 54 146 80 L146 90 Q100 66 54 90 Z" fill="#1A1622" stroke="#000" stroke-width="2"/>')


def face(ch):
    s, sh = SKIN[ch['skin']]
    return (f'<ellipse cx="100" cy="104" rx="40" ry="44" fill="{s}" stroke="{INK}" stroke-width="5"/>'
            f'<path d="M66 118 Q100 152 134 118 Q130 146 100 148 Q70 146 66 118 Z" fill="{sh}" opacity=".35"/>')


def beard(ch):
    b = ch.get('beard')
    col = '#C9C2B8' if ch.get('grey') else '#231A16'
    if b == 'full':
        return (f'<path d="M62 106 Q60 158 100 162 Q140 158 138 106 Q134 136 120 138 Q100 146 80 138 Q66 136 62 106 Z" fill="{col}" stroke="{INK}" stroke-width="4"/>')
    if b == 'goatee':
        return f'<path d="M86 134 Q100 128 114 134 Q112 156 100 158 Q88 156 86 134 Z" fill="{col}" stroke="{INK}" stroke-width="3.5"/>'
    if b == 'stubble':
        return f'<path d="M64 112 Q68 156 100 158 Q132 156 136 112 Q128 140 100 144 Q72 140 64 112 Z" fill="{col}" opacity=".3"/>'
    if b == 'mustache':
        return f'<path d="M80 126 Q100 116 120 126 Q110 122 100 126 Q90 122 80 126 Z" fill="{col}" stroke="{INK}" stroke-width="3"/>'
    return ''


def mustache(ch):
    """الشنب فوق الفم (للحية الكاملة والسكسوكة)."""
    b = ch.get('beard')
    col = '#C9C2B8' if ch.get('grey') else '#231A16'
    if b in ('full', 'goatee'):
        return f'<path d="M82 126 Q100 118 118 126 Q108 124 100 128 Q92 124 82 126 Z" fill="{col}" stroke="{INK}" stroke-width="2.5"/>'
    return ''


# ───────────── العيون ─────────────
L, R = (82, 98), (118, 98)


def eye_white(c, rx=9, ry=10):
    return f'<ellipse cx="{c[0]}" cy="{c[1]}" rx="{rx}" ry="{ry}" fill="#fff" stroke="{INK}" stroke-width="3.5"/>'


def pupil(c, dx=0, dy=0, r=5):
    x, y = c[0] + dx, c[1] + dy
    return f'<circle cx="{x}" cy="{y}" r="{r}" fill="{INK}"/><circle cx="{x + r * .35}" cy="{y - r * .4}" r="{r * .38}" fill="#fff"/>'


def eyes(kind, skin='#E2AE7E'):
    out = []
    if kind == 'normal':
        for c in (L, R): out += [eye_white(c), pupil(c)]
    elif kind == 'look_up':
        for c in (L, R): out += [eye_white(c), pupil(c, 2, -4)]
    elif kind == 'side':
        for c in (L, R):
            out += [eye_white(c, 10, 7), pupil(c, 5, 1, 4.5), f'<path d="M{c[0] - 11} {c[1] - 3} H{c[0] + 11}" stroke="{INK}" stroke-width="4" stroke-linecap="round"/>']
    elif kind == 'wide':
        for c in (L, R): out += [eye_white(c, 12, 13), pupil(c, 0, 0, 3.4)]
    elif kind == 'happy':
        for c in (L, R): out.append(f'<path d="M{c[0] - 9} {c[1] + 3} Q{c[0]} {c[1] - 9} {c[0] + 9} {c[1] + 3}" fill="none" stroke="{INK}" stroke-width="5" stroke-linecap="round"/>')
    elif kind == 'laugh':
        out.append(f'<path d="M{L[0] - 9} {L[1] - 6} L{L[0] + 7} {L[1]} L{L[0] - 9} {L[1] + 6}" fill="none" stroke="{INK}" stroke-width="5" stroke-linecap="round" stroke-linejoin="round"/>')
        out.append(f'<path d="M{R[0] + 9} {R[1] - 6} L{R[0] - 7} {R[1]} L{R[0] + 9} {R[1] + 6}" fill="none" stroke="{INK}" stroke-width="5" stroke-linecap="round" stroke-linejoin="round"/>')
    elif kind == 'closed':
        for c in (L, R): out.append(f'<path d="M{c[0] - 9} {c[1] + 1} Q{c[0]} {c[1] + 6} {c[0] + 9} {c[1] + 1}" fill="none" stroke="{INK}" stroke-width="4.5" stroke-linecap="round"/>')
    elif kind == 'wink':
        out += [eye_white(L), pupil(L), f'<path d="M{R[0] - 9} {R[1] + 2} Q{R[0]} {R[1] - 8} {R[0] + 9} {R[1] + 2}" fill="none" stroke="{INK}" stroke-width="5" stroke-linecap="round"/>']
    elif kind == 'angry':
        for c, s in ((L, 1), (R, -1)):
            out += [eye_white(c, 9, 9), pupil(c, 0, 2, 4.5),
                    f'<path d="M{c[0] - 12 * s} {c[1] - 12} L{c[0] + 12 * s} {c[1] - 3} L{c[0] + 12 * s} {c[1] - 14} Z" fill="{skin}"/>']
    elif kind == 'sad':
        for c, s in ((L, 1), (R, -1)):
            out += [eye_white(c, 9, 10), pupil(c, 0, 3, 4.6),
                    f'<path d="M{c[0] - 12 * s} {c[1] - 4} L{c[0] + 12 * s} {c[1] - 12} L{c[0] - 12 * s} {c[1] - 14} Z" fill="{skin}"/>']
    elif kind == 'teary':
        for c in (L, R):
            out += [eye_white(c, 11, 12), f'<circle cx="{c[0]}" cy="{c[1] + 1}" r="7.5" fill="{INK}"/>',
                    f'<circle cx="{c[0] + 3}" cy="{c[1] - 2}" r="3.2" fill="#fff"/><circle cx="{c[0] - 3}" cy="{c[1] + 4}" r="1.8" fill="#fff"/>',
                    f'<path d="M{c[0] - 10} {c[1] + 9} Q{c[0]} {c[1] + 14} {c[0] + 10} {c[1] + 9}" fill="none" stroke="#7FD3FF" stroke-width="3"/>']
    elif kind == 'dizzy':
        for c in (L, R):
            out.append(f'<path d="M{c[0]} {c[1]} m-1 0 a2 2 0 1 1 3 1 a5 5 0 1 1 -7 -3 a8 8 0 1 1 11 6" fill="none" stroke="{INK}" stroke-width="3.2" stroke-linecap="round"/>')
    elif kind == 'star':
        for c in (L, R):
            x, y = c
            out.append(f'<path d="M{x} {y - 11} L{x + 3.5} {y - 3.5} L{x + 11} {y - 2} L{x + 5} {y + 3.5} L{x + 7} {y + 11} L{x} {y + 6.5} L{x - 7} {y + 11} L{x - 5} {y + 3.5} L{x - 11} {y - 2} L{x - 3.5} {y - 3.5} Z" fill="#FFD43B" stroke="{INK}" stroke-width="3"/>')
    elif kind == 'sun':
        out.append(f'<path d="M66 92 H96 Q97 110 82 110 Q66 110 66 92 Z M104 92 H134 Q134 110 118 110 Q103 110 104 92 Z" fill="#14121C" stroke="{INK}" stroke-width="3"/>'
                   f'<path d="M96 95 H104" stroke="{INK}" stroke-width="4"/><path d="M72 96 L80 96" stroke="#fff" stroke-width="3" opacity=".6" stroke-linecap="round"/>')
    elif kind == 'evil':
        for c, s in ((L, 1), (R, -1)):
            out.append(f'<path d="M{c[0] - 11 * s} {c[1] - 6} Q{c[0]} {c[1] + 8} {c[0] + 11 * s} {c[1] + 2} Z" fill="#fff" stroke="{INK}" stroke-width="3.5" stroke-linejoin="round"/>')
            out.append(f'<circle cx="{c[0] + 2 * s}" cy="{c[1] + 1}" r="3.6" fill="#E03131"/>')
    elif kind == 'tiny':
        for c in (L, R): out.append(f'<circle cx="{c[0]}" cy="{c[1]}" r="3.6" fill="{INK}"/>')
    elif kind == 'money':
        for c in (L, R):
            out.append(f'<circle cx="{c[0]}" cy="{c[1]}" r="10" fill="#FFD43B" stroke="#8A5A08" stroke-width="3"/>'
                       f'<path d="M{c[0]} {c[1] - 6} L{c[0] + 2} {c[1] - 1} L{c[0] + 6} {c[1] - 1} L{c[0] + 3} {c[1] + 2} L{c[0] + 4} {c[1] + 7} L{c[0]} {c[1] + 4} L{c[0] - 4} {c[1] + 7} L{c[0] - 3} {c[1] + 2} L{c[0] - 6} {c[1] - 1} L{c[0] - 2} {c[1] - 1} Z" fill="#B9780F"/>')
    elif kind == 'glow':
        for c in (L, R):
            out.append(f'<ellipse cx="{c[0]}" cy="{c[1]}" rx="11" ry="9" fill="#C084FC" opacity=".55"/><ellipse cx="{c[0]}" cy="{c[1]}" rx="8" ry="6.5" fill="#F3E8FF" stroke="{INK}" stroke-width="3"/>')
    elif kind == 'sleepy':
        for c in (L, R):
            out.append(f'<path d="M{c[0] - 10} {c[1]} H{c[0] + 10}" stroke="{INK}" stroke-width="4.5" stroke-linecap="round"/>'
                       f'<path d="M{c[0] - 8} {c[1]} Q{c[0]} {c[1] + 6} {c[0] + 8} {c[1]}" fill="{INK}" opacity=".7"/>')
    return ''.join(out)


def brows(kind, ch):
    col = '#8F877F' if ch.get('grey') else INK
    w = 5
    if kind == 'none' or ch['head'] == 'hijab' and kind == 'normal':
        pass
    d = {
        'normal': ('M70 82 Q80 76 92 80', 'M108 80 Q120 76 130 82'),
        'raised': ('M70 82 Q80 77 92 80', 'M108 74 Q120 64 132 72'),
        'angry': ('M70 76 L94 86', 'M106 86 L130 76'),
        'sad': ('M70 84 Q80 78 92 74', 'M108 74 Q120 78 130 84'),
        'up': ('M68 76 Q80 66 92 72', 'M108 72 Q120 66 132 76'),
        'flat': ('M70 80 H92', 'M108 80 H130'),
    }.get(kind)
    if not d:
        return ''
    return ''.join(f'<path d="{p}" fill="none" stroke="{col}" stroke-width="{w}" stroke-linecap="round"/>' for p in d)


def mouth(kind):
    m = {
        'smile': 'M84 128 Q100 142 116 128',
        'frown': 'M86 140 Q100 128 114 140',
        'flat': 'M88 134 H112',
        'smirk': 'M88 134 Q104 136 116 124',
        'wavy': 'M84 134 Q90 128 96 134 Q102 140 108 134 Q114 128 118 134',
    }
    if kind in m:
        return f'<path d="{m[kind]}" fill="none" stroke="{INK}" stroke-width="5" stroke-linecap="round" stroke-linejoin="round"/>'
    if kind == 'grin':
        return (f'<path d="M80 126 Q100 152 120 126 Z" fill="#fff" stroke="{INK}" stroke-width="4.5" stroke-linejoin="round"/>'
                f'<path d="M82 128 H118" stroke="{INK}" stroke-width="2.5"/>')
    if kind == 'laugh':
        return (f'<path d="M76 124 Q100 166 124 124 Z" fill="#7A2B22" stroke="{INK}" stroke-width="5" stroke-linejoin="round"/>'
                '<path d="M80 126 H120 L118 132 H82 Z" fill="#fff"/><path d="M88 150 Q100 142 112 150 Q106 158 100 158 Q94 158 88 150 Z" fill="#E8707A"/>')
    if kind == 'o':
        return f'<ellipse cx="100" cy="136" rx="7" ry="9" fill="#7A2B22" stroke="{INK}" stroke-width="4"/>'
    if kind == 'O':
        return f'<ellipse cx="100" cy="138" rx="13" ry="17" fill="#7A2B22" stroke="{INK}" stroke-width="5"/><ellipse cx="100" cy="146" rx="8" ry="5" fill="#E8707A"/>'
    if kind == 'clench':
        return (f'<rect x="80" y="126" width="40" height="16" rx="6" fill="#fff" stroke="{INK}" stroke-width="4.5"/>'
                f'<path d="M80 134 H120 M90 126 V142 M100 126 V142 M110 126 V142" stroke="{INK}" stroke-width="2.5"/>')
    if kind == 'tongue':
        return (f'<path d="M84 128 Q100 140 116 128" fill="none" stroke="{INK}" stroke-width="5" stroke-linecap="round"/>'
                f'<path d="M94 133 Q94 148 102 148 Q110 148 108 132" fill="#E8707A" stroke="{INK}" stroke-width="3.5"/>')
    if kind == 'evil':
        return (f'<path d="M74 122 Q100 160 126 122 Q100 134 74 122 Z" fill="#7A2B22" stroke="{INK}" stroke-width="5" stroke-linejoin="round"/>'
                '<path d="M80 125 L86 133 L92 127 L98 135 L104 127 L110 135 L116 127 L121 125 Q100 133 80 125 Z" fill="#fff"/>')
    if kind == 'yawn':
        return f'<ellipse cx="100" cy="136" rx="10" ry="13" fill="#7A2B22" stroke="{INK}" stroke-width="4.5"/>'
    if kind == 'pout':
        return f'<path d="M92 134 Q100 128 108 134 Q100 140 92 134 Z" fill="#C2554F" stroke="{INK}" stroke-width="3.5"/>'
    return ''


# ───────────── الإضافات والأغراض ─────────────
def hand(x, y, rot=0, s=1, kind='palm', skin='tan', flip=False):
    """كف بسيطة (الأصابع لفوق والرسغ تحت قبل اللف). kind: palm (مفتوحة)، fist، point، thumb. flip: اليد الثانية."""
    c, sh = SKIN[skin]
    if kind == 'palm':
        body = (f'<path d="M-14 22 Q-22 4 -18 -10 L-16 -26 Q-15 -32 -10 -31 Q-6 -30 -6 -24 L-5 -12 L-4 -34 Q-3 -40 2 -40 Q7 -40 7 -34 L7 -12 L9 -32 Q10 -37 15 -36 Q19 -35 19 -30 L18 -8 L22 -22 Q24 -27 28 -25 Q31 -23 30 -18 L24 10 Q20 26 6 28 Q-6 30 -14 22 Z" '
                f'fill="{c}" stroke="{INK}" stroke-width="4" stroke-linejoin="round"/>')
    elif kind == 'fist':
        body = (f'<path d="M-18 -16 Q-18 -26 -8 -26 H16 Q26 -26 26 -14 V8 Q26 24 8 26 H-6 Q-20 24 -20 10 Z" fill="{c}" stroke="{INK}" stroke-width="4" stroke-linejoin="round"/>'
                f'<path d="M-8 -26 V-10 M2 -26 V-10 M12 -26 V-10" stroke="{INK}" stroke-width="3"/>'
                f'<path d="M-20 -2 Q-8 -6 0 2" fill="none" stroke="{INK}" stroke-width="3.5"/>')
    elif kind == 'point':
        body = (f'<path d="M-16 -8 Q-18 18 0 22 H14 Q24 20 24 10 V-6 Q24 -14 16 -14 H8 L8 -46 Q8 -52 2 -52 Q-4 -52 -4 -46 V-12 Q-14 -14 -16 -8 Z" '
                f'fill="{c}" stroke="{INK}" stroke-width="4" stroke-linejoin="round"/>'
                f'<path d="M8 -4 H22 M8 6 H22" stroke="{INK}" stroke-width="2.5"/>')
    else:  # thumb
        body = (f'<path d="M-18 -10 H14 Q24 -10 24 0 V14 Q24 24 12 24 H-12 Q-18 24 -18 18 Z" fill="{c}" stroke="{INK}" stroke-width="4" stroke-linejoin="round"/>'
                f'<path d="M-14 -10 Q-16 -30 -6 -40 Q2 -44 2 -34 Q0 -22 6 -10" fill="{c}" stroke="{INK}" stroke-width="4" stroke-linejoin="round"/>'
                f'<path d="M-18 2 H22 M-18 12 H22" stroke="{INK}" stroke-width="2.5"/>')
    return f'<g transform="translate({x} {y}) rotate({rot}) scale({-s if flip else s} {s})">{body}</g>'


def arm(x1, y1, x2, y2, ch):
    """ذراع بكمّ الثوب أو العباية: من تحت (الصدر) لين الرسغ (x2، y2) عشان اليد تطلع منها طبيعية."""
    sleeve = '#1E1B26' if ch['head'] == 'hijab' else ('#2B2B35' if ch.get('masked') else '#F4F1EA')
    return (f'<path d="M{x1} {y1} L{x2} {y2}" stroke="{INK}" stroke-width="27" stroke-linecap="round"/>'
            f'<path d="M{x1} {y1} L{x2} {y2}" stroke="{sleeve}" stroke-width="19" stroke-linecap="round"/>')


def sweat(x=138, y=78):
    return f'<path d="M{x} {y} Q{x + 10} {y + 14} {x} {y + 20} Q{x - 10} {y + 14} {x} {y} Z" fill="#8FD3FF" stroke="{INK}" stroke-width="3"/><circle cx="{x - 2}" cy="{y + 12}" r="2.5" fill="#fff"/>'


def tears_stream():
    return ''.join(f'<path d="M{x} 106 Q{x + d * 6} 130 {x + d * 14} 150" fill="none" stroke="#7FD3FF" stroke-width="7" stroke-linecap="round"/>' for x, d in ((76, -1), (124, 1)))


def tear():
    return f'<path d="M80 108 Q86 120 80 126 Q74 120 80 108 Z" fill="#7FD3FF" stroke="{INK}" stroke-width="2.5"/>'


def vein(x=156, y=46):
    return (f'<circle cx="{x}" cy="{y}" r="15" fill="#fff" stroke="{INK}" stroke-width="3"/>'
            f'<g transform="translate({x} {y})" stroke="#E03131" stroke-width="5" stroke-linecap="round" fill="none">'
            '<path d="M-8 -2 Q-2 -2 -2 -8 M8 -2 Q2 -2 2 -8 M-8 2 Q-2 2 -2 8 M8 2 Q2 2 2 8"/></g>')


def steam():
    puff = '#F1F3F5'
    return ''.join(f'<path d="M{x} {y} q-8 -4 -4 -12 q2 -10 12 -6 q6 -8 14 -2 q10 0 8 10 q8 6 0 12 Z" fill="{puff}" stroke="{INK}" stroke-width="3.5"/>'
                   for x, y in ((34, 52), (150, 46)))


def blush():
    return '<ellipse cx="72" cy="118" rx="9" ry="5" fill="#FF6B6B" opacity=".45"/><ellipse cx="128" cy="118" rx="9" ry="5" fill="#FF6B6B" opacity=".45"/>'


def marks(kind):
    if kind == 'q':
        return (f'<text x="160" y="58" font-family="Marhey" font-weight="bold" font-size="44" fill="#FFD43B" stroke="{INK}" stroke-width="6" paint-order="stroke">؟</text>'
                f'<text x="28" y="48" font-family="Marhey" font-weight="bold" font-size="30" fill="#FFD43B" stroke="{INK}" stroke-width="5" paint-order="stroke" transform="rotate(-15 36 40)">؟</text>')
    return (f'<text x="160" y="58" font-family="Marhey" font-weight="bold" font-size="46" fill="#FF6B6B" stroke="{INK}" stroke-width="6" paint-order="stroke">!</text>'
            f'<text x="34" y="52" font-family="Marhey" font-weight="bold" font-size="34" fill="#FF6B6B" stroke="{INK}" stroke-width="5" paint-order="stroke">!</text>')


def sparkles(color='#FFD43B'):
    def st(x, y, r):
        return f'<path d="M{x} {y - r} Q{x + r * .2} {y - r * .2} {x + r} {y} Q{x + r * .2} {y + r * .2} {x} {y + r} Q{x - r * .2} {y + r * .2} {x - r} {y} Q{x - r * .2} {y - r * .2} {x} {y - r} Z" fill="{color}" stroke="{INK}" stroke-width="2.5"/>'
    return st(34, 54, 13) + st(166, 70, 10) + st(158, 30, 7)


def motion():
    return ''.join(f'<path d="M{x} {y} q-6 6 0 12" fill="none" stroke="{INK}" stroke-width="4" stroke-linecap="round"/>' for x, y in ((40, 92), (34, 108), (162, 92), (168, 108)))


def halo():
    return '<ellipse cx="100" cy="24" rx="34" ry="9" fill="none" stroke="#6E4606" stroke-width="10"/><ellipse cx="100" cy="24" rx="34" ry="9" fill="none" stroke="#FFE066" stroke-width="6"/>'


def flames_back():
    return ''.join(f'<path d="M{x} 150 Q{x - 18} 110 {x - 4} 80 Q{x + 2} 100 {x + 10} 96 Q{x + 6} 70 {x + 22} 46 Q{x + 30} 84 {x + 40} 96 Q{x + 48} 120 {x + 34} 150 Z" fill="#FF922B" stroke="{INK}" stroke-width="4" stroke-linejoin="round"/>'
                   f'<path d="M{x + 8} 150 Q{x} 124 {x + 14} 108 Q{x + 22} 124 {x + 26} 150 Z" fill="#FFE066"/>' for x in (16, 136))


def zzz():
    return (f'<text x="150" y="52" font-family="Tajawal" font-weight="bold" font-size="30" fill="#A5D8FF" stroke="{INK}" stroke-width="5" paint-order="stroke">z</text>'
            f'<text x="166" y="32" font-family="Tajawal" font-weight="bold" font-size="22" fill="#A5D8FF" stroke="{INK}" stroke-width="4" paint-order="stroke">z</text>')


def dizzy_stars():
    return ''.join(f'<path d="M{x} {y - 8} L{x + 2.5} {y - 2.5} L{x + 8} {y - 1.5} L{x + 3.5} {y + 2.5} L{x + 5} {y + 8} L{x} {y + 5} L{x - 5} {y + 8} L{x - 3.5} {y + 2.5} L{x - 8} {y - 1.5} L{x - 2.5} {y - 2.5} Z" fill="#FFD43B" stroke="{INK}" stroke-width="2.5"/>'
                   for x, y in ((56, 40), (100, 26), (144, 40)))


def lightbulb():
    return ('<g transform="translate(160 40)"><circle r="17" fill="#FFE066" stroke="#2A1A14" stroke-width="4"/><rect x="-8" y="14" width="16" height="10" rx="3" fill="#ADB5BD" stroke="#2A1A14" stroke-width="3"/>'
            '<path d="M-5 -2 Q0 -10 5 -2" fill="none" stroke="#F08C00" stroke-width="3"/>'
            '<path d="M-26 -14 l-8 -5 M26 -14 l8 -5 M0 -24 v-9" stroke="#FFD43B" stroke-width="4" stroke-linecap="round"/></g>')


def magnifier(x=146, y=128, s=1):
    return (f'<g transform="translate({x} {y}) scale({s}) rotate(-25)"><rect x="-5" y="18" width="10" height="38" rx="4" fill="#7A4E22" stroke="{INK}" stroke-width="3.5"/>'
            f'<circle r="22" fill="#BDE7FF" fill-opacity=".55" stroke="#C98A12" stroke-width="7"/><circle r="22" fill="none" stroke="{INK}" stroke-width="2.5"/>'
            '<path d="M-12 -6 Q-8 -14 2 -14" fill="none" stroke="#fff" stroke-width="4" stroke-linecap="round"/></g>')


def finjan(x=144, y=150, s=1, steam_on=True):
    st = (f'<path d="M-6 -22 q-6 -8 0 -16 q6 -8 0 -16 M8 -22 q-6 -8 0 -16" fill="none" stroke="#fff" stroke-width="3.5" stroke-linecap="round" opacity=".9"/>' if steam_on else '')
    return (f'<g transform="translate({x} {y}) scale({s})">{st}<path d="M-18 -16 H18 Q16 10 0 12 Q-16 10 -18 -16 Z" fill="#FFF8E7" stroke="{INK}" stroke-width="4"/>'
            '<path d="M-14 -16 H14" stroke="#C98A12" stroke-width="4"/><path d="M-16 -8 Q0 -2 16 -8" fill="none" stroke="#2CA6A4" stroke-width="3"/>'
            '<ellipse cx="0" cy="-16" rx="16" ry="4" fill="#8D5A2B"/></g>')


def dallah(x=150, y=140, s=1, pour=False):
    p = '<path d="M-36 -18 Q-52 -10 -54 10" fill="none" stroke="#8D5A2B" stroke-width="5" stroke-linecap="round"/>' if pour else ''
    return (f'<g transform="translate({x} {y}) scale({s}) rotate({-30 if pour else 0})">{p}'
            f'<path d="M-14 -40 Q-16 -52 0 -54 Q16 -52 14 -40 Z" fill="#F7C948" stroke="{INK}" stroke-width="3.5"/>'
            f'<path d="M-16 -40 H16 Q22 -20 22 0 Q22 20 0 22 Q-22 20 -22 0 Q-22 -20 -16 -40 Z" fill="#F7C948" stroke="{INK}" stroke-width="4"/>'
            f'<path d="M-20 -14 Q-36 -22 -38 -32 Q-34 -26 -18 -24 Z" fill="#F7C948" stroke="{INK}" stroke-width="3.5"/>'
            f'<path d="M20 -24 Q36 -16 30 10" fill="none" stroke="{INK}" stroke-width="5"/><path d="M-18 6 H18" stroke="#C98A12" stroke-width="3"/>'
            '<path d="M-10 -32 Q-8 -14 -10 8" stroke="#fff" stroke-width="3" opacity=".6"/></g>')


def dates_plate(x=146, y=158):
    return (f'<g transform="translate({x} {y})"><ellipse rx="32" ry="10" fill="#E9ECEF" stroke="{INK}" stroke-width="3.5"/>'
            + ''.join(f'<ellipse cx="{dx}" cy="{dy}" rx="8" ry="5" fill="#6B3410" stroke="{INK}" stroke-width="2.5" transform="rotate({r} {dx} {dy})"/>'
                      for dx, dy, r in ((-14, -6, -20), (0, -8, 10), (14, -6, 30), (-6, -14, 0), (8, -15, -15))) + '</g>')


def dagger(x=150, y=130, rot=-30, s=1):
    return (f'<g transform="translate({x} {y}) rotate({rot}) scale({s})"><path d="M-6 -6 Q-12 22 0 42 Q14 56 30 52 Q12 46 10 30 Q6 12 8 -6 Z" fill="#DEE2E6" stroke="{INK}" stroke-width="3.5"/>'
            f'<rect x="-14" y="-12" width="30" height="8" rx="3" fill="#F7C948" stroke="{INK}" stroke-width="3"/>'
            f'<path d="M-4 -12 L-2 -40 H6 L8 -12 Z" fill="#7A4E22" stroke="{INK}" stroke-width="3"/><circle cx="2" cy="-42" r="5" fill="#F7C948" stroke="{INK}" stroke-width="2.5"/></g>')


def mask_held(x=140, y=150):
    return (f'<g transform="translate({x} {y}) rotate(-12)"><path d="M-34 -10 Q-34 -24 -16 -22 Q0 -20 0 -14 Q0 -20 16 -22 Q34 -24 34 -10 Q34 8 16 6 Q4 4 0 -2 Q-4 4 -16 6 Q-34 8 -34 -10 Z" fill="#7048E8" stroke="{INK}" stroke-width="4"/>'
            '<ellipse cx="-15" cy="-8" rx="8" ry="5" fill="#1A1622"/><ellipse cx="15" cy="-8" rx="8" ry="5" fill="#1A1622"/>'
            f'<path d="M34 -4 L48 30" stroke="#C98A12" stroke-width="5" stroke-linecap="round"/></g>')


def crown(y=30, s=1):
    return (f'<g transform="translate(100 {y}) scale({s})"><path d="M-34 18 L-38 -16 L-18 2 L0 -26 L18 2 L38 -16 L34 18 Z" fill="#FFD43B" stroke="{INK}" stroke-width="4" stroke-linejoin="round"/>'
            '<circle cx="0" cy="8" r="5" fill="#E03131" stroke="#2A1A14" stroke-width="2"/><circle cx="-20" cy="10" r="4" fill="#4DABF7"/><circle cx="20" cy="10" r="4" fill="#4DABF7"/></g>')


def bisht():
    return ('<path d="M24 200 Q28 164 64 150 L84 200 Z M176 200 Q172 164 136 150 L116 200 Z" fill="#1A1622" stroke="#2A1A14" stroke-width="4"/>'
            '<path d="M64 150 L84 200 M136 150 L116 200" stroke="#F7C948" stroke-width="6"/>')


def falcon_arm():
    return ('<g transform="translate(152 136) scale(1.1)"><path d="M-26 34 H22 V48 H-26 Z" fill="#7A4E22" stroke="#2A1A14" stroke-width="3.5"/>'
            '<path d="M-16 32 Q-24 2 -6 -16 Q8 -26 18 -14 Q26 0 20 20 Q12 34 -16 32 Z" fill="#9C7A54" stroke="#2A1A14" stroke-width="3.5"/>'
            '<path d="M-6 -16 Q4 -36 18 -26 Q24 -20 22 -12 Q12 -20 -6 -16 Z" fill="#6E5234" stroke="#2A1A14" stroke-width="3"/>'
            '<circle cx="12" cy="-20" r="3" fill="#111"/><path d="M20 -18 L28 -14 L21 -11 Z" fill="#F7C948" stroke="#2A1A14" stroke-width="1.5"/>'
            '<path d="M-10 4 Q2 10 14 4 M-12 14 Q0 20 14 14" stroke="#4A3826" stroke-width="2.5" fill="none"/></g>')


def trophy(x=150, y=140, s=1):
    return (f'<g transform="translate({x} {y}) scale({s})"><path d="M-22 -30 C-40 -30 -40 -4 -18 -2 M22 -30 C40 -30 40 -4 18 -2" fill="none" stroke="#B9780F" stroke-width="6"/>'
            f'<path d="M-24 -36 H24 V-18 C24 0 12 8 0 10 C-12 8 -24 0 -24 -18 Z" fill="#FFD43B" stroke="{INK}" stroke-width="4"/>'
            f'<rect x="-6" y="10" width="12" height="10" fill="#F7C948" stroke="{INK}" stroke-width="3"/><path d="M-18 20 H18 L22 32 H-22 Z" fill="#FFD43B" stroke="{INK}" stroke-width="4"/></g>')


def fireworks():
    def burst(x, y, r, c):
        rays = ''.join(f'<path d="M{x} {y} m{r * .35 * cos} {r * .35 * sin} l{r * .65 * cos} {r * .65 * sin}" stroke="{c}" stroke-width="5" stroke-linecap="round"/>'
                       for cos, sin in ((1, 0), (-1, 0), (0, 1), (0, -1), (.7, .7), (-.7, .7), (.7, -.7), (-.7, -.7)))
        return rays + f'<circle cx="{x}" cy="{y}" r="5" fill="{c}"/>'
    return burst(34, 40, 26, '#FF6B6B') + burst(166, 50, 24, '#FFD43B') + burst(160, 150, 18, '#4DABF7')


def gold_bars():
    return ('<g transform="translate(146 160)">'
            + ''.join(f'<path d="M{dx - 18} {dy} L{dx - 12} {dy - 12} H{dx + 12} L{dx + 18} {dy} Z" fill="#FFD43B" stroke="#2A1A14" stroke-width="3.5"/>'
                      for dx, dy in ((-16, 10), (16, 10), (0, -4))) + '</g>')


def rocket():
    return ('<g transform="translate(156 60) rotate(40)"><path d="M0 -40 Q16 -20 14 18 H-14 Q-16 -20 0 -40 Z" fill="#F1F3F5" stroke="#2A1A14" stroke-width="4"/>'
            '<circle cy="-8" r="7" fill="#4DABF7" stroke="#2A1A14" stroke-width="3"/>'
            '<path d="M-14 6 L-26 26 L-14 18 Z M14 6 L26 26 L14 18 Z" fill="#E03131" stroke="#2A1A14" stroke-width="3"/>'
            '<path d="M-9 18 Q0 46 9 18 Z" fill="#FF922B" stroke="#2A1A14" stroke-width="3"/></g>')


def lantern(x=152, y=120):
    return (f'<g transform="translate({x} {y})"><path d="M0 -50 V-40" stroke="#2A1A14" stroke-width="4"/><circle cy="-52" r="5" fill="none" stroke="#2A1A14" stroke-width="3"/>'
            '<path d="M-14 -40 H14 L18 -30 H-18 Z" fill="#F7C948" stroke="#2A1A14" stroke-width="3.5"/>'
            '<path d="M-18 -30 H18 Q24 0 14 24 H-14 Q-24 0 -18 -30 Z" fill="#FFE8A3" stroke="#2A1A14" stroke-width="4"/>'
            '<path d="M-6 -24 V18 M6 -24 V18" stroke="#C98A12" stroke-width="3"/><path d="M-16 24 H16 L12 32 H-12 Z" fill="#F7C948" stroke="#2A1A14" stroke-width="3.5"/>'
            '<circle cy="-2" r="26" fill="#FFE066" opacity=".25"/></g>')


def istikana(x=146, y=152):
    return (f'<g transform="translate({x} {y})"><path d="M-14 -24 Q-8 -6 -12 10 H12 Q8 -6 14 -24 Z" fill="#E8590C" fill-opacity=".85" stroke="#2A1A14" stroke-width="3.5"/>'
            '<ellipse cy="12" rx="22" ry="6" fill="#F1F3F5" stroke="#2A1A14" stroke-width="3"/><path d="M-12 -20 H12" stroke="#fff" stroke-width="2" opacity=".6"/></g>')


def nightcap():
    return '<path d="M60 64 Q90 4 150 30 Q170 40 172 60 Q140 44 120 56 Q96 50 60 64 Z" fill="#4263EB" stroke="#2A1A14" stroke-width="4"/><circle cx="174" cy="62" r="9" fill="#fff" stroke="#2A1A14" stroke-width="3"/>'


def star_badge():
    return ('<g transform="translate(152 146)"><path d="M0 -26 L8 -8 L28 -8 L12 4 L18 24 L0 12 L-18 24 L-12 4 L-28 -8 L-8 -8 Z" fill="#FFD43B" stroke="#2A1A14" stroke-width="4" stroke-linejoin="round"/></g>')


def lightning_bolts():
    return ''.join(f'<path d="M{x} {y} l-12 22 h10 l-8 20 l22 -28 h-10 l8 -14 Z" fill="#FFE066" stroke="#2A1A14" stroke-width="3.5" stroke-linejoin="round"/>' for x, y in ((40, 30), (166, 40)))


def mind_waves():
    return ''.join(f'<path d="M{100 - r} {44 - r * .3} Q100 {14 - r * .6} {100 + r} {44 - r * .3}" fill="none" stroke="#C084FC" stroke-width="5" stroke-linecap="round" opacity="{.9 - r / 80}"/>' for r in (24, 38, 52))


def ghost_body():
    return ('<path d="M48 104 Q46 30 100 28 Q154 30 152 104 V170 Q140 160 130 172 Q118 160 108 172 Q98 160 88 172 Q76 160 66 172 Q56 160 48 170 Z" fill="#F8F9FA" fill-opacity=".92" stroke="#2A1A14" stroke-width="5"/>'
            '<ellipse cx="82" cy="94" rx="10" ry="14" fill="#2A1A14"/><ellipse cx="118" cy="94" rx="10" ry="14" fill="#2A1A14"/>'
            '<ellipse cx="100" cy="132" rx="10" ry="12" fill="#2A1A14"/>')


def fist_up():
    return hand(156, 70, 10, 1.05, 'fist')


def clap_hands(skin):
    return (hand(86, 168, -20, 1.0, 'palm', skin) + hand(116, 168, 20, 1.0, 'palm', skin)
            + ''.join(f'<path d="M{x} {y} l{dx} {dy}" stroke="#FFD43B" stroke-width="4" stroke-linecap="round"/>' for x, y, dx, dy in ((100, 122, 0, -12), (82, 128, -8, -8), (118, 128, 8, -8))))


# ───────────── الوصفات: لكل ملصق ─────────────
# (الشخصية، العيون، الحواجب، الفم، [إضافات ورا]، [إضافات قدام])
def rc(ch, e, b, m, back=(), front=()):
    return dict(ch=ch, eyes=e, brows=b, mouth=m, back=list(back), front=list(front))


RECIPES = {
    # الأساسي
    'b_laugh': rc('A', 'laugh', 'up', 'laugh', front=['tears_stream']),
    'b_think': rc('C', 'look_up', 'raised', 'flat', front=['hand_chin', 'marks_q']),
    'b_eyes': rc('D', 'side', 'flat', 'flat'),
    'b_shh': rc('E', 'closed', 'normal', 'pout', front=['finger_lips']),
    'b_smirk': rc('B', 'side', 'raised', 'smirk'),
    'b_angry': rc('G', 'angry', 'angry', 'clench', front=['vein', 'point_out']),
    # صدمة
    'shock_jaw': rc('A', 'wide', 'up', 'O', front=['marks_e']),
    'shock_hands': rc('E', 'wide', 'up', 'O', front=['hands_cheeks']),
    'shock_what': rc('B', 'wide', 'raised', 'o', front=['marks_q', 'palms_up']),
    'shock_no': rc('F', 'closed', 'sad', 'frown', front=['motion', 'hand_stop']),
    'shock_dizzy': rc('G', 'dizzy', 'up', 'wavy', back=['dizzy_stars']),
    'shock_faint': rc('C', 'closed', 'sad', 'o', front=['sweat', 'hand_forehead']),
    # ضحك
    'laugh_tears': rc('B', 'laugh', 'up', 'laugh', front=['tears_stream', 'motion']),
    'laugh_roll': rc('D', 'laugh', 'up', 'laugh', front=['tears_stream'], back=['tilt']),
    'laugh_clap': rc('A', 'happy', 'up', 'laugh', front=['clap']),
    'laugh_point': rc('G', 'laugh', 'up', 'laugh', front=['point_out', 'tears_stream']),
    'laugh_grin': rc('E', 'happy', 'normal', 'grin', front=['blush']),
    'laugh_wink': rc('I', 'wink', 'raised', 'tongue'),
    # القهوة
    'cof_cup': rc('C', 'happy', 'normal', 'smile', front=['finjan']),
    'cof_pour': rc('A', 'normal', 'normal', 'smile', front=['dallah_pour', 'finjan_low']),
    'cof_welcome': rc('I', 'happy', 'up', 'grin', front=['wave']),
    'cof_cold': rc('G', 'sad', 'sad', 'frown', front=['finjan_cold', 'sweat']),
    'cof_dates': rc('E', 'happy', 'normal', 'smile', front=['dates', 'finjan_small']),
    'cof_enough': rc('B', 'closed', 'normal', 'smile', front=['finjan_shake', 'motion']),
    # الزعل
    'ang_steam': rc('G', 'angry', 'angry', 'clench', back=['steam'], front=['vein']),
    'ang_never': rc('D', 'angry', 'angry', 'frown', front=['arms_crossed']),
    'ang_upset': rc('E', 'sad', 'sad', 'pout', front=['tear']),
    'ang_bored': rc('A', 'sleepy', 'flat', 'flat', front=['hand_chin']),
    'ang_ugh': rc('C', 'closed', 'angry', 'wavy', front=['facepalm']),
    'ang_fist': rc('B', 'angry', 'angry', 'clench', front=['fist_up', 'vein']),
    # التوتر
    'nerv_sweat': rc('A', 'wide', 'sad', 'wavy', front=['sweat', 'sweat2']),
    'nerv_cover': rc('E', 'closed', 'sad', 'wavy', front=['cover_eyes', 'blush']),
    'nerv_heart': rc('F', 'wide', 'sad', 'o', front=['heart_beat']),
    'nerv_luck': rc('G', 'sad', 'sad', 'frown', front=['tear', 'palms_up']),
    'nerv_notme': rc('B', 'side', 'sad', 'wavy', front=['palms_out', 'sweat']),
    'nerv_bite': rc('D', 'wide', 'up', 'clench', front=['sweat']),
    # المحقق
    'det_who': rc('C', 'side', 'raised', 'flat', front=['magnifier', 'marks_q']),
    'det_clue': rc('F', 'normal', 'up', 'grin', front=['paper']),
    'det_watch': rc('G', 'side', 'angry', 'flat', front=['binoculars']),
    'det_obvious': rc('I', 'normal', 'raised', 'smirk', front=['point_out']),
    'det_solved': rc('A', 'star', 'up', 'grin', front=['lightbulb']),
    'det_hmm': rc('B', 'side', 'raised', 'wavy', front=['hand_chin', 'marks_q']),
    # البريء
    'inn_me': rc('A', 'teary', 'sad', 'o', front=['palms_up']),
    'inn_cry': rc('E', 'closed', 'sad', 'frown', front=['tears_stream']),
    'inn_trust': rc('C', 'normal', 'sad', 'smile', front=['hand_heart']),
    'inn_halo': rc('D', 'happy', 'normal', 'smile', back=['halo'], front=['blush']),
    'inn_hands': rc('G', 'wide', 'sad', 'wavy', front=['hands_up']),
    'inn_pls': rc('F', 'teary', 'sad', 'pout', front=['hands_pray']),
    # الاحتفال
    'par_kafu': rc('A', 'happy', 'up', 'grin', front=['thumb']),
    'par_won': rc('B', 'star', 'up', 'laugh', front=['trophy']),
    'par_clap': rc('E', 'happy', 'up', 'grin', front=['clap']),
    'par_fireworks': rc('C', 'star', 'up', 'laugh', back=['fireworks']),
    'par_dance': rc('G', 'closed', 'up', 'laugh', front=['dance_arms', 'motion']),
    'par_best': rc('I', 'sun', 'normal', 'smirk', front=['star_badge']),
    # الخاين
    'tr_evil': rc('H', 'evil', 'angry', 'none', front=['sparkle_evil']),
    'tr_dagger': rc('G', 'evil', 'angry', 'evil', front=['dagger']),
    'tr_poker': rc('B', 'tiny', 'flat', 'flat'),
    'tr_plan': rc('H', 'evil', 'angry', 'none', front=['steeple']),
    'tr_mask': rc('A', 'side', 'raised', 'smirk', front=['mask']),
    'tr_laugh': rc('G', 'evil', 'angry', 'evil', back=['flames']),
    # الفخامة
    'vip_falcon': rc('C', 'normal', 'normal', 'smile', front=['bisht', 'falcon']),
    'vip_bisht': rc('I', 'closed', 'normal', 'smirk', front=['bisht']),
    'vip_gg': rc('B', 'happy', 'up', 'grin', front=['thumb', 'sparkles']),
    'vip_crown': rc('A', 'happy', 'normal', 'smile', back=['crown_on'], front=['hand_head']),
    'vip_gold': rc('G', 'money', 'up', 'grin', front=['gold_bars']),
    'vip_cool': rc('B', 'sun', 'flat', 'smirk', front=['sparkles']),
    # الحماس
    'hype_fire': rc('A', 'star', 'angry', 'grin', back=['flames']),
    'hype_go': rc('E', 'normal', 'angry', 'laugh', front=['fist_up']),
    'hype_strong': rc('G', 'angry', 'angry', 'grin', front=['flex']),
    'hype_100': rc('B', 'star', 'up', 'grin', front=['badge_100']),
    'hype_rocket': rc('I', 'star', 'up', 'laugh', front=['rocket']),
    'hype_eyes': rc('F', 'side', 'angry', 'flat', front=['point_eyes']),
    # الأساطير
    'leg_king': rc('C', 'closed', 'normal', 'smirk', back=['crown_on'], front=['bisht']),
    'leg_genius': rc('A', 'star', 'up', 'grin', front=['lightbulb', 'sparkles']),
    'leg_ghost': rc('A', 'none', 'none', 'none', back=['ghost']),
    'leg_mind': rc('F', 'glow', 'up', 'flat', back=['mind_waves'], front=['fingers_temple']),
    'leg_storm': rc('G', 'angry', 'angry', 'clench', back=['lightning']),
    'leg_legend': rc('B', 'sun', 'flat', 'smirk', back=['crown_on'], front=['sparkles']),
    # الموسم الأول
    's1_night': rc('A', 'happy', 'up', 'grin', back=['moon_stars']),
    's1_champ': rc('B', 'star', 'up', 'laugh', front=['trophy', 'sparkles']),
    's1_tea': rc('E', 'happy', 'normal', 'smile', front=['istikana']),
    's1_lantern': rc('C', 'happy', 'normal', 'smile', front=['lantern']),
    's1_sleep': rc('G', 'sleepy', 'flat', 'yawn', back=['nightcap'], front=['zzz']),
    's1_star': rc('D', 'star', 'up', 'grin', front=['star_badge', 'sparkles']),
}

PACK_COLORS = {
    'stk_basic': '#FFFFFF', 'stk_shock': '#FFE066', 'stk_laugh': '#FFD43B', 'stk_coffee': '#F5D0A9', 'stk_angry': '#FF8787',
    'stk_nervous': '#A5D8FF', 'stk_detective': '#FFE8A3', 'stk_innocent': '#B2F2BB', 'stk_party': '#FFD43B', 'stk_traitor': '#FF6B6B',
    'stk_vip': '#FFD54F', 'stk_hype': '#FFA94D', 'stk_legend': '#E599F7', 'stk_s1': '#63E6BE',
}

def extra(name, ch):
    sk = ch['skin']
    m = {
        'tears_stream': tears_stream, 'tear': tear, 'sweat': sweat, 'sweat2': lambda: sweat(56, 70), 'vein': vein, 'steam': steam,
        'blush': blush, 'marks_q': lambda: marks('q'), 'marks_e': lambda: marks('e'), 'sparkles': sparkles, 'motion': motion,
        'halo': halo, 'flames': flames_back, 'zzz': zzz, 'dizzy_stars': dizzy_stars, 'lightbulb': lightbulb,
        'magnifier': magnifier, 'finjan': finjan, 'finjan_low': lambda: finjan(132, 176, .85, False), 'finjan_small': lambda: finjan(64, 166, .8),
        'finjan_cold': lambda: finjan(146, 156, 1, False), 'dallah_pour': lambda: dallah(166, 112, .8, True), 'dates': dates_plate,
        'dagger': dagger, 'mask': mask_held, 'crown_on': lambda: crown(30, 1.05), 'bisht': bisht, 'falcon': falcon_arm, 'trophy': trophy,
        'fireworks': fireworks, 'gold_bars': gold_bars, 'rocket': rocket, 'lantern': lantern, 'istikana': istikana, 'nightcap': nightcap,
        'star_badge': star_badge, 'lightning': lightning_bolts, 'mind_waves': mind_waves, 'ghost': ghost_body, 'fist_up': lambda: hand(156, 72, 10, 1.05, 'fist', sk),
        'clap': lambda: clap_hands(sk),
        'hand_chin': lambda: hand(116, 156, -150, .95, 'point', sk),
        'finger_lips': lambda: hand(100, 160, 0, .9, 'point', sk),
        'point_out': lambda: hand(150, 150, -40, 1.05, 'point', sk),
        'hands_cheeks': lambda: hand(58, 128, -20, .95, 'palm', sk) + hand(142, 128, 20, .95, 'palm', sk),
        'palms_up': lambda: hand(36, 168, -60, .9, 'palm', sk) + hand(164, 168, 60, .9, 'palm', sk),
        'hand_stop': lambda: hand(152, 150, 10, 1.05, 'palm', sk),
        'hand_forehead': lambda: hand(120, 62, 100, .95, 'palm', sk),
        # كف على الجبهة والعيون: الذراع من تحت والأصابع لفوق (مو مقلوبة).
        'facepalm': lambda: arm(78, 206, 96, 136, ch) + hand(100, 98, -8, 1.12, 'palm', sk),
        # يدين تغطي العيون من الفشلة: كل يد على عين، والأصابع لفوق.
        'cover_eyes': lambda: (arm(58, 206, 80, 138, ch) + arm(142, 206, 120, 138, ch)
                               + hand(82, 100, -6, 1.0, 'palm', sk) + hand(118, 100, 6, 1.0, 'palm', sk, flip=True)),
        'heart_beat': lambda: '<path d="M150 150 q-14 -16 -24 -4 q-10 14 24 34 q34 -20 24 -34 q-10 -12 -24 4 Z" fill="#FF6B6B" stroke="#2A1A14" stroke-width="4"/>' + motion(),
        'palms_out': lambda: hand(40, 160, -20, .9, 'palm', sk) + hand(160, 160, 20, .9, 'palm', sk),
        'paper': lambda: '<g transform="translate(150 146) rotate(10)"><rect x="-22" y="-28" width="44" height="56" rx="4" fill="#FFF8E7" stroke="#2A1A14" stroke-width="4"/><path d="M-12 -14 H12 M-12 -4 H8 M-12 6 H12" stroke="#ADB5BD" stroke-width="4"/><circle cx="8" cy="16" r="7" fill="none" stroke="#E03131" stroke-width="3"/></g>',
        'binoculars': lambda: '<g transform="translate(100 100)"><circle cx="-18" cy="0" r="16" fill="#343A40" stroke="#2A1A14" stroke-width="4"/><circle cx="18" cy="0" r="16" fill="#343A40" stroke="#2A1A14" stroke-width="4"/><circle cx="-18" cy="0" r="9" fill="#74C0FC"/><circle cx="18" cy="0" r="9" fill="#74C0FC"/><rect x="-6" y="-6" width="12" height="10" fill="#495057" stroke="#2A1A14" stroke-width="3"/></g>',
        'hand_heart': lambda: hand(124, 168, 0, .95, 'palm', sk) + '<path d="M80 168 q-8 -9 -14 -2 q-6 8 14 20 q20 -12 14 -20 q-6 -7 -14 2 Z" fill="#FF6B6B" stroke="#2A1A14" stroke-width="3"/>',
        'hands_up': lambda: hand(34, 96, -15, 1.0, 'palm', sk) + hand(166, 96, 15, 1.0, 'palm', sk),
        'hands_pray': lambda: hand(92, 170, 8, .95, 'palm', sk) + hand(108, 170, -8, .95, 'palm', sk),
        'thumb': lambda: hand(154, 156, 0, 1.1, 'thumb', sk),
        'dance_arms': lambda: hand(30, 84, -40, .95, 'palm', sk) + hand(168, 150, 40, .95, 'palm', sk),
        'sparkle_evil': lambda: sparkles('#FF6B6B'),
        'steeple': lambda: hand(90, 172, 15, .9, 'palm', sk) + hand(110, 172, -15, .9, 'palm', sk),
        'hand_head': lambda: hand(56, 56, -150, .9, 'palm', sk),
        'flex': lambda: '<g transform="translate(150 130)"><path d="M-30 30 Q-34 0 -14 -6 Q-6 -30 10 -28 Q24 -26 18 -10 Q34 0 26 26 Z" fill="' + SKIN[sk][0] + '" stroke="#2A1A14" stroke-width="4"/><path d="M-8 -6 Q4 2 16 -4" fill="none" stroke="#2A1A14" stroke-width="3"/></g>',
        'badge_100': lambda: '<g transform="translate(154 150) rotate(-12)"><rect x="-30" y="-18" width="60" height="36" rx="10" fill="#E03131" stroke="#2A1A14" stroke-width="4"/><text x="0" y="10" font-family="Marhey" font-weight="bold" font-size="26" text-anchor="middle" fill="#fff">١٠٠</text></g>',
        'point_eyes': lambda: hand(150, 124, -100, .9, 'point', sk),
        'fingers_temple': lambda: hand(48, 90, 60, .9, 'point', sk) + hand(152, 90, -60, .9, 'point', sk),
        'moon_stars': lambda: '<path d="M164 18 Q138 22 138 48 Q140 74 166 76 Q150 66 150 47 Q150 28 164 18 Z" fill="#FFE066" stroke="#2A1A14" stroke-width="3.5"/>' + sparkles('#FFF3BF'),
        'arms_crossed': lambda: '<path d="M44 196 Q50 170 100 168 Q150 170 156 196 Z" fill="' + SKIN[sk][0] + '" stroke="#2A1A14" stroke-width="4"/><path d="M52 186 Q100 160 148 186" fill="none" stroke="#2A1A14" stroke-width="4"/>',
        'finjan_shake': lambda: finjan(150, 150, 1, False) + motion(),
        'wave': lambda: hand(158, 118, 20, 1.05, 'palm', sk) + '<path d="M180 92 q8 10 0 20 M186 84 q12 16 0 34" fill="none" stroke="#2A1A14" stroke-width="3.5" stroke-linecap="round"/>',
        'tilt': lambda: '',
    }
    return m[name]()


def body(ch):
    """الثوب أو العباية تحت الوجه."""
    if ch['head'] == 'hijab':
        return '<path d="M30 200 Q34 160 72 150 Q100 160 128 150 Q166 160 170 200 Z" fill="#1E1B26" stroke="#2A1A14" stroke-width="5"/>'
    col = '#2B2B35' if ch.get('masked') else '#F4F1EA'
    return (f'<path d="M30 200 Q34 160 70 150 Q100 162 130 150 Q166 160 170 200 Z" fill="{col}" stroke="#2A1A14" stroke-width="5"/>'
            '<path d="M92 154 L100 178 L108 154" stroke="#2A1A14" stroke-width="3" fill="none" opacity=".5"/>')


def compose(sid, caption, color):
    r = RECIPES[sid]
    ch = CHARS[r['ch']]
    parts = []
    for b in r['back']:
        parts.append(extra(b, ch))
    if 'ghost' not in r['back']:
        parts.append(body(ch))
        parts.append(head_back(ch))
        parts.append(face(ch))
        parts.append(beard(ch))
        if ch['head'] == 'hijab':
            parts.append(head_front(ch))
        parts.append(brows(r['brows'], ch))
        parts.append(eyes(r['eyes'], SKIN[ch['skin']][0]))
        if ch.get('glasses') and r['eyes'] not in ('sun', 'glow', 'star', 'money'):
            parts.append(f'<circle cx="{L[0]}" cy="{L[1]}" r="13" fill="none" stroke="{INK}" stroke-width="3.5"/><circle cx="{R[0]}" cy="{R[1]}" r="13" fill="none" stroke="{INK}" stroke-width="3.5"/><path d="M95 98 H105" stroke="{INK}" stroke-width="3.5"/>')
        parts.append(mustache(ch))
        if ch.get('masked'):
            parts.append('<path d="M60 108 Q100 100 140 108 L140 150 Q100 166 60 150 Z" fill="url(#shemagh)" stroke="#2A1A14" stroke-width="5"/>')
        else:
            parts.append(mouth(r['mouth']))
        if ch['head'] != 'hijab':
            parts.append(head_front(ch))
    for f in r['front']:
        parts.append(extra(f, ch))
    art = ''.join(parts)
    tilt = -10 if 'tilt' in r['back'] else 0
    size = 34 if len(caption) <= 8 else (28 if len(caption) <= 11 else 24)
    return f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="-14 -10 228 236" width="512" height="530">
<defs><pattern id="shemagh" width="10" height="10" patternUnits="userSpaceOnUse" patternTransform="rotate(45)">
<rect width="10" height="10" fill="#FBF7F2"/><rect width="5" height="5" fill="#C8262E"/><rect x="5" y="5" width="5" height="5" fill="#C8262E"/></pattern></defs>
<g transform="rotate({tilt} 100 110)">{art}</g>
<g transform="rotate(-5 100 196)"><text x="100" y="208" font-family="Marhey" font-weight="bold" font-size="{size}" text-anchor="middle"
 fill="{color}" stroke="#1A0F0A" stroke-width="9" stroke-linejoin="round" paint-order="stroke">{caption}</text></g>
</svg>'''


def outline(png_bytes, size=256):
    """حافة بيضاء سميكة وظل خفيف، مثل الملصقات."""
    im = Image.open(io.BytesIO(png_bytes)).convert('RGBA')
    pad = 24
    canvas = Image.new('RGBA', (im.width + pad * 2, im.height + pad * 2), (0, 0, 0, 0))
    canvas.alpha_composite(im, (pad, pad))
    a = canvas.getchannel('A')
    grown = a.filter(ImageFilter.MaxFilter(17)).filter(ImageFilter.MaxFilter(9)).filter(ImageFilter.GaussianBlur(1.2))
    white = Image.new('RGBA', canvas.size, (255, 255, 255, 0))
    white.putalpha(grown)
    shadow = Image.new('RGBA', canvas.size, (0, 0, 0, 0))
    shadow.putalpha(grown.point(lambda v: v * .45).filter(ImageFilter.GaussianBlur(7)))
    out = Image.new('RGBA', canvas.size, (0, 0, 0, 0))
    out.alpha_composite(shadow, (0, 8))
    out.alpha_composite(white)
    out.alpha_composite(canvas)
    bbox = out.getbbox()
    out = out.crop(bbox)
    side = max(out.size)
    sq = Image.new('RGBA', (side, side), (0, 0, 0, 0))
    sq.alpha_composite(out, ((side - out.width) // 2, (side - out.height) // 2))
    return sq.resize((size, size), Image.LANCZOS)


def render(item):
    sid, caption, color = item
    path = os.path.join(SRC, f'{sid}.svg')
    open(path, 'w').write(compose(sid, caption, color))
    png = subprocess.run(['inkscape', path, '--export-type=png', '--export-filename=-', '-w', '512'], check=True, capture_output=True).stdout
    outline(png).save(os.path.join(OUT, f'{sid}.webp'), quality=90, method=6)
    return sid


if __name__ == '__main__':
    os.makedirs(SRC, exist_ok=True)
    os.makedirs(OUT, exist_ok=True)
    items = [(sid, cap, PACK_COLORS[p['id']]) for p in catalog.STICKER_PACKS for sid, cap in p['stickers'] if not ONLY or sid in ONLY]
    missing = [i[0] for i in items if i[0] not in RECIPES]
    assert not missing, missing
    with ThreadPoolExecutor(6) as ex:
        done = list(ex.map(render, items))
    print(len(done), 'stickers')
