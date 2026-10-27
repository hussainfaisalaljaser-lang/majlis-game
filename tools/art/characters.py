"""
كل شخصيات اللعبة بدقة عالية (512) كـ WebP في app/assets/avatars.
المجانية بخلفيتها الدائرية، والمميزة بدون خلفية (التطبيق يرسم ورها خلفية متحركة تضوي).
تشغيل:  python3 tools/art/characters.py app/assets/avatars [ids,...]
"""
import io, math, os, subprocess, sys
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


def book():
    return ('<g transform="translate(146 170) rotate(-12)"><rect x="-24" y="-16" width="48" height="32" rx="3" fill="#7C2D12" stroke="#2B0F05" stroke-width="2.5"/>'
            '<path d="M0 -16 V16" stroke="#FCD34D" stroke-width="2"/><path d="M-18 -8 H-6 M-18 0 H-6 M6 -8 H18 M6 0 H18" stroke="#FCD34D" stroke-width="2"/></g>')


# ───────────── حيوانات الجوائز ─────────────
# اللي ينعطى (هدايا المستويات، والباتل باس، وأبطال الأسبوع) لازم يناسب الكل، ذكور وإناث: كلها حيوانات.
DARK = '#2E2219'


def _qpt(p0, p1, p2, t):
    return ((1 - t) ** 2 * p0[0] + 2 * (1 - t) * t * p1[0] + t * t * p2[0],
            (1 - t) ** 2 * p0[1] + 2 * (1 - t) * t * p1[1] + t * t * p2[1])


def laurel_low(color='#FCD34D', edge='#7A4E00'):
    """غصنين غار يلفون تحت الصورة من الجهتين (شعار البطل)."""
    out = ''
    for s in (-1, 1):
        p0, p1, p2 = (100 + s * 20, 198), (100 + s * 72, 186), (100 + s * 62, 108)
        d = f'M{p0[0]} {p0[1]} Q{p1[0]} {p1[1]} {p2[0]} {p2[1]}'
        out += f'<path d="{d}" fill="none" stroke="{edge}" stroke-width="2.4"/>'
        for i in range(7):
            t = .12 + i * .13
            x, y = _qpt(p0, p1, p2, t)
            x2, y2 = _qpt(p0, p1, p2, t + .01)
            ang = math.degrees(math.atan2(y2 - y, x2 - x))
            for side in (-1, 1):
                a = ang + side * 38
                cx = x + math.cos(math.radians(a)) * 7
                cy = y + math.sin(math.radians(a)) * 7
                out += (f'<ellipse cx="{cx:.1f}" cy="{cy:.1f}" rx="8" ry="3.8" fill="{color}" stroke="{edge}" stroke-width="1.3" '
                        f'transform="rotate({a:.1f} {cx:.1f} {cy:.1f})"/>')
    return out


def medal_ring(color='#FCD34D', n='١', edge='#4A3A10', ribbon='#E03131'):
    return (f'<path d="M86 152 L94 172 M114 152 L106 172" stroke="{ribbon}" stroke-width="7"/>'
            f'<circle cx="100" cy="180" r="14" fill="{color}" stroke="{edge}" stroke-width="3"/>'
            f'<circle cx="100" cy="180" r="9.5" fill="none" stroke="#fff" stroke-width="1.2" opacity=".55"/>'
            f'<text x="100" y="187" font-family="Marhey" font-weight="bold" font-size="18" text-anchor="middle" fill="#fff" stroke="{edge}" stroke-width="3" paint-order="stroke">{n}</text>')


# ───────────── المها العربية (أبطال الأسبوع) ─────────────
def oryx_horns(metal, ring):
    out = ''
    for s in (-1, 1):
        bx, tx = 100 + s * 13, 100 + s * 34
        out += (f'<path d="M{bx - 5} 66 L{tx - 1.6} 4 Q{tx} 1 {tx + 1.6} 4 L{bx + 5} 66 Z" fill="{metal}" stroke="{ring}" stroke-width="1.6" stroke-linejoin="round"/>')
        for i in range(7):
            t = .08 + i * .085
            x = bx + (tx - bx) * t
            y = 66 - 62 * t
            w = 5.4 - 3.2 * t
            out += f'<path d="M{x - w:.1f} {y + 1.4:.1f} Q{x:.1f} {y - 1.6:.1f} {x + w:.1f} {y + 1.4:.1f}" stroke="{ring}" stroke-width="1.5" fill="none"/>'
        out += f'<path d="M{bx + s * -1.5} 60 L{tx + s * -.6} 10" stroke="#fff" stroke-width="1.4" opacity=".55"/>'
    return out


