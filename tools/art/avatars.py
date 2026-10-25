"""يرسم شخصيات اللعبة (فيكتور SVG) بأسلوب مسطح: غترة، شماغ، حجاب، لحى، نظارات."""
import os
import sys

OUT = sys.argv[1]
os.makedirs(OUT, exist_ok=True)

SKIN = {'light': '#F2C9A0', 'tan': '#D9A274', 'brown': '#B07A4F', 'deep': '#8A5A3A'}
SKIN_SHADE = {'light': '#E2B088', 'tan': '#C48A5E', 'brown': '#97653E', 'deep': '#734830'}
HAIR = {'black': '#231A16', 'brown': '#4A3121', 'grey': '#BDB6AE'}


def face(skin, beard=None, beard_color='black', glasses=None, smile=True, brows='normal', ears=True):
    s, sh = SKIN[skin], SKIN_SHADE[skin]
    hc = HAIR[beard_color]
    parts = [
        # الرقبة
        f'<path d="M84 128 L84 150 Q100 158 116 150 L116 128 Z" fill="{sh}"/>',
        # الوجه
        f'<ellipse cx="100" cy="104" rx="33" ry="38" fill="{s}"/>',
    ]
    if ears:
        parts.append(f'<ellipse cx="67" cy="106" rx="6" ry="9" fill="{sh}"/><ellipse cx="133" cy="106" rx="6" ry="9" fill="{sh}"/>')
    if beard == 'full':
        parts.append(f'<path d="M68 104 Q68 150 100 150 Q132 150 132 104 Q128 128 118 130 Q100 138 82 130 Q72 128 68 104 Z" fill="{hc}"/>')
        parts.append(f'<path d="M86 124 Q100 118 114 124 Q108 130 100 130 Q92 130 86 124 Z" fill="{hc}"/>')
    elif beard == 'goatee':
        parts.append(f'<path d="M88 126 Q100 120 112 126 Q110 142 100 144 Q90 142 88 126 Z" fill="{hc}"/>')
        parts.append(f'<path d="M86 122 Q100 116 114 122 Q100 126 86 122 Z" fill="{hc}"/>')
    elif beard == 'stubble':
        parts.append(f'<path d="M70 108 Q72 146 100 147 Q128 146 130 108 Q124 130 100 134 Q76 130 70 108 Z" fill="{hc}" opacity=".35"/>')
        parts.append(f'<path d="M86 122 Q100 117 114 122 Q100 125 86 122 Z" fill="{hc}"/>')
    elif beard == 'mustache':
        parts.append(f'<path d="M84 123 Q100 115 116 123 Q108 121 100 124 Q92 121 84 123 Z" fill="{hc}"/>')
    # الحواجب
    by = 92 if brows == 'normal' else 90
    tilt = 3 if brows == 'sly' else 0
    parts.append(f'<path d="M80 {by + tilt} Q88 {by - 4} 95 {by}" stroke="{HAIR["black"] if beard_color != "grey" else "#8F877F"}" stroke-width="3.5" fill="none" stroke-linecap="round"/>')
    parts.append(f'<path d="M105 {by} Q112 {by - 4} 120 {by + tilt}" stroke="{HAIR["black"] if beard_color != "grey" else "#8F877F"}" stroke-width="3.5" fill="none" stroke-linecap="round"/>')
    # العيون
    if glasses == 'sun':
        parts.append('<path d="M76 99 H96 Q97 112 86 112 Q76 112 76 99 Z M104 99 H124 Q124 112 114 112 Q103 112 104 99 Z" fill="#15151F"/>')
        parts.append('<path d="M96 101 H104" stroke="#15151F" stroke-width="3"/>')
        parts.append('<path d="M80 102 L86 102" stroke="#fff" stroke-width="2" opacity=".5" stroke-linecap="round"/>')
    else:
        parts.append('<ellipse cx="88" cy="103" rx="4" ry="4.6" fill="#1D1A24"/><ellipse cx="112" cy="103" rx="4" ry="4.6" fill="#1D1A24"/>')
        parts.append('<circle cx="89.4" cy="101.6" r="1.3" fill="#fff"/><circle cx="113.4" cy="101.6" r="1.3" fill="#fff"/>')
        if glasses == 'round':
            parts.append('<circle cx="88" cy="103" r="9" fill="none" stroke="#2B2B33" stroke-width="2.5"/><circle cx="112" cy="103" r="9" fill="none" stroke="#2B2B33" stroke-width="2.5"/><path d="M97 103 H103" stroke="#2B2B33" stroke-width="2.5"/>')
    # الأنف والفم
    parts.append(f'<path d="M100 106 Q97 114 101 116" stroke="{sh}" stroke-width="2.5" fill="none" stroke-linecap="round"/>')
    if beard != 'full':
        mouth = 'M92 128 Q100 134 108 128' if smile else 'M93 130 Q100 128 107 130'
        parts.append(f'<path d="{mouth}" stroke="#7A3B33" stroke-width="3" fill="none" stroke-linecap="round"/>')
    else:
        parts.append('<path d="M93 131 Q100 135 107 131" stroke="#E9D6C8" stroke-width="2.5" fill="none" stroke-linecap="round" opacity=".8"/>')
    # خدود
    parts.append('<ellipse cx="78" cy="116" rx="5" ry="3" fill="#E77A6E" opacity=".25"/><ellipse cx="122" cy="116" rx="5" ry="3" fill="#E77A6E" opacity=".25"/>')
    return '\n'.join(parts)


