"""
كل شخصيات اللعبة بدقة عالية (512) كـ WebP في app/assets/avatars.
المجانية بخلفيتها الدائرية، والمميزة بدون خلفية (التطبيق يرسم ورها خلفية متحركة تضوي).
تشغيل:  python3 tools/art/characters.py app/assets/avatars [ids,...]
"""
import io, os, subprocess, sys
from concurrent.futures import ThreadPoolExecutor

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = sys.argv[1] if len(sys.argv) > 1 else 'app/assets/avatars'
ONLY = set(sys.argv[2].split(',')) if len(sys.argv) > 2 else None
SRC = os.path.join(HERE, 'build', 'avatars')

src = open(os.path.join(HERE, 'avatars.py')).read()
exec(src[src.index('SKIN ='):src.index('CHARACTERS =')])  # face, thobe, abaya, ghutra, hijab, hijab_front, wrap
FREE = dict(eval(src[src.index('CHARACTERS = {') + len('CHARACTERS = '):src.index("\n}\n", src.index('CHARACTERS = {')) + 2]))
psrc = open(os.path.join(HERE, 'premium.py')).read()
exec(psrc[psrc.index('def bisht'):psrc.index('PREMIUM = {')])  # bisht, falcon_bird, tiara, necklace, magnifier, assassin, sultana

INK = '#1E1720'


# ───────────── أجزاء جديدة ─────────────
def coat(color='#F8F9FA'):
    return (f'<path d="M28 200 Q32 156 70 146 Q100 158 130 146 Q168 156 172 200 Z" fill="{color}"/>'
            '<path d="M84 150 L100 200 L116 150" fill="#DCE3EA"/><path d="M70 146 L88 200 M130 146 L112 200" stroke="#C7D0DA" stroke-width="3"/>')


def stethoscope():
    return ('<path d="M76 150 Q70 182 96 186 Q120 186 124 168" fill="none" stroke="#2B2F36" stroke-width="5"/>'
            '<circle cx="124" cy="166" r="7" fill="#ADB5BD" stroke="#2B2F36" stroke-width="3"/>')


def earpiece():
    return '<path d="M64 108 Q56 130 66 150" fill="none" stroke="#111" stroke-width="2.5"/><circle cx="66" cy="106" r="4" fill="#222"/>'


def skullcap(color='#FFFFFF'):
    return f'<path d="M66 92 Q66 62 100 60 Q134 62 134 92 Q118 82 100 82 Q82 82 66 92 Z" fill="{color}" stroke="#D9D9D9" stroke-width="2"/>'


def nose_clip():
    return '<path d="M94 106 Q100 100 106 106" fill="none" stroke="#2B2F36" stroke-width="4"/><rect x="92" y="104" width="16" height="5" rx="2" fill="#6C757D"/>'


def pearl_hand():
    return ('<g transform="translate(146 160)"><ellipse rx="16" ry="10" fill="#D9A274" stroke="#B07A4F" stroke-width="2"/>'
            '<circle cy="-8" r="9" fill="#FFFDF5" stroke="#D6CFC2" stroke-width="2"/><circle cx="-3" cy="-11" r="3" fill="#fff"/></g>')


def quill():
    return ('<g transform="translate(146 150) rotate(25)"><path d="M0 40 Q-14 0 0 -40 Q14 0 0 40 Z" fill="#FFFFFF" stroke="#ADB5BD" stroke-width="2"/>'
            '<path d="M0 -36 V44" stroke="#868E96" stroke-width="2"/></g>')


def pilot_cap():
    return ('<path d="M62 96 Q60 56 100 54 Q140 56 138 96 Q140 120 132 128 L126 104 Q118 80 100 80 Q82 80 74 104 L68 128 Q60 120 62 96 Z" fill="#7A4A2A"/>'
            '<path d="M70 78 Q100 66 130 78 L130 88 Q100 76 70 88 Z" fill="#5A3520"/>'
            '<circle cx="84" cy="74" r="11" fill="#9BD3FF" stroke="#C9A227" stroke-width="4"/><circle cx="116" cy="74" r="11" fill="#9BD3FF" stroke="#C9A227" stroke-width="4"/>'
            '<path d="M95 74 H105" stroke="#C9A227" stroke-width="4"/>')