def oryx_ear(s):
    """أذن وحدة ([s] = -١ يسار، ١ يمين)."""
    cx = 100 + s * 40
    return (f'<ellipse cx="{cx}" cy="84" rx="17" ry="8" fill="#F4EFE6" stroke="#CFC4B4" stroke-width="1.2" transform="rotate({s * 22} {cx} 84)"/>'
            f'<ellipse cx="{cx + s * 2}" cy="84" rx="10" ry="3.8" fill="#E7B9AE" transform="rotate({s * 22} {cx + s * 2} 84)"/>')


def oryx_ears():
    return oryx_ear(-1) + oryx_ear(1)


def oryx_head(mark=DARK):
    face = '#F7F3EB'
    return (f'<path d="M100 56 Q129 57 132 82 Q134 106 124 126 Q115 144 100 148 Q85 144 76 126 Q66 106 68 82 Q71 57 100 56 Z" fill="{face}"/>'
            # خط داكن من الجبهة لين الخشم (يضعف بين العيون)، وشريطين من القرون على العيون لين الفك
            f'<path d="M100 59 Q108 62 107 72 Q104 84 103 96 Q104 110 110 120 Q114 130 112 137 Q100 145 88 137 Q86 130 90 120 Q96 110 97 96 Q96 84 93 72 Q92 62 100 59 Z" fill="{mark}"/>'
            f'<path d="M86 66 Q76 72 74 88 Q72 106 78 124 Q81 126 83 122 Q81 108 84 98 Q86 84 92 70 Z" fill="{mark}"/>'
            f'<path d="M114 66 Q124 72 126 88 Q128 106 122 124 Q119 126 117 122 Q119 108 116 98 Q114 84 108 70 Z" fill="{mark}"/>'
            '<ellipse cx="95" cy="132" rx="2.4" ry="3.2" fill="#7A6352"/><ellipse cx="105" cy="132" rx="2.4" ry="3.2" fill="#7A6352"/>'
            '<path d="M92 144 Q96 148 100 145.5 Q104 148 108 144" stroke="#8A7564" stroke-width="2" fill="none" stroke-linecap="round"/>'
            + oryx_eyes())


def oryx_eyes():
    out = ''
    for x in (82, 118):
        out += (f'<ellipse cx="{x}" cy="96" rx="7.5" ry="8.5" fill="#fff"/>'
                f'<circle cx="{x + (1 if x < 100 else -1)}" cy="97" r="5.4" fill="#5A3A1E"/><circle cx="{x + (1 if x < 100 else -1)}" cy="97" r="3.2" fill="#140D08"/>'
                f'<circle cx="{x - 1.4}" cy="94.4" r="1.8" fill="#fff"/>')
    return out


def oryx_lids():
    return toon_lids('#F7F3EB', xs=(82, 118), y=96, line=DARK)


def oryx_mouth():
    """يضحك فرحان."""
    return ('<path d="M91 143 Q100 156 109 143 Q100 146 91 143 Z" fill="#5A1A14" stroke="#8A7564" stroke-width="1.6" stroke-linejoin="round"/>'
            '<path d="M95 148.5 Q100 152 105 148.5 Q100 150 95 148.5 Z" fill="#E77F7F"/>')


def oryx_body(coat='#EDE5D8'):
    return (f'<path d="M36 200 Q44 158 78 150 Q100 158 122 150 Q156 158 164 200 Z" fill="{coat}"/>'
            '<path d="M80 150 Q100 166 120 150 L118 160 Q100 172 82 160 Z" fill="#D9CDBB" opacity=".7"/>')


# لكل مركز: القرون (لون وحلقات)، والغار (لون وحافة)، والميدالية ورقمها.
CHAMPS = {
    'champ1': ('#FCD34D', '#9A6B00', '#FCD34D', '#7A4E00', '#FCD34D', '١'),
    'champ2': ('#E5E9F0', '#7B8794', '#E2E8F0', '#64748B', '#CBD5E1', '٢'),
    'champ3': ('#E9A86A', '#8A4B1C', '#E0A060', '#6B3410', '#D08B4E', '٣'),
}


def oryx(metal, ring, laurel_c, laurel_e, medal_c, n):
    return (laurel_low(laurel_c, laurel_e) + oryx_body() + oryx_horns(metal, ring) + oryx_ears() + oryx_head()
            + medal_ring(medal_c, n))


def toon_eyes(xs=(84, 116), y=96, iris='#5A3A1E', rx=7.5, ry=8.5, ir=5.4, look=1):
    """عيون كرتونية: أبيض، وقزحية، وبؤبؤ، ولمعة."""
    out = ''
    for x in xs:
        dx = look if x < 100 else -look
        out += (f'<ellipse cx="{x}" cy="{y}" rx="{rx}" ry="{ry}" fill="#fff"/>'
                f'<circle cx="{x + dx}" cy="{y + 1}" r="{ir}" fill="{iris}"/><circle cx="{x + dx}" cy="{y + 1}" r="{ir * .58:.1f}" fill="#140D08"/>'
                f'<circle cx="{x - 1.4}" cy="{y - 2.6}" r="{ir * .33:.1f}" fill="#fff"/>')
    return out


