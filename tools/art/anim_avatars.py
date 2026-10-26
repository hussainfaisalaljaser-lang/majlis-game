"""
الشخصيات اللي تتحرك: كل شخصية طبقات من نفس الرسمة (الجسم، الرمشة، الإكسسوار…) بلوحة أكبر من الدائرة
(viewBox ‎-20 -20 240 240) عشان الأجنحة وغيرها تقدر تطلع برا الإطار. التطبيق يحركها (widgets/anim_avatar.dart).
الطبقات الداخلية مقصوصة على الدائرة، وطبقات «pop_» بدون قص (تنرسم فوق الإطار).
ويطلع معها الشكل الثابت (assets/avatars/<id>.webp) بنفس الرسمة للقوائم.
تشغيل:  python3 tools/art/anim_avatars.py app/assets/avatars [ids,...]
"""
import io, os, subprocess, sys
from concurrent.futures import ThreadPoolExecutor

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = sys.argv[1] if len(sys.argv) > 1 else 'app/assets/avatars'
SRC = os.path.join(HERE, 'build', 'anim')

src = open(os.path.join(HERE, 'avatars.py')).read()
exec(src[src.index('SKIN ='):src.index('CHARACTERS =')])  # face, thobe, ghutra, wrap…
psrc = open(os.path.join(HERE, 'premium.py')).read()
exec(psrc[psrc.index('def bisht'):psrc.index('PREMIUM = {')])  # bisht, tiara, necklace…
csrc = open(os.path.join(HERE, 'characters.py')).read()
exec(csrc[csrc.index("INK = '#1E1720'"):csrc.index('# ───────────── الشخصيات المميزة')])  # helmet, turban, mascots…

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


# ───────────── باقي الشخصيات الملحمية والأسطورية ─────────────
# كل شخصية: الجسم، والراس (الوجه وغطاه)، والرمشة، وأغراضها. التطبيق يحركها (widgets/anim_avatar.dart):
# تتنفس وترمش وتحرك راسها، ولكل وحدة حركة خاصة. الطبقات بدون قص (الصورة نفسها مقصوصة في التطبيق).

def lids(skin='tan', lashes=False, xs=(88, 112), y=103):
    """جفون مسكّرة فوق العيون (الرمشة)."""
    s = SKIN[skin]
    out = ''
    for x in xs:
        out += (f'<ellipse cx="{x}" cy="{y}" rx="5.4" ry="5.9" fill="{s}"/>'
                f'<path d="M{x - 4.6} {y + .8} Q{x} {y + 3.8} {x + 4.6} {y + .8}" stroke="#1D1A24" stroke-width="1.8" fill="none" stroke-linecap="round"/>')
        if lashes:
            side = -1 if x < 100 else 1
            out += f'<path d="M{x + side * 4.4} {y + 1.4} l{side * 2.4} -1.6" stroke="#1D1A24" stroke-width="1.4" stroke-linecap="round"/>'
    return out


def mouth_open(beard=False):
    """فم مفتوح (يضحك أو يتكلم)."""
    lip = '#E9D6C8' if beard else '#7A3B33'
    return (f'<path d="M91 127 Q100 141 109 127 Q100 130 91 127 Z" fill="#4A1712" stroke="{lip}" stroke-width="2" stroke-linejoin="round"/>'
            '<path d="M94 128.6 Q100 130.6 106 128.6" stroke="#fff" stroke-width="1.6" fill="none" stroke-linecap="round"/>')


def below(color, x0=24, x1=176, y=196):
    """امتداد للجسم تحت الدائرة، عشان لو تحرك لفوق ما يبان فراغ."""
    return f'<rect x="{x0}" y="{y}" width="{x1 - x0}" height="{224 - y}" fill="{color}"/>'


def cap_only():
    return ('<path d="M62 96 Q60 56 100 54 Q140 56 138 96 Q140 120 132 128 L126 104 Q118 80 100 80 Q82 80 74 104 L68 128 Q60 120 62 96 Z" fill="#7A4A2A"/>'
            '<path d="M70 78 Q100 66 130 78 L130 88 Q100 76 70 88 Z" fill="#5A3520"/>')