def jacket(color='#5A3520'):
    return (f'<path d="M28 200 Q32 154 72 146 Q100 158 128 146 Q168 154 172 200 Z" fill="{color}"/>'
            '<path d="M72 146 Q86 160 100 160 Q114 160 128 146 L134 160 Q100 176 66 160 Z" fill="#F1E3C6"/>')


def turban(color='#6D28D9', gem='#FCD34D'):
    return (f'<path d="M60 92 Q56 52 100 48 Q144 52 140 92 Q124 76 100 76 Q76 76 60 92 Z" fill="{color}"/>'
            f'<path d="M62 84 Q100 58 138 84 M64 74 Q100 50 136 74" fill="none" stroke="#000" stroke-opacity=".18" stroke-width="4"/>'
            f'<path d="M100 54 L108 66 L100 78 L92 66 Z" fill="{gem}" stroke="#7A4E00" stroke-width="2"/>'
            '<path d="M100 48 Q112 30 118 40 Q108 40 104 50 Z" fill="#fff" opacity=".85"/>')


def crystal_ball():
    return ('<circle cx="100" cy="176" r="30" fill="#C084FC" opacity=".35"/>'
            '<circle cx="100" cy="172" r="20" fill="#A855F7" stroke="#F3E8FF" stroke-width="3"/>'
            '<path d="M90 164 Q96 156 106 158" fill="none" stroke="#fff" stroke-width="4" stroke-linecap="round"/>'
            '<path d="M80 192 H120 L114 200 H86 Z" fill="#C9A227"/>')


def robe(color='#4C1D95', trim='#FCD34D'):
    return (f'<path d="M26 200 Q30 156 68 146 Q100 160 132 146 Q170 156 174 200 Z" fill="{color}"/>'
            f'<path d="M68 146 Q100 166 132 146" fill="none" stroke="{trim}" stroke-width="4"/>')


def helmet(color='#9CA3AF', plume=None):
    p = f'<path d="M100 40 Q122 20 132 34 Q116 34 106 48 Z" fill="{plume}"/>' if plume else ''
    return (p + f'<path d="M64 104 Q60 52 100 46 Q140 52 136 104 L132 112 Q120 80 100 80 Q80 80 68 112 Z" fill="{color}" stroke="#4B5563" stroke-width="2.5"/>'
            '<path d="M100 46 V80" stroke="#6B7280" stroke-width="3"/><path d="M96 80 H104 V116 Q100 120 96 116 Z" fill="#6B7280"/>'
            '<path d="M68 96 Q100 84 132 96" fill="none" stroke="#6B7280" stroke-width="3"/>')


def chainmail():
    return ('<path d="M60 112 Q58 150 70 160 Q100 172 130 160 Q142 150 140 112 Q136 140 120 144 Q100 150 80 144 Q64 140 60 112 Z" fill="#9CA3AF"/>'
            + ''.join(f'<circle cx="{x}" cy="{y}" r="2.2" fill="none" stroke="#6B7280" stroke-width="1.2"/>' for x in range(66, 136, 7) for y in range(122, 160, 7) if (x - 100) ** 2 / 1600 + (y - 140) ** 2 / 600 < 1.3))


def armor(color='#9CA3AF', accent='#DC2626'):
    return (f'<path d="M26 200 Q30 156 70 146 Q100 156 130 146 Q170 156 174 200 Z" fill="{color}"/>'
            f'<path d="M30 168 Q50 150 70 148 L74 170 Q52 172 30 186 Z M170 168 Q150 150 130 148 L126 170 Q148 172 170 186 Z" fill="#6B7280"/>'
            f'<path d="M86 160 H114 V200 H86 Z" fill="{accent}"/>')


def hood(color='#1B1030'):
    return (f'<path d="M44 120 Q40 40 100 32 Q160 40 156 120 L168 200 H32 Z" fill="{color}"/>'
            '<path d="M64 112 Q64 64 100 60 Q136 64 136 112 Q136 150 100 156 Q64 150 64 112 Z" fill="#05010D"/>'
            '<ellipse cx="86" cy="106" rx="9" ry="5" fill="#C084FC"/><ellipse cx="114" cy="106" rx="9" ry="5" fill="#C084FC"/>'
            '<ellipse cx="86" cy="106" rx="16" ry="10" fill="#A855F7" opacity=".3"/><ellipse cx="114" cy="106" rx="16" ry="10" fill="#A855F7" opacity=".3"/>')