def toon_lids(color, xs=(84, 116), y=96, rx=8.2, ry=9.2, line='#1D1A24'):
    return ''.join(f'<ellipse cx="{x}" cy="{y}" rx="{rx}" ry="{ry}" fill="{color}"/>'
                   f'<path d="M{x - rx * .75:.1f} {y + 1} Q{x} {y + 5} {x + rx * .75:.1f} {y + 1}" stroke="{line}" stroke-width="1.7" fill="none" stroke-linecap="round"/>' for x in xs)


# ───────────── السلوقي (حارس المجلس، مستوى ١٠) ─────────────
def saluki():
    ear = '#B98A5E'
    fringe = ''.join(f'<path d="M{x} {y} q{-3 * s} 8 {1 * s} 14" stroke="#9A6E45" stroke-width="2.2" fill="none" stroke-linecap="round"/>'
                     for s in (-1, 1) for x, y in [(100 + s * 46, 120), (100 + s * 40, 128), (100 + s * 52, 112), (100 + s * 34, 134)])
    ears = ''.join(f'<path d="M{100 + s * 22} 62 Q{100 + s * 46} 60 {100 + s * 54} 92 Q{100 + s * 60} 126 {100 + s * 44} 148 Q{100 + s * 30} 140 {100 + s * 30} 112 Q{100 + s * 28} 84 {100 + s * 22} 62 Z" fill="{ear}"/>' for s in (-1, 1))
    head = ('<path d="M100 52 Q124 54 128 82 Q130 102 118 120 Q109 134 106 144 Q100 151 94 144 Q91 134 82 120 Q70 102 72 82 Q76 54 100 52 Z" fill="#F3E6CF"/>'
            '<path d="M100 56 Q104 80 103 104 Q102 124 100 140 Q98 124 97 104 Q96 80 100 56 Z" fill="#FFF8EC" opacity=".8"/>'
            '<path d="M76 84 Q84 78 92 84 M108 84 Q116 78 124 84" stroke="#B98A5E" stroke-width="2.6" fill="none" stroke-linecap="round"/>')
    nose = ('<path d="M92 137 Q100 132 108 137 Q107 145 100 147 Q93 145 92 137 Z" fill="#2B1B10"/>'
            '<ellipse cx="97.5" cy="138" rx="2" ry="1.2" fill="#fff" opacity=".6"/>'
            '<path d="M100 147 V150 M94 152 Q100 156 106 152" stroke="#6B4A2E" stroke-width="2" fill="none" stroke-linecap="round"/>')
    body = '<path d="M34 200 Q42 158 80 150 Q100 158 120 150 Q158 158 166 200 Z" fill="#EAD9BC"/>'
    collar = '<path d="M76 152 Q100 166 124 152 L124 160 Q100 174 76 160 Z" fill="#B91C1C"/><path d="M78 156 Q100 169 122 156" stroke="#FCD34D" stroke-width="2" fill="none" stroke-dasharray="4 3"/>'
    shield = ('<path d="M100 166 L120 172 V184 Q120 196 100 202 Q80 196 80 184 V172 Z" fill="#B45309" stroke="#431407" stroke-width="3"/>'
              '<path d="M100 174 L103.5 181.5 L111.5 181.5 L105 186 L107.5 194 L100 189 L92.5 194 L95 186 L88.5 181.5 L96.5 181.5 Z" fill="#FDE68A"/>')
    return body + ears + fringe + head + toon_eyes(y=96, rx=6.6, ry=7.4, ir=4.8, iris='#4A2C14') + nose + collar + shield


# ───────────── البومة (الحكيم، مستوى ٢٠) ─────────────
def owl_body():
    feathers = ''.join(f'<path d="M{x} {y} q4 5 8 0" stroke="#A8957A" stroke-width="2" fill="none"/>' for x in (82, 96, 110) for y in (160, 172, 184))
    return ('<path d="M28 200 Q30 150 62 138 Q100 128 138 138 Q170 150 172 200 Z" fill="#7A6650"/>'
            '<path d="M66 200 Q66 160 100 150 Q134 160 134 200 Z" fill="#E6D7BA"/>' + feathers)


def owl_head():
    tufts = ''.join(f'<path d="M{100 + s * 30} 62 L{100 + s * 46} 32 L{100 + s * 50} 66 Z" fill="#6B5843"/>' for s in (-1, 1))
    head = '<path d="M50 96 Q48 58 100 54 Q152 58 150 96 Q150 136 100 142 Q50 136 50 96 Z" fill="#8C7A64"/>'
    disc = ''.join(f'<circle cx="{100 + s * 21}" cy="98" r="23" fill="#EFE3CC"/>' for s in (-1, 1))
    brows = ''.join(f'<path d="M{100 + s * 4} 74 Q{100 + s * 22} 66 {100 + s * 40} 78" stroke="#5A4835" stroke-width="5" fill="none" stroke-linecap="round"/>' for s in (-1, 1))
    beak = '<path d="M93 108 Q100 104 107 108 L101.5 124 Q100 126 98.5 124 Z" fill="#F2A93B" stroke="#9A5B12" stroke-width="1.6"/>'
    return tufts + head + disc + brows + toon_eyes(xs=(79, 121), y=98, iris='#F59E0B', rx=13, ry=13, ir=9, look=0) + beak