def goggles():
    return ('<circle cx="84" cy="74" r="11" fill="#9BD3FF" stroke="#C9A227" stroke-width="4"/><circle cx="116" cy="74" r="11" fill="#9BD3FF" stroke="#C9A227" stroke-width="4"/>'
            '<path d="M95 74 H105" stroke="#C9A227" stroke-width="4"/>'
            '<path d="M78 69 Q82 65 87 67 M110 69 Q114 65 119 67" stroke="#fff" stroke-width="2" fill="none" opacity=".8" stroke-linecap="round"/>')


def helmet_plume(plume):
    return f'<path d="M100 40 Q122 20 132 34 Q116 34 106 48 Z" fill="{plume}"/>'


def crystal_ball_glow():
    return '<circle cx="100" cy="172" r="17" fill="#F5D0FE" opacity=".9"/><circle cx="100" cy="172" r="26" fill="#E879F9" opacity=".35"/>'


def eyes_glow(color, xs=(88, 112), y=103):
    return ''.join(f'<ellipse cx="{x}" cy="{y}" rx="7" ry="5.5" fill="{color}" opacity=".9"/><ellipse cx="{x}" cy="{y}" rx="12" ry="9" fill="{color}" opacity=".3"/>' for x in xs)


def ghost_cloak(color='#1B1030'):
    return (f'<path d="M44 120 Q40 40 100 32 Q160 40 156 120 L168 200 H32 Z" fill="{color}"/>' + below(color, 32, 168, 198) +
            '<path d="M64 112 Q64 64 100 60 Q136 64 136 112 Q136 150 100 156 Q64 150 64 112 Z" fill="#05010D"/>')


def ghost_eyes():
    return ('<ellipse cx="86" cy="106" rx="16" ry="10" fill="#A855F7" opacity=".3"/><ellipse cx="114" cy="106" rx="16" ry="10" fill="#A855F7" opacity=".3"/>'
            '<ellipse cx="86" cy="106" rx="9" ry="5" fill="#C084FC"/><ellipse cx="114" cy="106" rx="9" ry="5" fill="#C084FC"/>')


def ghost_mouth():
    return '<ellipse cx="100" cy="134" rx="7" ry="9" fill="#C084FC" opacity=".85"/><ellipse cx="100" cy="134" rx="4" ry="6" fill="#05010D"/>'


def assassin_head():
    return (face('tan', brows='sly') +
            '<path d="M58 106 Q54 62 100 56 Q146 62 142 106 L150 168 Q132 150 126 118 Q122 84 100 82 Q78 84 74 118 Q68 150 50 168 Z" fill="#141218"/>'
            '<path d="M66 108 Q100 102 134 108 L134 152 Q100 164 66 152 Z" fill="#141218"/>'
            '<path d="M66 88 Q100 78 134 88 L134 96 Q100 86 66 96 Z" fill="#141218"/>')


def assassin_eyes():
    return ('<ellipse cx="88" cy="103" rx="11" ry="7" fill="#FF2B2B" opacity=".25"/><ellipse cx="112" cy="103" rx="11" ry="7" fill="#FF2B2B" opacity=".25"/>'
            '<ellipse cx="88" cy="103" rx="6" ry="3.2" fill="#FF2B2B"/><ellipse cx="112" cy="103" rx="6" ry="3.2" fill="#FF2B2B"/>')


def assassin_dagger():
    return ('<g transform="translate(150 170) rotate(-35)"><path d="M0 -40 Q8 -20 4 0 L-4 0 Q-8 -20 0 -40 Z" fill="#D7DCE3"/>'
            '<path d="M0 -38 Q3 -20 1.5 -2" stroke="#fff" stroke-width="1.4" fill="none" opacity=".8"/>'
            '<rect x="-10" y="0" width="20" height="5" rx="2" fill="#C9A227"/><rect x="-3.5" y="5" width="7" height="18" rx="2" fill="#5A3A22"/></g>')