def thobe(color='#F4F1EA', collar='#E3DED3'):
    return (f'<path d="M30 200 Q34 158 70 148 Q100 160 130 148 Q166 158 170 200 Z" fill="{color}"/>'
            f'<path d="M92 152 L100 176 L108 152" stroke="{collar}" stroke-width="3" fill="none"/>')


def abaya(color='#1E1B26'):
    return f'<path d="M28 200 Q32 156 72 146 Q100 156 128 146 Q168 156 172 200 Z" fill="{color}"/>'


def ghutra(pattern=None, agal=True):
    """الغترة: بيضاء، أو شماغ أحمر بنقش مربعات."""
    fill = 'url(#shemagh)' if pattern == 'red' else '#FBFAF7'
    shade = '#E9E4DA' if pattern is None else '#C9C1B4'
    out = [
        f'<path d="M58 106 Q54 62 100 56 Q146 62 142 106 L150 168 Q132 150 126 118 Q122 84 100 82 Q78 84 74 118 Q68 150 50 168 Z" fill="{fill}"/>',
        f'<path d="M66 100 Q64 74 100 70 Q136 74 134 100" fill="none" stroke="{shade}" stroke-width="3" opacity=".7"/>',
    ]
    if agal:
        out.append('<path d="M62 76 Q100 58 138 76 L138 84 Q100 66 62 84 Z" fill="#18151B"/>')
        out.append('<path d="M62 88 Q100 70 138 88 L138 95 Q100 78 62 95 Z" fill="#18151B"/>')
    return '\n'.join(out)


def hijab(color, accent=None):
    out = [
        f'<path d="M60 112 Q56 58 100 54 Q144 58 140 112 Q142 148 128 160 Q100 172 72 160 Q58 148 60 112 Z" fill="{color}"/>',
        # فتحة الوجه
    ]
    if accent:
        out.append(f'<path d="M66 92 Q100 62 134 92" stroke="{accent}" stroke-width="4" fill="none" opacity=".8"/>')
    return '\n'.join(out)


def hijab_front(color):
    """الحجاب حول الوجه: نفس الشكل الخارجي، ومفتوح على شكل الوجه."""
    outer = 'M60 112 Q56 58 100 54 Q144 58 140 112 Q142 148 128 160 Q100 172 72 160 Q58 148 60 112 Z'
    opening = 'M100 74 Q127 74 129 104 Q129 138 100 142 Q71 138 71 104 Q73 74 100 74 Z'
    return (f'<path d="{outer} {opening}" fill="{color}" fill-rule="evenodd"/>'
            f'<path d="{opening}" fill="none" stroke="#000" stroke-opacity=".12" stroke-width="2"/>')


def wrap(bg1, bg2, body):
    return f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 200" width="512" height="512">