def owl_glasses():
    return (''.join(f'<circle cx="{100 + s * 21}" cy="98" r="16" fill="#BFE3FF" fill-opacity=".14" stroke="#C9A227" stroke-width="3.4"/>' for s in (-1, 1))
            + '<path d="M95 96 Q100 92 105 96" stroke="#C9A227" stroke-width="3" fill="none"/>'
            + '<path d="M70 92 Q74 86 80 87 M112 92 Q116 86 122 87" stroke="#fff" stroke-width="2" fill="none" opacity=".75" stroke-linecap="round"/>')


def owl_wing():
    return ('<path d="M114 146 Q146 138 166 158 Q170 176 150 190 Q128 186 114 146 Z" fill="#6B5843"/>'
            + ''.join(f'<path d="M{x} {y} q6 3 10 9" stroke="#5A4835" stroke-width="2" fill="none"/>' for x, y in [(128, 152), (138, 150), (148, 154)]))


def owl_tip():
    return '<path d="M126 184 Q136 176 150 182 Q148 190 136 192 Q128 190 126 184 Z" fill="#7A6650"/>'


def owl_lids():
    return toon_lids('#EFE3CC', xs=(79, 121), y=98, rx=13.6, ry=13.6, line='#5A4835')


def owl():
    return owl_body() + owl_wing() + owl_head() + owl_glasses() + book() + owl_tip()


# ───────────── النمر الذهبي (مستوى ٣٠) ─────────────
def leopard_head():
    fur, dark = '#F2B33D', '#6B3E12'
    ears = ''.join(f'<path d="M{100 + s * 24} 64 Q{100 + s * 40} 34 {100 + s * 54} 60 Q{100 + s * 56} 74 {100 + s * 44} 82 Z" fill="{dark}"/>'
                   f'<path d="M{100 + s * 30} 66 Q{100 + s * 40} 46 {100 + s * 48} 64 Q{100 + s * 48} 72 {100 + s * 42} 76 Z" fill="#F4A6A6"/>' for s in (-1, 1))
    head = f'<path d="M100 56 Q140 58 146 96 Q148 132 118 146 Q100 152 82 146 Q52 132 54 96 Q60 58 100 56 Z" fill="{fur}"/>'
    spots = ''.join(f'<path d="M{x - 5} {y} a5 4 0 1 1 10 0" stroke="{dark}" stroke-width="2.6" fill="none" transform="rotate({r} {x} {y})"/>'
                    for x, y, r in [(86, 70, -15), (114, 70, 15), (64, 100, -70), (136, 100, 70)])
    spots += ''.join(f'<circle cx="{x}" cy="{y}" r="2" fill="{dark}"/>' for x, y in [(100, 66), (94, 76), (106, 76), (62, 116), (138, 116)])
    muzzle = ('<path d="M76 118 Q78 104 100 106 Q122 104 124 118 Q124 136 100 142 Q76 136 76 118 Z" fill="#FFF3DC"/>'
              '<path d="M93 112 Q100 108 107 112 Q105 119 100 121 Q95 119 93 112 Z" fill="#D9777A"/>'
              '<path d="M100 121 V126 M92 128 Q96 132 100 127 Q104 132 108 128" stroke="#6B3E12" stroke-width="2" fill="none" stroke-linecap="round"/>'
              + ''.join(f'<path d="M{100 + s * 18} {y} q{s * 14} {d} {s * 26} {d * 2}" stroke="#fff" stroke-width="1.4" fill="none" opacity=".9"/>' for s in (-1, 1) for y, d in [(120, -2), (126, 0), (132, 2)]))
    return ears + head + spots + toon_eyes(xs=(82, 118), y=94, iris='#22A35A', rx=8.5, ry=8.8, ir=6) + muzzle


def leopard_body():
    return ('<path d="M34 200 Q42 158 78 148 Q100 156 122 148 Q158 158 166 200 Z" fill="#E9A631"/>'
            '<path d="M80 150 Q100 166 120 150 L116 200 H84 Z" fill="#FFF3DC"/>'
            + ''.join(f'<path d="M{x - 5} {y} a5 4 0 1 1 10 0" stroke="#6B3E12" stroke-width="2.6" fill="none"/>' for x, y in [(54, 180), (146, 180), (62, 164), (138, 164)]))