def sultana_veil():
    veil = '#2A0F3D'
    return (f'<path d="M71 112 Q100 108 129 112 L126 152 Q100 164 74 152 Z" fill="{veil}"/>'
            '<path d="M71 112 Q100 108 129 112" stroke="#F2C14E" stroke-width="3" fill="none"/>'
            + ''.join(f'<circle cx="{78 + i * 7}" cy="{114 + (abs(i - 3.5) < 2) * 1}" r="1.8" fill="#F2C14E"/>' for i in range(8)))


def sultana_head():
    veil = '#2A0F3D'
    return (hijab(veil, '#F2C14E') + face('tan', ears=False, brows='sly') + hijab_front(veil) +
            '<path d="M100 74 L100 86" stroke="#F2C14E" stroke-width="2"/><circle cx="100" cy="88" r="3" fill="#E03131" stroke="#F2C14E"/>')


# الذئب: الأذنين لحالهم (يحركهم)، والراس، والعيون المسكّرة، والفم وهو يعوي
WOLF_HEAD = ('<path d="M56 80 Q56 52 100 50 Q144 52 144 80 Q152 118 124 140 L100 156 L76 140 Q48 118 56 80 Z" fill="#94A3B8"/>'
             '<path d="M78 110 Q100 96 122 110 Q118 140 100 152 Q82 140 78 110 Z" fill="#E2E8F0"/>'
             '<path d="M70 92 L90 98 L84 106 Z M130 92 L110 98 L116 106 Z" fill="#FDE047" stroke="#111" stroke-width="2"/>'
             '<circle cx="86" cy="100" r="2.5" fill="#111"/><circle cx="114" cy="100" r="2.5" fill="#111"/>'
             '<path d="M92 120 Q100 114 108 120 L100 130 Z" fill="#111"/><path d="M100 130 V138 M92 140 Q100 146 108 140" stroke="#111" stroke-width="2.5" fill="none"/>')
WOLF_EAR_L = '<path d="M52 30 L78 66 L58 80 Z" fill="#64748B"/><path d="M58 42 L74 64 L62 72 Z" fill="#F9A8D4"/>'
WOLF_EAR_R = '<path d="M148 30 L122 66 L142 80 Z" fill="#64748B"/><path d="M142 42 L126 64 L138 72 Z" fill="#F9A8D4"/>'
WOLF_LIDS = ('<path d="M68 91 L92 97.5 L85 107.5 Z M132 91 L108 97.5 L115 107.5 Z" fill="#94A3B8"/>'
             '<path d="M71 96 Q80 103 86 104 M129 96 Q120 103 114 104" stroke="#111" stroke-width="2" fill="none" stroke-linecap="round"/>')
WOLF_HOWL = ('<path d="M100 130 V134" stroke="#111" stroke-width="2.5"/>'
             '<ellipse cx="100" cy="142" rx="9" ry="8" fill="#3B0A12" stroke="#111" stroke-width="2.5"/>'
             '<path d="M94 137 L96 141 L98 137 M102 137 L104 141 L106 137" fill="#fff"/>')

# الصقر (التميمة): الراس وحده يلف، والجفون، والمنقار وهو يصرخ
FALCON_BODY = '<path d="M30 200 Q40 152 100 146 Q160 152 170 200 Z" fill="#8B5E34"/>' + below('#8B5E34', 30, 170, 198)
FALCON_LIDS = ('<circle cx="80" cy="84" r="9.4" fill="#A47148"/><circle cx="120" cy="84" r="9.4" fill="#A47148"/>'
               '<path d="M71.5 85 Q80 90 88.5 85 M111.5 85 Q120 90 128.5 85" stroke="#111" stroke-width="2.4" fill="none" stroke-linecap="round"/>')
FALCON_BEAK = '<path d="M94 118 Q100 134 106 118 Q100 122 94 118 Z" fill="#3B0A12" stroke="#92400E" stroke-width="2"/>'


def falcon_head_mascot():
    full = mascot_falcon()
    return full[full.index('<path d="M50 120'):]