def gold_chain():
    return ('<path d="M74 150 Q100 178 126 150" fill="none" stroke="#FCD34D" stroke-width="6" stroke-dasharray="7 3"/>'
            '<circle cx="100" cy="172" r="9" fill="#FCD34D" stroke="#B45309" stroke-width="2.5"/>')


def big_crown(color='#FCD34D', y=46):
    return (f'<g transform="translate(100 {y})"><path d="M-36 18 L-40 -18 L-20 0 L0 -30 L20 0 L40 -18 L36 18 Z" fill="{color}" stroke="#7A4E00" stroke-width="3"/>'
            '<circle cx="0" cy="8" r="6" fill="#E11D48"/><circle cx="-22" cy="10" r="4.5" fill="#3B82F6"/><circle cx="22" cy="10" r="4.5" fill="#3B82F6"/>'
            '<circle cx="-40" cy="-20" r="4" fill="#FFF"/><circle cx="0" cy="-32" r="4.5" fill="#FFF"/><circle cx="40" cy="-20" r="4" fill="#FFF"/></g>')


def space_helmet():
    return ('<circle cx="100" cy="104" r="62" fill="#DEE2E6" stroke="#868E96" stroke-width="4"/>'
            '<circle cx="100" cy="104" r="50" fill="#0B1026" opacity=".18"/>')


def space_visor_front():
    return ('<circle cx="100" cy="104" r="50" fill="#5DADE2" opacity=".22"/>'
            '<path d="M60 84 Q72 60 100 56" fill="none" stroke="#fff" stroke-width="6" stroke-linecap="round" opacity=".7"/>'
            '<circle cx="134" cy="86" r="3" fill="#fff" opacity=".9"/><circle cx="126" cy="74" r="2" fill="#fff" opacity=".8"/>')


def space_suit():
    return ('<path d="M24 200 Q28 156 70 150 Q100 162 130 150 Q172 156 176 200 Z" fill="#F1F3F5"/>'
            '<rect x="84" y="166" width="32" height="22" rx="4" fill="#ADB5BD"/><circle cx="92" cy="177" r="3" fill="#E03131"/><circle cx="104" cy="177" r="3" fill="#40C057"/>')


def mascot_camel():
    return ('<path d="M30 200 Q40 150 100 146 Q160 150 170 200 Z" fill="#C68642"/>'
            '<ellipse cx="62" cy="64" rx="10" ry="18" fill="#B87333" transform="rotate(-25 62 64)"/><ellipse cx="138" cy="64" rx="10" ry="18" fill="#B87333" transform="rotate(25 138 64)"/>'
            '<ellipse cx="100" cy="92" rx="40" ry="44" fill="#D9A066"/>'
            '<ellipse cx="100" cy="132" rx="30" ry="22" fill="#E8C097"/>'
            '<ellipse cx="90" cy="130" rx="4" ry="6" fill="#5A3A22"/><ellipse cx="110" cy="130" rx="4" ry="6" fill="#5A3A22"/>'
            '<path d="M88 146 Q100 152 112 146" fill="none" stroke="#5A3A22" stroke-width="3" stroke-linecap="round"/>'
            '<ellipse cx="82" cy="88" rx="7" ry="9" fill="#2B1B10"/><ellipse cx="118" cy="88" rx="7" ry="9" fill="#2B1B10"/>'
            '<circle cx="84" cy="85" r="2.5" fill="#fff"/><circle cx="120" cy="85" r="2.5" fill="#fff"/>'
            '<path d="M72 78 Q82 72 92 78 M108 78 Q118 72 128 78" stroke="#2B1B10" stroke-width="3" fill="none" stroke-linecap="round"/>'
            '<path d="M74 54 Q100 40 126 54 L126 62 Q100 48 74 62 Z" fill="#E11D48"/><path d="M74 62 Q100 50 126 62" stroke="#FCD34D" stroke-width="3" fill="none"/>')