def leopard_lids():
    return toon_lids('#F2B33D', xs=(82, 118), y=94, rx=9.2, ry=9.6, line='#6B3E12')


def leopard():
    return leopard_body() + leopard_head() + gold_chain()


# ───────────── أسد الياقوت (محارب الياقوت، مستوى ٤٠) ─────────────
def lion_mane():
    out = ''
    n = 16
    for layer, (r1, r2, col) in enumerate([(64, 50, '#7F1029'), (56, 44, '#BE123C')]):
        d = ''
        for i in range(n + 1):
            a = -math.pi / 2 + i * 2 * math.pi / n
            am = a + math.pi / n
            x, y = 100 + math.cos(a) * r1, 100 + math.sin(a) * r1
            mx, my = 100 + math.cos(am) * r2, 100 + math.sin(am) * r2
            d += (f'M{x:.1f} {y:.1f} ' if i == 0 else f'L{x:.1f} {y:.1f} ') + (f'Q{100 + math.cos(am - .1) * (r1 + 4):.1f} {100 + math.sin(am - .1) * (r1 + 4):.1f} {mx:.1f} {my:.1f} ' if i < n else '')
        out += f'<path d="{d}Z" fill="{col}"/>'
    return out


def lion_head():
    face = ('<path d="M100 62 Q130 64 134 94 Q136 124 116 140 Q100 148 84 140 Q64 124 66 94 Q70 64 100 62 Z" fill="#E9B872"/>'
            + ''.join(f'<circle cx="{100 + s * 30}" cy="66" r="9" fill="#D9A35E"/><circle cx="{100 + s * 30}" cy="66" r="4.5" fill="#B8784A"/>' for s in (-1, 1))
            + '<path d="M80 116 Q80 104 100 106 Q120 104 120 116 Q120 134 100 140 Q80 134 80 116 Z" fill="#F7E4C0"/>'
            '<path d="M92 110 Q100 106 108 110 Q106 118 100 120 Q94 118 92 110 Z" fill="#7A3B2E"/>'
            '<path d="M100 120 V125 M92 127 Q96 131 100 126 Q104 131 108 127" stroke="#7A3B2E" stroke-width="2" fill="none" stroke-linecap="round"/>'
            '<path d="M74 82 L94 88 M126 82 L106 88" stroke="#7A4A20" stroke-width="3.4" stroke-linecap="round"/>')
    gem = ('<path d="M100 66 L108 74 L100 84 L92 74 Z" fill="#F43F5E" stroke="#FCD34D" stroke-width="2.4" stroke-linejoin="round"/>'
           '<path d="M100 68 L104 74 L100 76 Z" fill="#fff" opacity=".7"/>')
    return face + toon_eyes(xs=(84, 116), y=97, iris='#D97706', rx=7, ry=7.6, ir=5) + gem


def ruby_armor(color='#7F1D1D', accent='#BE123C'):
    return (f'<path d="M26 200 Q30 156 70 146 Q100 156 130 146 Q170 156 174 200 Z" fill="{color}"/>'
            f'<path d="M30 168 Q50 150 70 148 L74 170 Q52 172 30 186 Z M170 168 Q150 150 130 148 L126 170 Q148 172 170 186 Z" fill="#5B1414" stroke="#FCD34D" stroke-width="2"/>'
            f'<path d="M78 156 Q100 166 122 156 L118 200 H82 Z" fill="{accent}" stroke="#FCD34D" stroke-width="2.4"/>'
            '<path d="M100 170 L108 180 L100 192 L92 180 Z" fill="#F43F5E" stroke="#FCD34D" stroke-width="2"/>')


def lion_lids():
    return toon_lids('#E9B872', xs=(84, 116), y=97, rx=7.8, ry=8.4, line='#7A4A20')


def lion_roar():
    return ('<path d="M86 124 Q100 148 114 124 Q100 130 86 124 Z" fill="#4A0F12" stroke="#7A3B2E" stroke-width="2" stroke-linejoin="round"/>'
            '<path d="M90 126 L93 133 L96 127 M104 127 L107 133 L110 126" fill="#fff"/>'
            '<path d="M94 140 Q100 144 106 140 Q100 138 94 140 Z" fill="#E77F7F"/>')


def lion():
    return ruby_armor() + lion_mane() + lion_head()


# ───────────── العنقاء (أسطورة المجلس، مستوى ٥٠) ─────────────
def flame(x, y, h, w, rot, c1, c2):
    """ريشة على شكل لهب: [c1] برا و[c2] جوا."""
    return (f'<g transform="rotate({rot} {x} {y})"><path d="M{x} {y} Q{x - w} {y - h * .45} {x - w * .2} {y - h * .78} Q{x + w * .1} {y - h * .9} {x} {y - h} '
            f'Q{x + w * .5} {y - h * .62} {x + w * .9} {y - h * .5} Q{x + w * .7} {y - h * .2} {x} {y} Z" fill="{c1}"/>'
            f'<path d="M{x} {y - 2} Q{x - w * .45} {y - h * .4} {x} {y - h * .7} Q{x + w * .45} {y - h * .4} {x} {y - 2} Z" fill="{c2}"/></g>')