def chain_only():
    return gold_chain()


def human(body, head, skin, lashes=False, beard=False, extra=None):
    """الطبقات العامة: الجسم، والراس، والرمشة، والفم المفتوح. [extra] طبقات خاصة بالشخصية."""
    layers = {'body': (body, False), 'head': (head, False), 'blink': (lids(skin, lashes), False),
              'mouth': (mouth_open(beard), False)}
    layers.update({k: (v, False) for k, v in (extra or {}).items()})
    return layers


RIGS = {
    'lady_gold': human(abaya('#2A1220') + below('#2A1220', 28, 172),
                       hijab('#F8F0E3', '#F2C14E') + face('light', ears=False) + hijab_front('#F8F0E3') + tiara(),
                       'light', lashes=True, extra={'wink': lids('light', True, xs=(88,)), 'necklace': necklace()}),
    'pilot': human(jacket() + below('#5A3520', 28, 172), face('tan', beard='mustache') + cap_only(), 'tan',
                   extra={'goggles': goggles()}),
    'seer': human(robe() + below('#4C1D95', 26, 174), face('deep', beard='full', brows='sly') + turban(), 'deep', beard=True,
                  extra={'ball': crystal_ball(), 'ball_glow': crystal_ball_glow(), 'eyes': eyes_glow('#E879F9')}),
    'knight': human(armor() + chainmail() + below('#9CA3AF', 26, 174), face('tan', beard='full', brows='sly') + helmet(), 'tan', beard=True,
                    extra={'plume': helmet_plume('#DC2626')}),
    'ghost': {'cloak': (ghost_cloak(), False), 'eyes': (ghost_eyes(), False), 'mouth': (ghost_mouth(), False)},
    'assassin': {'body': (thobe('#141218', '#24212B') + below('#141218', 30, 170), False), 'head': (assassin_head(), False),
                 'eyes': (assassin_eyes(), False), 'dagger': (assassin_dagger(), False)},
    'wolf': {'body': ('<path d="M30 200 Q40 150 100 146 Q160 150 170 200 Z" fill="#475569"/>' + below('#475569', 30, 170), False),
             'ear_l': (WOLF_EAR_L, False), 'ear_r': (WOLF_EAR_R, False), 'head': (WOLF_HEAD, False), 'blink': (WOLF_LIDS, False), 'howl': (WOLF_HOWL, False)},
    'falcon_bird': {'body': (FALCON_BODY, False), 'head': (falcon_head_mascot(), False), 'blink': (FALCON_LIDS, False),
                    'beak': (FALCON_BEAK, False)},
    'tycoon': human(bisht('#FCD34D', '#2B1A10') + below('#2B1A10', 26, 174), face('tan', beard='goatee', glasses='sun') + ghutra(), 'tan',
                    extra={'chain': chain_only()}),
    'emir': human(bisht() + below('#15121A', 26, 174), face('light', beard='full', beard_color='grey') + ghutra(), 'light', beard=True),
    'sultana': human(abaya('#1C0B28') + below('#1C0B28', 28, 172), sultana_head(), 'tan', lashes=True,
                     extra={'veil': sultana_veil()}),
    'queen': human(abaya('#3B0764') + below('#3B0764', 28, 172),
                   hijab('#6D28D9', '#FCD34D') + face('light', ears=False) + hijab_front('#6D28D9') + big_crown(y=52), 'light', lashes=True,
                   extra={'necklace': necklace()}),
    'astronaut': human(space_suit() + below('#F1F3F5', 24, 176), space_helmet() + face('tan'), 'tan',
                       extra={'visor': space_visor_front()}),
    'lv20': human(robe('#E2E8F0', '#94A3B8') + below('#E2E8F0', 26, 174), face('light', beard='full', beard_color='grey') + turban('#FFFFFF', '#60A5FA'),
                  'light', beard=True, extra={'book': book()}),
    'lv30': human(bisht('#FCD34D', '#7A4E00') + below('#7A4E00', 26, 174), face('light', beard='full') + gold_ghutra(), 'light', beard=True,
                  extra={'chain': chain_only()}),
    'lv40': human(armor('#7F1D1D', '#FB7185') + below('#7F1D1D', 26, 174),
                  face('deep', beard='full', brows='sly') + helmet('#B91C1C') + '<circle cx="100" cy="62" r="7" fill="#F43F5E" stroke="#4C0519" stroke-width="2"/>',
                  'deep', beard=True, extra={'plume': helmet_plume('#FDA4AF')}),
    'lv50': human(bisht('#F472B6', '#312E81') + below('#312E81', 26, 174),
                  face('tan', beard='goatee', brows='sly') + colored_ghutra('#FFFFFF') + big_crown('#FDE68A', 44), 'tan',
                  extra={'glow': glow_eyes('#F9A8D4')}),
    's1a': human(thobe('#0F2E2C', '#134E4A') + below('#0F2E2C', 30, 170),
                 face('tan', brows='sly') + colored_ghutra('#134E4A') + face_mask() + crescent_badge(100, 66), 'tan'),
    's1b': human(abaya('#1E1B4B') + below('#1E1B4B', 28, 172),
                 hijab('#4338CA', '#FDE68A') + face('light', ears=False) + hijab_front('#4338CA') + crescent_badge(100, 66), 'light', lashes=True,
                 extra={'necklace': necklace()}),
    's1c': human(bisht('#FCD34D', '#0F766E') + below('#0F766E', 26, 174),
                 face('light', beard='full') + turban('#0F766E', '#FCD34D') + crescent_badge(100, 52, '#FDE68A'), 'light', beard=True),
    'champ1': human(thobe() + below('#F4F1EA', 30, 170), face('tan', beard='goatee') + ghutra() + laurel('#FCD34D'), 'tan',
                    extra={'medal': medal_on('#FCD34D', '١')}),
    'champ2': human(thobe() + below('#F4F1EA', 30, 170), face('light', beard='stubble') + ghutra('red') + laurel('#E2E8F0'), 'light',
                    extra={'medal': medal_on('#CBD5E1', '٢')}),
    'champ3': human(thobe() + below('#F4F1EA', 30, 170), face('brown', beard='mustache') + ghutra() + laurel('#E0A060'), 'brown',
                    extra={'medal': medal_on('#D08B4E', '٣')}),
}
ANIMS.update(RIGS)