def mascot_wolf():
    return ('<path d="M30 200 Q40 150 100 146 Q160 150 170 200 Z" fill="#475569"/>'
            '<path d="M52 30 L78 66 L58 80 Z M148 30 L122 66 L142 80 Z" fill="#64748B"/><path d="M58 42 L74 64 L62 72 Z M142 42 L126 64 L138 72 Z" fill="#F9A8D4"/>'
            '<path d="M56 80 Q56 52 100 50 Q144 52 144 80 Q152 118 124 140 L100 156 L76 140 Q48 118 56 80 Z" fill="#94A3B8"/>'
            '<path d="M78 110 Q100 96 122 110 Q118 140 100 152 Q82 140 78 110 Z" fill="#E2E8F0"/>'
            '<path d="M70 92 L90 98 L84 106 Z M130 92 L110 98 L116 106 Z" fill="#FDE047" stroke="#111" stroke-width="2"/>'
            '<circle cx="86" cy="100" r="2.5" fill="#111"/><circle cx="114" cy="100" r="2.5" fill="#111"/>'
            '<path d="M92 120 Q100 114 108 120 L100 130 Z" fill="#111"/><path d="M100 130 V138 M92 140 Q100 146 108 140" stroke="#111" stroke-width="2.5" fill="none"/>')


def mascot_falcon():
    return ('<path d="M30 200 Q40 152 100 146 Q160 152 170 200 Z" fill="#8B5E34"/>'
            '<path d="M50 120 Q44 60 100 48 Q156 60 150 120 Q146 156 100 162 Q54 156 50 120 Z" fill="#A47148"/>'
            '<path d="M64 120 Q66 92 100 88 Q134 92 136 120 Q132 152 100 156 Q68 152 64 120 Z" fill="#F5E6CC"/>'
            '<path d="M60 84 Q80 70 96 84 Q80 96 60 84 Z M140 84 Q120 70 104 84 Q120 96 140 84 Z" fill="#3B2410"/>'
            '<circle cx="80" cy="84" r="8" fill="#FBBF24" stroke="#111" stroke-width="2.5"/><circle cx="120" cy="84" r="8" fill="#FBBF24" stroke="#111" stroke-width="2.5"/>'
            '<circle cx="80" cy="84" r="4" fill="#111"/><circle cx="120" cy="84" r="4" fill="#111"/>'
            '<path d="M88 96 Q100 90 112 96 L106 120 Q100 128 94 120 Z" fill="#FCD34D" stroke="#92400E" stroke-width="2.5"/>'
            '<path d="M94 120 Q100 112 106 120" fill="none" stroke="#92400E" stroke-width="2"/>'
            + ''.join(f'<path d="M{x} {y} q4 4 8 0" stroke="#6B4423" stroke-width="2" fill="none"/>' for x in (76, 92, 108) for y in (134, 144)))


def laurel(color='#FCD34D'):
    leaves = ''.join(f'<ellipse cx="{100 + s * (44 - i * 2)}" cy="{96 - i * 11}" rx="9" ry="4.5" fill="{color}" stroke="#7A4E00" stroke-width="1.5" transform="rotate({s * (60 - i * 14)} {100 + s * (44 - i * 2)} {96 - i * 11})"/>'
                     for s in (-1, 1) for i in range(5))
    return leaves


def medal_on(color='#FCD34D', n='١'):
    return (f'<path d="M86 150 L94 172 M114 150 L106 172" stroke="#E03131" stroke-width="7"/>'
            f'<circle cx="100" cy="180" r="14" fill="{color}" stroke="#4A3A10" stroke-width="3"/>'
            f'<text x="100" y="187" font-family="Marhey" font-weight="bold" font-size="18" text-anchor="middle" fill="#fff" stroke="#4A3A10" stroke-width="3" paint-order="stroke">{n}</text>')


def crescent_badge(x=100, y=60, color='#FCD34D'):
    return f'<path d="M{x + 6} {y - 12} Q{x - 10} {y - 10} {x - 10} {y + 2} Q{x - 8} {y + 14} {x + 6} {y + 14} Q{x - 2} {y + 8} {x - 2} {y + 1} Q{x - 2} {y - 6} {x + 6} {y - 12} Z" fill="{color}" stroke="#7A4E00" stroke-width="1.5"/>'