def phoenix_crest():
    return ''.join(flame(100, 66, h, 13, r, c1, c2) for r, h, c1, c2 in
                   [(-46, 40, '#DC2626', '#FB923C'), (-22, 50, '#F97316', '#FDE68A'), (0, 58, '#DC2626', '#FCD34D'),
                    (22, 50, '#F97316', '#FDE68A'), (46, 40, '#DC2626', '#FB923C')])


def phoenix_head(crest=True):
    head = ('<path d="M100 58 Q138 60 142 98 Q144 130 118 144 Q100 150 82 144 Q56 130 58 98 Q62 60 100 58 Z" fill="#F97316"/>'
            + '<path d="M70 96 Q72 74 100 72 Q128 74 130 96 Q132 124 100 132 Q68 124 70 96 Z" fill="#FFEDD5"/>')
    brows = ''.join(f'<path d="M{100 + s * 8} 82 Q{100 + s * 18} 75 {100 + s * 30} 81" stroke="#9A3412" stroke-width="3.6" fill="none" stroke-linecap="round"/>' for s in (-1, 1))
    beak = ('<path d="M90 108 Q100 102 110 108 L103 128 Q100 132 97 128 Z" fill="#FCD34D" stroke="#B45309" stroke-width="1.8"/>'
            '<path d="M96 110 Q100 108 104 110" stroke="#fff" stroke-width="1.4" fill="none" opacity=".7"/>')
    return (phoenix_crest() if crest else '') + head + brows + toon_eyes(xs=(82, 118), y=96, iris='#B45309', rx=8, ry=8.6, ir=5.6) + beak


def phoenix_wings():
    return ''.join(flame(100 + s * 48, 206, 74, 22, s * 52, '#DC2626', '#F97316') + flame(100 + s * 44, 206, 56, 16, s * 40, '#F97316', '#FDE68A') for s in (-1, 1))


def phoenix_body():
    scales = ''.join(f'<path d="M{x - 7} {y} q7 8 14 0" stroke="#EA580C" stroke-width="2" fill="none"/>' for x in (86, 100, 114) for y in (162, 176, 190))
    return '<path d="M50 200 Q56 156 100 146 Q144 156 150 200 Z" fill="#EA580C"/>' + '<path d="M72 200 Q74 164 100 156 Q126 164 128 200 Z" fill="#FED7AA"/>' + scales


def phoenix_lids():
    return toon_lids('#FFEDD5', xs=(82, 118), y=96, rx=8.8, ry=9.4, line='#9A3412')


def phoenix():
    return phoenix_wings() + phoenix_body() + phoenix_head()


# ───────────── وشق الليل (الموسم الأول) ─────────────
def caracal_ear(s):
    """أذن طويلة وفي راسها خصلة سودا (علامة الوشق)."""
    return (f'<path d="M{100 + s * 18} 68 L{100 + s * 46} 14 L{100 + s * 52} 74 Z" fill="#3A2416"/>'
            f'<path d="M{100 + s * 24} 68 L{100 + s * 44} 28 L{100 + s * 46} 72 Z" fill="#E7B98C"/>'
            f'<path d="M{100 + s * 46} 16 Q{100 + s * 50} 2 {100 + s * 58} -4 Q{100 + s * 52} 8 {100 + s * 50} 18 Z" fill="#141010"/>')


def caracal_head(ears=True):
    fur = '#C98A4E'
    ears = caracal_ear(-1) + caracal_ear(1) if ears else ''
    head = f'<path d="M100 58 Q136 60 142 96 Q146 130 118 144 Q100 150 82 144 Q54 130 58 96 Q64 60 100 58 Z" fill="{fur}"/>'
    marks = ('<path d="M92 66 Q90 76 86 86 M108 66 Q110 76 114 86" stroke="#3A2416" stroke-width="3" fill="none" stroke-linecap="round"/>'
             + ''.join(f'<ellipse cx="{100 + s * 18}" cy="96" rx="12" ry="11" fill="#F4E1C8"/>' for s in (-1, 1)))
    muzzle = ('<path d="M78 120 Q80 106 100 108 Q120 106 122 120 Q122 138 100 142 Q78 138 78 120 Z" fill="#F7EBDD"/>'
              '<path d="M93 113 Q100 109 107 113 Q105 120 100 122 Q95 120 93 113 Z" fill="#B85C5C"/>'
              '<path d="M100 122 V126 M92 129 Q96 133 100 128 Q104 133 108 129" stroke="#3A2416" stroke-width="2" fill="none" stroke-linecap="round"/>'
              + ''.join(f'<circle cx="{100 + s * 14}" cy="{y}" r="1.6" fill="#3A2416"/>' for s in (-1, 1) for y in (120, 126)))
    return ears + head + marks + toon_eyes(xs=(82, 118), y=96, iris='#C7A43B', rx=7.6, ry=8.4, ir=5.6) + muzzle