<defs>
  <radialGradient id="bg" cx="50%" cy="38%" r="70%"><stop offset="0" stop-color="{bg1}"/><stop offset="1" stop-color="{bg2}"/></radialGradient>
  <pattern id="shemagh" width="10" height="10" patternUnits="userSpaceOnUse" patternTransform="rotate(45)">
    <rect width="10" height="10" fill="#FBF7F2"/><rect width="5" height="5" fill="#C8262E"/><rect x="5" y="5" width="5" height="5" fill="#C8262E"/>
  </pattern>
  <clipPath id="c"><circle cx="100" cy="100" r="100"/></clipPath>
</defs>
<g clip-path="url(#c)">
<rect width="200" height="200" fill="url(#bg)"/>
<path d="M0 150 Q100 120 200 150 V200 H0 Z" fill="#000" opacity=".08"/>
{body}
</g>
</svg>'''


CHARACTERS = {
    # رجال بغترة بيضاء
    'falcon': ('#3B5BDB', '#1E2A6B', thobe() + face('tan', beard='goatee') + ghutra()),
    'sheikh': ('#B8860B', '#5C3D05', thobe('#EFE9DD') + face('light', beard='full', beard_color='grey') + ghutra()),
    'cool': ('#0CA678', '#065A46', thobe() + face('brown', beard='stubble', glasses='sun') + ghutra()),
    'scholar': ('#7048E8', '#33207A', thobe('#E8E4DA') + face('light', beard='full', glasses='round') + ghutra()),
    # رجال بشماغ أحمر
    'desert': ('#E8590C', '#7A2C05', thobe('#D8C9AE', '#BFAF92') + face('deep', beard='full') + ghutra('red')),
    'hawk': ('#C92A2A', '#5E1111', thobe('#2B2B35', '#3D3D4A') + face('tan', beard='mustache', brows='sly') + ghutra('red')),
    'merchant': ('#1098AD', '#0A4A55', thobe('#F1EDE4') + face('brown', beard='goatee', glasses='round') + ghutra('red')),
    'youth': ('#F59F00', '#7A4E00', thobe() + face('light', beard=None) + ghutra('red', agal=True)),
    # نساء بحجاب
    'pearl': ('#D6336C', '#6B1234', abaya() + hijab('#2A2433', '#C9A227') + face('light', ears=False) + hijab_front('#2A2433')),
    'rose': ('#AE3EC9', '#4F1A5C', abaya('#3A1E40') + hijab('#B5446E') + face('tan', ears=False) + hijab_front('#B5446E')),
    'night': ('#4263EB', '#1B2A73', abaya() + hijab('#1C3D6E', '#7FB3FF') + face('brown', glasses='sun', ears=False) + hijab_front('#1C3D6E')),
    'jasmine': ('#37B24D', '#155C22', abaya('#24312A') + hijab('#E9E2D0') + face('light', glasses='round', ears=False) + hijab_front('#E9E2D0')),
    'amber': ('#F76707', '#7A3003', abaya('#3A2416') + hijab('#8C5A2B', '#F4C27A') + face('deep', ears=False) + hijab_front('#8C5A2B')),
    'sky': ('#15AABF', '#0B4F5A', abaya('#1F2A33') + hijab('#5BC0BE') + face('tan', brows='sly', ears=False) + hijab_front('#5BC0BE')),
    # المقنّع (للبوتات والغامض)
    'masked': ('#495057', '#1A1D20', thobe('#1E1E26', '#2E2E3A') + face('tan', beard='stubble') + ghutra('red') +
               '<path d="M66 108 Q100 102 134 108 L134 150 Q100 162 66 150 Z" fill="url(#shemagh)"/>'),
    'shadow': ('#5F3DC4', '#21124F', abaya('#14121B') + hijab('#14121B') + face('deep', brows='sly', ears=False) + hijab_front('#14121B') +
               '<path d="M70 110 Q100 106 130 110 L128 150 Q100 160 72 150 Z" fill="#14121B"/>'),
}

for name, (b1, b2, body) in CHARACTERS.items():
    with open(os.path.join(OUT, f'{name}.svg'), 'w') as f:
        f.write(wrap(b1, b2, body))
print(len(CHARACTERS), 'characters')