def shield_chest(color='#B45309'):
    return (f'<path d="M100 150 L126 158 V176 Q126 192 100 200 Q74 192 74 176 V158 Z" fill="{color}" stroke="#431407" stroke-width="3"/>'
            '<path d="M100 160 L104 170 L114 170 L106 176 L109 186 L100 180 L91 186 L94 176 L86 170 L96 170 Z" fill="#FDE68A"/>')


def book():
    return ('<g transform="translate(146 170) rotate(-12)"><rect x="-24" y="-16" width="48" height="32" rx="3" fill="#7C2D12" stroke="#2B0F05" stroke-width="2.5"/>'
            '<path d="M0 -16 V16" stroke="#FCD34D" stroke-width="2"/><path d="M-18 -8 H-6 M-18 0 H-6 M6 -8 H18 M6 0 H18" stroke="#FCD34D" stroke-width="2"/></g>')


def glow_eyes(color='#FDE047'):
    return f'<ellipse cx="88" cy="103" rx="8" ry="5" fill="{color}" opacity=".85"/><ellipse cx="112" cy="103" rx="8" ry="5" fill="{color}" opacity=".85"/>'


def gold_ghutra():
    """غترة ذهبية (للشيخ الذهبي)."""
    return ('<path d="M58 106 Q54 62 100 56 Q146 62 142 106 L150 168 Q132 150 126 118 Q122 84 100 82 Q78 84 74 118 Q68 150 50 168 Z" fill="#FCD34D"/>'
            '<path d="M66 100 Q64 74 100 70 Q136 74 134 100" fill="none" stroke="#B45309" stroke-width="3" opacity=".6"/>'
            '<path d="M62 76 Q100 58 138 76 L138 84 Q100 66 62 84 Z" fill="#7A4E00"/><path d="M62 88 Q100 70 138 88 L138 95 Q100 78 62 95 Z" fill="#7A4E00"/>')


def colored_ghutra(color, agal='#18151B'):
    return (f'<path d="M58 106 Q54 62 100 56 Q146 62 142 106 L150 168 Q132 150 126 118 Q122 84 100 82 Q78 84 74 118 Q68 150 50 168 Z" fill="{color}"/>'
            f'<path d="M62 76 Q100 58 138 76 L138 84 Q100 66 62 84 Z" fill="{agal}"/><path d="M62 88 Q100 70 138 88 L138 95 Q100 78 62 95 Z" fill="{agal}"/>')


def face_mask(color='#134E4A'):
    return f'<path d="M66 108 Q100 102 134 108 L134 150 Q100 162 66 150 Z" fill="{color}"/><path d="M66 108 Q100 102 134 108" stroke="#FCD34D" stroke-width="2.5" fill="none"/>'