def caracal_body():
    return ('<path d="M34 200 Q42 158 80 148 Q100 156 120 148 Q158 158 166 200 Z" fill="#0F2E2C"/>'
            '<path d="M74 150 Q100 170 126 150 L130 162 Q100 184 70 162 Z" fill="#134E4A" stroke="#FCD34D" stroke-width="2"/>'
            '<path d="M106 166 Q92 168 92 178 Q94 190 106 190 Q99 184 99 178 Q99 172 106 166 Z" fill="#FCD34D" stroke="#7A4E00" stroke-width="1.5"/>')


def caracal_lids():
    return toon_lids('#F4E1C8', xs=(82, 118), y=96, rx=8.3, ry=9.1, line='#3A2416')


def caracal():
    return caracal_body() + caracal_head()


# ───────────── غزال القمر (الموسم الأول) ─────────────
def gazelle_horns():
    out = ''
    for s in (-1, 1):
        out += (f'<path d="M{100 + s * 12} 64 Q{100 + s * 4} 36 {100 + s * 18} 14 Q{100 + s * 28} 4 {100 + s * 24} 20 Q{100 + s * 14} 38 {100 + s * 20} 64 Z" fill="#3B2A1A"/>'
                + ''.join(f'<path d="M{100 + s * (10 - i * .6):.1f} {58 - i * 7} q{s * 5} -1 {s * 9} 1" stroke="#7A5C3E" stroke-width="1.6" fill="none"/>' for i in range(5)))
    return out


def gazelle_ear(s):
    return (f'<ellipse cx="{100 + s * 40}" cy="76" rx="18" ry="8.5" fill="#D9A066" transform="rotate({s * -28} {100 + s * 40} 76)"/>'
            f'<ellipse cx="{100 + s * 41}" cy="76" rx="11" ry="4.4" fill="#F2D2C2" transform="rotate({s * -28} {100 + s * 41} 76)"/>')


def gazelle_head(ears=True):
    fur = '#D9A066'
    ears = gazelle_ear(-1) + gazelle_ear(1) if ears else ''
    head = f'<path d="M100 58 Q128 60 132 86 Q134 110 122 128 Q112 144 100 148 Q88 144 78 128 Q66 110 68 86 Q72 60 100 58 Z" fill="{fur}"/>'
    stripes = (''.join(f'<path d="M{100 + s * 8} 74 Q{100 + s * 16} 100 {100 + s * 8} 132" stroke="#FFF6EA" stroke-width="7" fill="none" stroke-linecap="round"/>'
                       f'<path d="M{100 + s * 15} 76 Q{100 + s * 24} 102 {100 + s * 14} 130" stroke="#7A4A26" stroke-width="3" fill="none" stroke-linecap="round" opacity=".6"/>' for s in (-1, 1))
               + '<path d="M86 128 Q100 122 114 128 Q114 144 100 148 Q86 144 86 128 Z" fill="#FFF6EA"/>'
               '<path d="M93 132 Q100 128 107 132 Q105 138 100 139 Q95 138 93 132 Z" fill="#3B2A1A"/>'
               '<path d="M94 143 Q100 147 106 143" stroke="#8A6040" stroke-width="2" fill="none" stroke-linecap="round"/>')
    moon = ('<path d="M108 20 Q88 22 88 40 Q90 56 108 58 Q96 50 96 39 Q96 28 108 20 Z" fill="#FDE68A" stroke="#B7791F" stroke-width="1.5"/>')
    return gazelle_horns() + ears + head + stripes + toon_eyes(xs=(84, 116), y=94, iris='#3B2414', rx=8, ry=9, ir=6.2) + moon


def gazelle_body():
    return ('<path d="M36 200 Q44 158 80 150 Q100 158 120 150 Q156 158 164 200 Z" fill="#C98E58"/>'
            '<path d="M82 152 Q100 164 118 152 L116 200 H84 Z" fill="#FFF6EA"/>'
            '<path d="M76 154 Q100 172 124 154" stroke="#4338CA" stroke-width="6" fill="none"/>'
            '<path d="M76 154 Q100 172 124 154" stroke="#FDE68A" stroke-width="1.6" fill="none" stroke-dasharray="3 4"/>'
            '<path d="M104 168 Q94 170 94 178 Q95 186 104 186 Q99 182 99 177 Q99 172 104 168 Z" fill="#FDE68A" stroke="#B7791F" stroke-width="1.2"/>')


def gazelle_lids():
    return toon_lids('#D9A066', xs=(84, 116), y=94, rx=8.8, ry=9.8, line='#5A3A1E')