def render(svg, path, size=600):
    open(path + '.svg', 'w').write(svg)
    png = subprocess.run(['inkscape', path + '.svg', '--export-type=png', '--export-filename=-', '-w', str(size), '-h', str(size)],
                         check=True, capture_output=True).stdout
    return Image.open(io.BytesIO(png)).convert('RGBA')


if __name__ == '__main__':
    os.makedirs(SRC, exist_ok=True)
    only = set(sys.argv[2].split(',')) if len(sys.argv) > 2 else None
    for name, layers in ANIMS.items():
        if only and name not in only:
            continue
        out = os.path.join(OUT, 'anim', name)
        os.makedirs(out, exist_ok=True)

        def one(item, name=name, out=out):
            layer, (body, clip) = item
            render(canvas(body, clip), os.path.join(SRC, f'{name}_{layer}')).save(os.path.join(out, f'{layer}.webp'), quality=90, method=6)

        with ThreadPoolExecutor(4) as ex:
            list(ex.map(one, layers.items()))
        # الشكل الثابت (القوائم وغيرها): نفس الطبقات بدون الرمشة، مقصوص على الدائرة بحجم ٥١٢.
        # الباقين صورتهم الثابتة من characters.py (نفس الرسمة).
        if name not in STILL:
            print(name, len(layers), 'layers')
            continue
        body = ''.join(layers[l][0] for l in STILL[name])
        svg = (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 200" width="512" height="512">'
               f'{DEFS}<g clip-path="url(#c)">{body}</g></svg>')
        render(svg, os.path.join(SRC, f'{name}_still'), 512).save(os.path.join(OUT, f'{name}.webp'), quality=92, method=6)
        print(name, len(layers), 'layers')