# ───────────── الشخصيات المميزة ─────────────
PREMIUM = {
    'detective': thobe('#3C3A45', '#55525F') + face('brown', beard='goatee', brows='sly') + ghutra() + magnifier(),
    'falconer': thobe('#E8DCC4') + face('tan', beard='full') + ghutra('red') + falcon_bird(),
    'lady_gold': abaya('#2A1220') + hijab('#F8F0E3', '#F2C14E') + face('light', ears=False) + hijab_front('#F8F0E3') + tiara() + necklace(),
    'assassin': assassin(),
    'emir': bisht() + face('light', beard='full', beard_color='grey') + ghutra(),
    'sultana': sultana(),
    'spy': abaya('#111014') + hijab('#141218') + face('tan', glasses='sun', brows='sly', ears=False) + hijab_front('#141218') + earpiece(),
    'doctor': coat() + stethoscope() + hijab('#FFFFFF', '#5EEAD4') + face('light', ears=False) + hijab_front('#F1F5F9'),
    'diver': thobe('#F4F1EA') + face('brown', beard='stubble') + skullcap() + nose_clip() + pearl_hand(),
    'poet': thobe('#D8C9AE', '#BFAF92') + face('light', beard='full', beard_color='grey', glasses='round') + ghutra('red') + quill(),
    'camel': mascot_camel(),
    'pilot': jacket() + face('tan', beard='mustache') + pilot_cap(),
    'seer': robe() + face('deep', beard='full', brows='sly') + turban() + crystal_ball(),
    'knight': armor() + chainmail() + face('tan', beard='full', brows='sly') + helmet(plume='#DC2626'),
    'ghost': hood(),
    'wolf': mascot_wolf(),
    'falcon_bird': mascot_falcon(),
    'tycoon': bisht('#FCD34D', '#2B1A10') + gold_chain() + face('tan', beard='goatee', glasses='sun') + ghutra(),
    'queen': abaya('#3B0764') + hijab('#6D28D9', '#FCD34D') + face('light', ears=False) + hijab_front('#6D28D9') + big_crown(y=52) + necklace(),
    'astronaut': space_suit() + space_helmet() + face('tan') + space_visor_front(),
    'lv10': thobe('#7C4A1E', '#5A3315') + shield_chest() + face('tan', beard='goatee', brows='sly') + ghutra('red'),
    'lv20': robe('#E2E8F0', '#94A3B8') + face('light', beard='full', beard_color='grey') + turban('#FFFFFF', '#60A5FA') + book(),
    'lv30': bisht('#FCD34D', '#7A4E00') + gold_chain() + face('light', beard='full') + gold_ghutra(),
    'lv40': armor('#7F1D1D', '#FB7185') + face('deep', beard='full', brows='sly') + helmet('#B91C1C', plume='#FDA4AF') + '<circle cx="100" cy="62" r="7" fill="#F43F5E" stroke="#4C0519" stroke-width="2"/>',
    'lv50': bisht('#F472B6', '#312E81') + face('tan', beard='goatee', brows='sly') + colored_ghutra('#FFFFFF') + glow_eyes('#F9A8D4') + big_crown('#FDE68A', 44),
    's1a': thobe('#0F2E2C', '#134E4A') + face('tan', brows='sly') + colored_ghutra('#134E4A') + face_mask() + crescent_badge(100, 66),
    's1b': abaya('#1E1B4B') + hijab('#4338CA', '#FDE68A') + face('light', ears=False) + hijab_front('#4338CA') + crescent_badge(100, 66) + necklace(),
    's1c': bisht('#FCD34D', '#0F766E') + face('light', beard='full') + turban('#0F766E', '#FCD34D') + crescent_badge(100, 52, '#FDE68A'),
    'champ1': thobe() + face('tan', beard='goatee') + ghutra() + laurel('#FCD34D') + medal_on('#FCD34D', '١'),
    'champ2': thobe() + face('light', beard='stubble') + ghutra('red') + laurel('#E2E8F0') + medal_on('#CBD5E1', '٢'),
    'champ3': thobe() + face('brown', beard='mustache') + ghutra() + laurel('#E0A060') + medal_on('#D08B4E', '٣'),
}


def wrap_clear(body):
    """شخصية بدون خلفية، مقصوصة على الدائرة (التطبيق يحط ورها الخلفية المتحركة)."""
    return f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 200" width="512" height="512">
<defs>
  <pattern id="shemagh" width="10" height="10" patternUnits="userSpaceOnUse" patternTransform="rotate(45)">
    <rect width="10" height="10" fill="#FBF7F2"/><rect width="5" height="5" fill="#C8262E"/><rect x="5" y="5" width="5" height="5" fill="#C8262E"/>
  </pattern>
  <clipPath id="c"><circle cx="100" cy="100" r="100"/></clipPath>
</defs>
<g clip-path="url(#c)">{body}</g>
</svg>'''


def render(item):
    name, svg = item
    path = os.path.join(SRC, f'{name}.svg')
    open(path, 'w').write(svg)
    png = subprocess.run(['inkscape', path, '--export-type=png', '--export-filename=-', '-w', '512', '-h', '512'],
                         check=True, capture_output=True).stdout
    Image.open(io.BytesIO(png)).convert('RGBA').save(os.path.join(OUT, f'{name}.webp'), quality=92, method=6)
    return name


if __name__ == '__main__':
    os.makedirs(SRC, exist_ok=True)
    os.makedirs(OUT, exist_ok=True)
    items = [(n, wrap(b1, b2, body)) for n, (b1, b2, body) in FREE.items()]
    items += [(n, wrap_clear(body)) for n, body in PREMIUM.items()]
    items = [i for i in items if not ONLY or i[0] in ONLY]
    with ThreadPoolExecutor(6) as ex:
        done = list(ex.map(render, items))
    print(len(done), 'avatars')