def gazelle():
    return gazelle_body() + gazelle_head()


# ───────────── أصيل الموسم الأول (حصان عربي) ─────────────
def horse_mane():
    return ('<path d="M114 40 Q140 52 146 90 Q150 130 166 170 Q150 176 136 160 Q130 132 128 104 Q126 70 108 52 Z" fill="#15131A"/>'
            '<path d="M124 56 Q138 80 140 112 M134 70 Q146 104 152 150" stroke="#3A3640" stroke-width="2.4" fill="none" stroke-linecap="round"/>')


def horse_head():
    coat, hi = '#3A2A24', '#5A443A'
    ears = ''.join(f'<path d="M{100 + s * 16} 58 Q{100 + s * 20} 34 {100 + s * 24} 22 Q{100 + s * 32} 34 {100 + s * 32} 62 Z" fill="{coat}"/>'
                   f'<path d="M{100 + s * 20} 54 Q{100 + s * 22} 38 {100 + s * 25} 30 Q{100 + s * 29} 40 {100 + s * 28} 56 Z" fill="#1E1512"/>' for s in (-1, 1))
    head = (f'<path d="M100 46 Q128 48 132 76 Q134 100 124 120 Q117 134 119 148 Q112 162 100 162 Q88 162 81 148 Q83 134 76 120 Q66 100 68 76 Q72 48 100 46 Z" fill="{coat}"/>'
            f'<path d="M78 80 Q82 64 96 58" stroke="{hi}" stroke-width="5" fill="none" stroke-linecap="round" opacity=".8"/>'
            # الغرة البيضا من الجبهة لين الخشم
            '<path d="M100 66 Q107 70 105 86 Q103 110 104 130 Q100 136 96 130 Q97 110 95 86 Q93 70 100 66 Z" fill="#F4F1EC"/>'
            '<path d="M82 140 Q100 133 118 140 Q120 158 100 162 Q80 158 82 140 Z" fill="#241A16"/>'
            '<ellipse cx="91" cy="150" rx="4" ry="5.5" fill="#0C0908"/><ellipse cx="109" cy="150" rx="4" ry="5.5" fill="#0C0908"/>')
    forelock = '<path d="M86 52 Q100 40 114 50 Q112 66 104 74 Q100 64 96 72 Q92 64 86 52 Z" fill="#15131A"/>'
    bridle = ('<path d="M70 92 Q100 86 130 92" stroke="#0F766E" stroke-width="6" fill="none"/>'
              '<path d="M80 134 Q100 128 120 134" stroke="#0F766E" stroke-width="6" fill="none"/>'
              '<path d="M72 92 Q76 114 81 134 M128 92 Q124 114 119 134" stroke="#0F766E" stroke-width="5" fill="none"/>'
              '<path d="M70 92 Q100 86 130 92 M80 134 Q100 128 120 134" stroke="#FCD34D" stroke-width="1.6" fill="none" stroke-dasharray="3 3"/>'
              '<circle cx="78" cy="134" r="4" fill="#FCD34D" stroke="#7A4E00"/><circle cx="122" cy="134" r="4" fill="#FCD34D" stroke="#7A4E00"/>'
              '<circle cx="100" cy="88" r="9" fill="#0F766E" stroke="#FCD34D" stroke-width="2"/>'
              '<path d="M104 81 Q94 82 94 89 Q95 96 104 96 Q99 93 99 89 Q99 85 104 81 Z" fill="#FCD34D"/>')
    return ears + head + forelock + toon_eyes(xs=(80, 120), y=104, iris='#2A1A10', rx=7.2, ry=8.2, ir=5.6) + bridle


def horse_body():
    return ('<path d="M36 200 Q44 158 80 150 Q100 160 120 150 Q156 158 164 200 Z" fill="#2E211C"/>'
            '<path d="M40 200 Q50 170 100 168 Q150 170 160 200 Z" fill="#0F766E"/>'
            '<path d="M44 196 Q56 176 100 174 Q144 176 156 196" stroke="#FCD34D" stroke-width="3" fill="none"/>'
            + ''.join(f'<circle cx="{x}" cy="{y}" r="2.6" fill="#FCD34D"/>' for x, y in [(64, 184), (82, 179), (100, 177), (118, 179), (136, 184)]))


def horse_lids():
    return toon_lids('#3A2A24', xs=(80, 120), y=104, rx=7.9, ry=8.9, line='#A88C7C')


def horse():
    return horse_body() + horse_mane() + horse_head()


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
    'lv10': saluki(),
    'lv20': owl(),
    'lv30': leopard(),
    'lv40': lion(),
    'lv50': phoenix(),
    's1a': caracal(),
    's1b': gazelle(),
    's1c': horse(),
    'champ1': oryx(*CHAMPS['champ1']),
    'champ2': oryx(*CHAMPS['champ2']),
    'champ3': oryx(*CHAMPS['champ3']),
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
