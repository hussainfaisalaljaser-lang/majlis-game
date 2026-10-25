"""
أيقونات مجلس الخونة: مرسومة خصيصاً للعبة بنفس الأسلوب (حدود غامقة، تدرج، لمعة، ظل).
كل أيقونة 128×128 وتطلع PNG بدقة 256 (عشان تبان حادة في الجوالات).
تشغيل:  python3 tools/art/icons.py app/assets/icons
"""
import os, subprocess, sys
from concurrent.futures import ThreadPoolExecutor

OUT = sys.argv[1] if len(sys.argv) > 1 else 'app/assets/icons'
ONLY = set(sys.argv[2].split(',')) if len(sys.argv) > 2 else None
SRC = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'build', 'icons')

# ألوان الأسلوب: (فاتح، أساسي، غامق، حد)
GOLD = ('#FFF3BF', '#F7C948', '#C98A12', '#6E4606')
BLUE = ('#CFEFFF', '#3FA9F5', '#1863C9', '#0B2E6B')
RED = ('#FFD0D0', '#EF4B55', '#B3182A', '#5E0812')
GREEN = ('#D4FFE6', '#34C77B', '#1B8A4F', '#0A4227')
PURPLE = ('#EBDDFF', '#9B6BFF', '#5B2FC9', '#2A0F66')
TEAL = ('#CCFBF1', '#2DD4BF', '#0F8F80', '#064E46')
BROWN = ('#F3D9B5', '#B9834A', '#7A4E22', '#3A2310')
SILVER = ('#FFFFFF', '#D6DCE4', '#8E99A8', '#3A4250')
DARK = ('#8D86B8', '#4B4378', '#2A2350', '#120E26')
ORANGE = ('#FFE3C2', '#FF9A3D', '#D9620B', '#6E2B03')
PINK = ('#FFE0F0', '#F472B6', '#C2347E', '#5E0F38')
SKIN = ('#FBE0C3', '#E3B184', '#B9805A', '#5C3A22')
WHITE = ('#FFFFFF', '#F4F1EA', '#CFC8B8', '#5B5347')


class Icon:
    """يجمع تعريفات التدرجات وجسم الأيقونة."""

    def __init__(self):
        self.defs = []
        self.n = 0

    def g(self, c, vertical=True):
        """تدرج من لون الأسلوب [c] ويرجع fill."""
        self.n += 1
        gid = f'g{self.n}'
        x2, y2 = ('0', '1') if vertical else ('1', '1')
        self.defs.append(
            f'<linearGradient id="{gid}" x1="0" y1="0" x2="{x2}" y2="{y2}">'
            f'<stop offset="0" stop-color="{c[0]}"/><stop offset=".5" stop-color="{c[1]}"/><stop offset="1" stop-color="{c[2]}"/></linearGradient>')
        return f'url(#{gid})'

    def rg(self, c):
        self.n += 1
        gid = f'g{self.n}'
        self.defs.append(
            f'<radialGradient id="{gid}" cx="40%" cy="35%" r="70%">'
            f'<stop offset="0" stop-color="{c[0]}"/><stop offset=".55" stop-color="{c[1]}"/><stop offset="1" stop-color="{c[2]}"/></radialGradient>')
        return f'url(#{gid})'


def shape(ic, d, c, sw=4.5, extra=''):
    """شكل بتدرج وحد غامق."""
    return f'<path d="{d}" fill="{ic.g(c)}" stroke="{c[3]}" stroke-width="{sw}" stroke-linejoin="round" stroke-linecap="round" {extra}/>'


def circle(ic, cx, cy, r, c, sw=4.5, radial=False):
    fill = ic.rg(c) if radial else ic.g(c)
    return f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="{fill}" stroke="{c[3]}" stroke-width="{sw}"/>'


def shine(cx, cy, rx, ry, rot=-30, op=.5):
    return f'<ellipse cx="{cx}" cy="{cy}" rx="{rx}" ry="{ry}" fill="#fff" opacity="{op}" transform="rotate({rot} {cx} {cy})"/>'


def line(d, color, w=4.5):
    return f'<path d="{d}" fill="none" stroke="{color}" stroke-width="{w}" stroke-linecap="round" stroke-linejoin="round"/>'


def text(x, y, s, size, fill, stroke=None, sw=3, font='Marhey', weight='bold'):
    st = f'stroke="{stroke}" stroke-width="{sw}" paint-order="stroke" stroke-linejoin="round"' if stroke else ''
    return (f'<text x="{x}" y="{y}" font-family="{font}" font-weight="{weight}" font-size="{size}" text-anchor="middle" '
            f'fill="{fill}" {st}>{s}</text>')


ICONS = {}


def icon(name):
    def deco(fn):
        ICONS[name] = fn
        return fn
    return deco


# ═════════════ العملات والإحصائيات ═════════════
@icon('coin')
def _(ic):
    return (circle(ic, 64, 68, 52, GOLD) + f'<circle cx="64" cy="62" r="52" fill="{ic.g(GOLD)}" stroke="{GOLD[3]}" stroke-width="4.5"/>'
            + '<circle cx="64" cy="62" r="40" fill="none" stroke="#C98A12" stroke-width="4"/>'
            + shape(ic, 'M64 34 L72 54 L94 55 L77 68 L83 90 L64 77 L45 90 L51 68 L34 55 L56 54 Z', ('#FFE89A', '#E9AE2A', '#B9780F', '#7A4A06'), 3)
            + shine(44, 38, 15, 7))


@icon('gem')
def _(ic):
    return (shape(ic, 'M32 22 H96 L118 50 L64 114 L10 50 Z', BLUE)
            + '<path d="M32 22 L46 50 H82 L96 22 Z" fill="#BDEBFF" stroke="#0B2E6B" stroke-width="3" stroke-linejoin="round"/>'
            + '<path d="M10 50 H118 M46 50 L64 114 L82 50" fill="none" stroke="#0B2E6B" stroke-width="3" stroke-linejoin="round"/>'
            + '<path d="M32 22 L10 50 H46 Z" fill="#8FDBFF" stroke="#0B2E6B" stroke-width="3" stroke-linejoin="round"/>'
            + '<path d="M96 22 L118 50 H82 Z" fill="#2E8BE8" stroke="#0B2E6B" stroke-width="3" stroke-linejoin="round"/>'
            + '<path d="M40 28 L50 28 L55 40 L45 40 Z" fill="#fff" opacity=".75"/>')


@icon('gems')
def _(ic):
    def g(x, y, s, c):
        return (f'<g transform="translate({x} {y}) scale({s})">' + shape(ic, 'M-27 -26 H27 L46 -2 L0 52 L-46 -2 Z', c, 4)
                + f'<path d="M-27 -26 L-15 -2 H15 L27 -26 Z" fill="{c[0]}" stroke="{c[3]}" stroke-width="3"/>'
                + f'<path d="M-46 -2 H46 M-15 -2 L0 52 L15 -2" fill="none" stroke="{c[3]}" stroke-width="3"/></g>')
    return g(40, 70, .62, PURPLE) + g(90, 72, .62, GREEN) + g(64, 52, .78, BLUE) + shine(56, 36, 8, 4)


@icon('gem_chest')
def _(ic):
    return (shape(ic, 'M14 62 H114 V108 Q114 116 106 116 H22 Q14 116 14 108 Z', BROWN)
            + shape(ic, 'M18 62 Q20 30 64 28 Q108 30 110 62 Z', ('#E8C38F', '#A87038', '#6E4419', '#3A2310'))
            + '<path d="M14 62 H114" stroke="#3A2310" stroke-width="5"/>'
            + shape(ic, 'M56 56 H72 V80 H56 Z', GOLD, 3.5)
            + '<path d="M14 88 H114 M40 62 V116 M88 62 V116" stroke="#C98A12" stroke-width="5" opacity=".9"/>'
            + '<path d="M28 60 L40 40 L52 58 Z" fill="#7DD3FC" stroke="#0B2E6B" stroke-width="2.5"/>'
            + '<path d="M70 58 L84 36 L98 58 Z" fill="#F472B6" stroke="#5E0F38" stroke-width="2.5"/>'
            + '<circle cx="62" cy="44" r="9" fill="#FDE047" stroke="#6E4606" stroke-width="2.5"/>'
            + shine(40, 76, 12, 5, -10, .35))


@icon('games')
def _(ic):
    return (f'<g transform="rotate(-15 64 70)">' + f'<rect x="22" y="22" width="56" height="80" rx="9" fill="{ic.g(PURPLE)}" stroke="#F7C948" stroke-width="4.5"/>'
            + '<path d="M50 46 L55 58 L68 58 L57 66 L61 79 L50 71 L39 79 L43 66 L32 58 L45 58 Z" fill="#F7C948"/></g>'
            + f'<g transform="rotate(14 64 70)"><rect x="50" y="24" width="56" height="80" rx="9" fill="{ic.g(WHITE)}" stroke="#B3182A" stroke-width="4.5"/>'
            + '<circle cx="78" cy="58" r="15" fill="#E5484D"/><path d="M78 46 L82 62 H74 Z M70 62 H86 M78 62 V74" stroke="#fff" stroke-width="4" stroke-linecap="round" fill="#fff"/></g>')


@icon('trophy')
def _(ic):
    return (line('M34 24 C10 24 10 60 40 64 M94 24 C118 24 118 60 88 64', '#B9780F', 9)
            + shape(ic, 'M30 14 H98 V40 C98 66 82 78 64 80 C46 78 30 66 30 40 Z', GOLD)
            + f'<rect x="56" y="78" width="16" height="16" fill="{ic.g(GOLD)}" stroke="{GOLD[3]}" stroke-width="3"/>'
            + shape(ic, 'M38 94 H90 L96 114 H32 Z', GOLD)
            + '<path d="M64 28 L69 40 L82 40 L72 48 L76 60 L64 52 L52 60 L56 48 L46 40 L59 40 Z" fill="#fff" opacity=".85"/>'
            + shine(44, 26, 8, 5))


@icon('winrate')
def _(ic):
    return (f'<g stroke="#0A4227" stroke-width="4">'
            + f'<rect x="16" y="78" width="22" height="34" rx="4" fill="{ic.g(GREEN)}"/><rect x="46" y="58" width="22" height="54" rx="4" fill="{ic.g(GREEN)}"/>'
            + f'<rect x="76" y="36" width="22" height="76" rx="4" fill="{ic.g(GREEN)}"/></g>'
            + line('M14 66 L50 38 L72 50 L108 18', '#6E4606', 13) + line('M14 66 L50 38 L72 50 L108 18', '#F7C948', 8)
            + shape(ic, 'M92 12 L116 10 L114 34 Z', GOLD, 3))


@icon('xp')
def _(ic):
    return (shape(ic, 'M64 8 L80 46 L120 48 L89 73 L100 114 L64 91 L28 114 L39 73 L8 48 L48 46 Z', GOLD)
            + '<path d="M64 24 L74 50 L64 58 Z" fill="#fff" opacity=".55"/>')


# ═════════════ أقسام المتجر ═════════════
@icon('shop')
def _(ic):
    # دكان في السوق: مظلة مخططة فوق طاولة عليها ذهب
    stripes = ''.join(f'<path d="M{14 + i * 20} 34 L{24 + i * 20} 34 L{24 + i * 20} 54 Q{19 + i * 20} 62 {14 + i * 20} 54 Z" fill="{"#EF4B55" if i % 2 == 0 else "#FFF7E6"}"/>' for i in range(5))
    return (shape(ic, 'M20 54 H108 V110 H20 Z', BROWN)
            + shape(ic, 'M8 34 L20 14 H108 L120 34 Z', ('#FFE1E1', '#EF4B55', '#B3182A', '#5E0812'))
            + f'<g>{stripes}</g>' + line('M10 34 H118', '#5E0812', 4)
            + '<path d="M14 54 Q19 62 24 54 Q29 62 34 54 Q39 62 44 54 Q49 62 54 54 Q59 62 64 54 Q69 62 74 54 Q79 62 84 54 Q89 62 94 54 Q99 62 104 54 Q109 62 114 54" fill="none" stroke="#5E0812" stroke-width="3.5"/>'
            + shape(ic, 'M30 76 H98 V110 H30 Z', ('#4A2D14', '#3A2310', '#24150A', '#120A04'), 3.5)
            + circle(ic, 50, 74, 11, GOLD, 3) + circle(ic, 74, 72, 13, GOLD, 3) + circle(ic, 62, 64, 10, GOLD, 3)
            + shine(30, 22, 12, 4, 0, .45))


@icon('cat_frame')
def _(ic):
    return (f'<circle cx="64" cy="66" r="44" fill="none" stroke="{GOLD[3]}" stroke-width="22"/>'
            + f'<circle cx="64" cy="66" r="44" fill="none" stroke="{ic.g(GOLD)}" stroke-width="15"/>'
            + f'<circle cx="64" cy="66" r="33" fill="{ic.rg(PURPLE)}" stroke="{GOLD[3]}" stroke-width="3"/>'
            + shape(ic, 'M64 6 L76 20 L64 34 L52 20 Z', RED, 3.5)
            + '<circle cx="22" cy="66" r="6" fill="#7DD3FC" stroke="#0B2E6B" stroke-width="2.5"/><circle cx="106" cy="66" r="6" fill="#7DD3FC" stroke="#0B2E6B" stroke-width="2.5"/>'
            + '<path d="M46 66 a18 18 0 0 1 36 0" fill="#fff" opacity=".18"/>' + shine(40, 40, 10, 5))


@icon('cat_avatar')
def _(ic):
    return (circle(ic, 64, 64, 54, PURPLE, radial=True)
            + shape(ic, 'M22 118 Q26 84 64 80 Q102 84 106 118 Z', WHITE)
            + f'<ellipse cx="64" cy="58" rx="22" ry="25" fill="{ic.g(SKIN)}" stroke="{SKIN[3]}" stroke-width="3.5"/>'
            + shape(ic, 'M36 60 Q34 26 64 24 Q94 26 92 60 L98 96 Q86 84 84 66 Q82 42 64 42 Q46 42 44 66 Q42 84 30 96 Z', WHITE, 3.5)
            + '<path d="M38 40 Q64 28 90 40 L90 46 Q64 34 38 46 Z" fill="#1A1622"/>'
            + '<circle cx="56" cy="60" r="3" fill="#1A1622"/><circle cx="72" cy="60" r="3" fill="#1A1622"/>'
            + line('M57 70 Q64 75 71 70', '#7A3B33', 3) + shine(40, 30, 10, 5))


@icon('cat_bubble')
def _(ic):
    return (shape(ic, 'M16 24 H112 Q120 24 120 32 V80 Q120 88 112 88 H58 L34 110 L38 88 H16 Q8 88 8 80 V32 Q8 24 16 24 Z', TEAL)
            + '<circle cx="40" cy="56" r="8" fill="#fff"/><circle cx="64" cy="56" r="8" fill="#fff"/><circle cx="88" cy="56" r="8" fill="#fff"/>'
            + shape(ic, 'M104 4 L108 16 L120 20 L108 24 L104 36 L100 24 L88 20 L100 16 Z', GOLD, 2.5)
            + shine(30, 34, 14, 5, -8))


@icon('cat_sticker')
def _(ic):
    # ملصق بزاوية مطوية وعليه وجه شخصية بغترة تغمز
    return (shape(ic, 'M14 20 Q14 12 22 12 H106 Q114 12 114 20 V84 L84 116 H22 Q14 116 14 108 Z', WHITE)
            + shape(ic, 'M114 84 L84 116 V92 Q84 84 92 84 Z', SILVER, 3.5)
            + f'<g transform="translate(62 66) scale(.62) translate(-64 -60)">'
            + f'<ellipse cx="64" cy="60" rx="25" ry="28" fill="{ic.g(SKIN)}" stroke="{SKIN[3]}" stroke-width="5"/>'
            + shape(ic, 'M34 62 Q32 20 64 18 Q96 20 94 62 L104 104 Q88 90 86 68 Q84 42 64 42 Q44 42 42 68 Q40 90 24 104 Z', WHITE, 5)
            + '<path d="M36 36 Q64 22 92 36 L92 45 Q64 30 36 45 Z" fill="#1A1622"/>'
            + '<circle cx="55" cy="60" r="4.5" fill="#1A1622"/><path d="M67 60 Q73 55 79 60" fill="none" stroke="#1A1622" stroke-width="4.5" stroke-linecap="round"/>'
            + '<path d="M52 72 Q64 84 76 72 Z" fill="#7A2B22" stroke="#3A2310" stroke-width="3"/></g>'
            + shape(ic, 'M96 18 L100 30 L112 34 L100 38 L96 50 L92 38 L80 34 L92 30 Z', GOLD, 2.5))


@icon('cat_table')
def _(ic):
    return (shape(ic, 'M10 30 H118 V98 H10 Z', RED)
            + '<rect x="18" y="38" width="92" height="52" fill="none" stroke="#F7C948" stroke-width="3.5" stroke-dasharray="6 4"/>'
            + ''.join(f'<path d="M{6 if s < 0 else 122} {36 + i * 8} h{s * 8}" stroke="#E9D6A8" stroke-width="2.5"/>' for s in (-1, 1) for i in range(8))
            + f'<ellipse cx="64" cy="64" rx="34" ry="21" fill="{ic.rg(GOLD)}" stroke="{GOLD[3]}" stroke-width="4"/>'
            + '<ellipse cx="64" cy="64" rx="24" ry="13" fill="none" stroke="#C98A12" stroke-width="2.5"/>' + shine(52, 58, 10, 4, 0, .5))


@icon('cat_cards')
def _(ic):
    return (f'<g transform="rotate(-18 64 76)"><rect x="24" y="22" width="52" height="76" rx="9" fill="{ic.g(WHITE)}" stroke="#1863C9" stroke-width="4.5"/>'
            + f'<circle cx="50" cy="56" r="14" fill="{ic.g(BLUE)}" stroke="#0B2E6B" stroke-width="3"/></g>'
            + f'<g transform="rotate(14 64 76)"><rect x="52" y="22" width="52" height="76" rx="9" fill="{ic.g(WHITE)}" stroke="#B3182A" stroke-width="4.5"/>'
            + f'<circle cx="78" cy="56" r="14" fill="{ic.g(RED)}" stroke="#5E0812" stroke-width="3"/></g>')


# ═════════════ أزرار وواجهة ═════════════
@icon('lock')
def _(ic):
    return (line('M40 56 V40 Q40 16 64 16 Q88 16 88 40 V56', SILVER[3], 15) + line('M40 56 V40 Q40 16 64 16 Q88 16 88 40 V56', '#D6DCE4', 8)
            + shape(ic, 'M24 54 H104 Q112 54 112 62 V108 Q112 116 104 116 H24 Q16 116 16 108 V62 Q16 54 24 54 Z', GOLD)
            + '<circle cx="64" cy="80" r="9" fill="#5B3A06"/><path d="M60 84 H68 L66 100 H62 Z" fill="#5B3A06"/>' + shine(36, 64, 10, 5))


@icon('info')
def _(ic):
    return (circle(ic, 64, 64, 54, BLUE, radial=True) + '<circle cx="64" cy="36" r="9" fill="#fff"/>'
            + '<path d="M54 54 H70 V94 H78 V102 H50 V94 H58 V62 H54 Z" fill="#fff"/>' + shine(42, 34, 14, 7))


@icon('pass')
def _(ic):
    # تذكرة الموسم الذهبية
    return (shape(ic, 'M10 34 H118 V52 Q108 52 108 64 Q108 76 118 76 V94 H10 V76 Q20 76 20 64 Q20 52 10 52 Z', GOLD)
            + '<path d="M38 34 V94" stroke="#6E4606" stroke-width="3" stroke-dasharray="5 5"/>'
            + shape(ic, 'M24 52 L27 60 L35 61 L29 66 L31 74 L24 70 L17 74 L19 66 L13 61 L21 60 Z', RED, 2.5)
            + text(78, 78, '١', 44, '#fff', '#6E4606', 6) + shine(70, 42, 26, 4, 0, .45))


@icon('gift')
def _(ic):
    return (shape(ic, 'M18 56 H110 V112 H18 Z', RED) + shape(ic, 'M12 40 H116 V60 H12 Z', RED)
            + f'<rect x="56" y="40" width="16" height="72" fill="{ic.g(GOLD)}" stroke="{GOLD[3]}" stroke-width="3.5"/>'
            + shape(ic, 'M64 40 Q40 10 30 26 Q24 40 64 40 Z', GOLD, 3.5) + shape(ic, 'M64 40 Q88 10 98 26 Q104 40 64 40 Z', GOLD, 3.5)
            + shine(30, 48, 10, 4, 0, .5))


@icon('check')
def _(ic):
    return circle(ic, 64, 64, 54, GREEN, radial=True) + line('M38 66 L56 84 L92 44', '#0A4227', 16) + line('M38 66 L56 84 L92 44', '#fff', 10) + shine(42, 34, 14, 7)


@icon('cross')
def _(ic):
    return circle(ic, 64, 64, 54, RED, radial=True) + line('M42 42 L86 86 M86 42 L42 86', '#5E0812', 16) + line('M42 42 L86 86 M86 42 L42 86', '#fff', 10) + shine(42, 34, 14, 7)


@icon('warning')
def _(ic):
    return (shape(ic, 'M64 10 L122 112 H6 Z', ORANGE, 5) + '<path d="M58 42 H70 L68 82 H60 Z" fill="#3A1A02"/><circle cx="64" cy="96" r="7" fill="#3A1A02"/>'
            + shine(56, 40, 6, 12, 30, .4))


@icon('edit')
def _(ic):
    # قلم القصب للكتابة العربية
    return (f'<g transform="rotate(40 64 64)">' + shape(ic, 'M56 6 H72 V96 L64 122 L56 96 Z', BROWN)
            + '<path d="M56 96 L64 122 L72 96 Z" fill="#F3D9B5" stroke="#3A2310" stroke-width="3.5" stroke-linejoin="round"/>'
            + '<path d="M64 106 V122" stroke="#1A1622" stroke-width="3"/>' + '<path d="M56 26 H72 M56 32 H72" stroke="#3A2310" stroke-width="3"/></g>'
            + '<path d="M20 112 Q36 100 52 108" fill="none" stroke="#1A1622" stroke-width="5" stroke-linecap="round"/>')


@icon('tools')
def _(ic):
    return (f'<g transform="rotate(-45 64 64)">' + shape(ic, 'M58 40 H70 V118 Q70 122 64 122 Q58 122 58 118 Z', BROWN)
            + shape(ic, 'M36 16 H92 V44 H36 Z', SILVER) + '</g>'
            + f'<g transform="rotate(45 64 64)">' + shape(ic, 'M58 48 H70 V118 Q64 124 58 118 Z', SILVER)
            + shape(ic, 'M64 6 a22 22 0 1 0 0.1 0 Z M56 10 V30 H72 V10', SILVER) + '</g>')


@icon('key')
def _(ic):
    return (shape(ic, 'M58 62 L112 62 L112 74 L104 74 L104 86 L94 86 L94 74 L86 74 L86 84 L76 84 L76 74 L58 74 Z', GOLD)
            + f'<circle cx="38" cy="68" r="28" fill="{ic.g(GOLD)}" stroke="{GOLD[3]}" stroke-width="4.5"/>'
            + '<circle cx="38" cy="68" r="11" fill="#2A2350" stroke="#6E4606" stroke-width="3"/>'
            + '<path d="M38 40 L44 50 L38 56 L32 50 Z" fill="#EF4B55" stroke="#5E0812" stroke-width="2"/>' + shine(28, 52, 9, 5))


@icon('plus')
def _(ic):
    return circle(ic, 64, 64, 54, PURPLE, radial=True) + line('M64 34 V94 M34 64 H94', '#2A0F66', 16) + line('M64 34 V94 M34 64 H94', '#fff', 10) + shine(42, 34, 14, 7)


@icon('exit')
def _(ic):
    # باب مقوّس وسهم طالع
    return (shape(ic, 'M24 118 V48 Q24 14 58 14 Q92 14 92 48 V118 Z', BROWN)
            + shape(ic, 'M34 118 V50 Q34 26 58 26 Q82 26 82 50 V118 Z', ('#6E4A2A', '#4A2D14', '#2A180A', '#120A04'), 3)
            + '<circle cx="72" cy="78" r="4" fill="#F7C948"/>'
            + shape(ic, 'M70 58 H96 V44 L124 70 L96 96 V82 H70 Z', RED, 4))


@icon('home')
def _(ic):
    # بيت عربي بقوس
    return (shape(ic, 'M16 58 L64 18 L112 58 V114 H16 Z', ('#FFF6E0', '#EED3A1', '#C9A066', '#5A3D18'))
            + shape(ic, 'M8 62 L64 14 L120 62', RED, 5, 'fill="none"')
            + shape(ic, 'M50 114 V82 Q50 66 64 66 Q78 66 78 82 V114 Z', BROWN, 3.5)
            + '<path d="M28 74 h14 v14 h-14 Z M86 74 h14 v14 h-14 Z" fill="#7DD3FC" stroke="#5A3D18" stroke-width="3"/>'
            + shine(44, 46, 12, 5, -30, .45))


@icon('profile')
def _(ic):
    return (shape(ic, 'M18 120 Q20 82 64 76 Q108 82 110 120 Z', WHITE)
            + f'<ellipse cx="64" cy="54" rx="24" ry="27" fill="{ic.g(SKIN)}" stroke="{SKIN[3]}" stroke-width="4"/>'
            + shape(ic, 'M34 58 Q32 18 64 16 Q96 18 94 58 L102 100 Q88 86 86 64 Q84 38 64 38 Q44 38 42 64 Q40 86 26 100 Z', WHITE, 4)
            + '<path d="M36 34 Q64 20 92 34 L92 42 Q64 28 36 42 Z" fill="#1A1622"/>'
            + '<circle cx="55" cy="56" r="3.5" fill="#1A1622"/><circle cx="73" cy="56" r="3.5" fill="#1A1622"/>'
            + line('M55 68 Q64 74 73 68', '#7A3B33', 3.5))


@icon('friends')
def _(ic):
    def person(x, s, head, cloth):
        return (f'<g transform="translate({x} 0) scale({s}) translate(-64 0)">' + shape(ic, 'M22 122 Q24 86 64 80 Q104 86 106 122 Z', cloth)
                + f'<ellipse cx="64" cy="56" rx="24" ry="27" fill="{ic.g(SKIN)}" stroke="{SKIN[3]}" stroke-width="4"/>'
                + shape(ic, head, WHITE if cloth == WHITE else PINK, 4) + '</g>')
    ghutra = 'M36 60 Q34 20 64 18 Q94 20 92 60 L100 100 Q88 88 86 66 Q84 40 64 40 Q44 40 42 66 Q40 88 28 100 Z'
    hijab = 'M38 62 Q36 22 64 20 Q92 22 90 62 Q92 92 80 102 Q64 110 48 102 Q36 92 38 62 Z M64 34 Q84 34 84 58 Q84 82 64 86 Q44 82 44 58 Q44 34 64 34 Z'
    return person(44, .78, hijab, PINK) + person(84, .86, ghutra, WHITE)


@icon('rank')
def _(ic):
    return (shape(ic, 'M44 52 H84 V118 H44 Z', GOLD) + shape(ic, 'M8 74 H44 V118 H8 Z', SILVER) + shape(ic, 'M84 86 H120 V118 H84 Z', BROWN)
            + text(64, 94, '١', 34, '#fff', '#6E4606', 5) + text(26, 106, '٢', 28, '#fff', '#3A4250', 5) + text(102, 112, '٣', 24, '#fff', '#3A2310', 5)
            + shape(ic, 'M50 40 L54 22 L64 32 L74 22 L78 40 Z', GOLD, 3.5))


@icon('missions')
def _(ic):
    return (shape(ic, 'M28 14 H100 V114 H28 Z', WHITE)
            + ''.join(f'<rect x="38" y="{30 + i * 24}" width="14" height="14" rx="3" fill="{"#34C77B" if i < 2 else "#fff"}" stroke="#5B5347" stroke-width="3"/>'
                      f'<path d="M60 {37 + i * 24} H90" stroke="#B9AFA0" stroke-width="5" stroke-linecap="round"/>' for i in range(3))
            + line('M40 36 L44 40 L51 31 M40 60 L44 64 L51 55', '#fff', 3.5)
            + shape(ic, 'M20 8 H108 V20 H20 Z', BROWN, 3.5) + shape(ic, 'M20 108 H108 V120 H20 Z', BROWN, 3.5))


@icon('bot')
def _(ic):
    return (line('M64 26 V12', '#3A4250', 5) + '<circle cx="64" cy="10" r="7" fill="#EF4B55" stroke="#5E0812" stroke-width="3"/>'
            + shape(ic, 'M24 30 H104 Q114 30 114 40 V92 Q114 102 104 102 H24 Q14 102 14 92 V40 Q14 30 24 30 Z', SILVER)
            + '<rect x="28" y="44" width="72" height="36" rx="12" fill="#1E1B4B" stroke="#3A4250" stroke-width="3"/>'
            + '<circle cx="48" cy="62" r="8" fill="#5EEAD4"/><circle cx="80" cy="62" r="8" fill="#5EEAD4"/>'
            + '<rect x="8" y="54" width="8" height="22" rx="3" fill="#8E99A8" stroke="#3A4250" stroke-width="3"/><rect x="112" y="54" width="8" height="22" rx="3" fill="#8E99A8" stroke="#3A4250" stroke-width="3"/>'
            + line('M48 90 H80', '#3A4250', 4) + shine(36, 38, 12, 4, 0, .6))


@icon('music')
def _(ic):
    # عود
    return (f'<g transform="rotate(-35 64 64)">' + shape(ic, 'M56 8 H72 V58 H56 Z', BROWN, 4)
            + shape(ic, 'M50 4 H78 V16 H50 Z', ('#5A3A1E', '#3A2310', '#24150A', '#120A04'), 3)
            + shape(ic, 'M64 50 Q100 58 100 88 Q100 122 64 122 Q28 122 28 88 Q28 58 64 50 Z', ORANGE)
            + '<circle cx="64" cy="86" r="10" fill="#3A1A02"/>' + line('M60 16 V110 M68 16 V110', '#FFF3BF', 1.6)
            + shape(ic, 'M54 104 H74 V110 H54 Z', ('#5A3A1E', '#3A2310', '#24150A', '#120A04'), 2.5) + shine(48, 72, 8, 14, 0, .35) + '</g>')


@icon('music_off')
def _(ic):
    return ICONS['music'](ic) + line('M14 14 L114 114', '#5E0812', 16) + line('M14 14 L114 114', '#EF4B55', 9)


@icon('sound')
def _(ic):
    return (shape(ic, 'M16 48 H38 L70 20 V108 L38 80 H16 Z', GOLD)
            + line('M84 46 Q96 64 84 82', '#6E4606', 9) + line('M84 46 Q96 64 84 82', '#F7C948', 5)
            + line('M98 32 Q120 64 98 96', '#6E4606', 9) + line('M98 32 Q120 64 98 96', '#F7C948', 5) + shine(30, 54, 8, 4, 0, .5))


@icon('mute')
def _(ic):
    return (shape(ic, 'M16 48 H38 L70 20 V108 L38 80 H16 Z', SILVER)
            + line('M84 48 L116 80 M116 48 L84 80', '#5E0812', 13) + line('M84 48 L116 80 M116 48 L84 80', '#EF4B55', 7))


@icon('chat')
def _(ic):
    return (shape(ic, 'M44 16 H110 Q120 16 120 26 V60 Q120 70 110 70 H104 L108 86 L88 70 H44 Q34 70 34 60 V26 Q34 16 44 16 Z', SILVER, 4)
            + shape(ic, 'M18 46 H82 Q92 46 92 56 V90 Q92 100 82 100 H44 L22 116 L26 100 H18 Q8 100 8 90 V56 Q8 46 18 46 Z', GOLD, 4.5)
            + '<circle cx="32" cy="73" r="6" fill="#6E4606"/><circle cx="50" cy="73" r="6" fill="#6E4606"/><circle cx="68" cy="73" r="6" fill="#6E4606"/>'
            + shine(26, 54, 10, 4, 0, .5))


@icon('log')
def _(ic):
    # مخطوطة
    return (shape(ic, 'M30 20 H98 V108 H30 Z', ('#FFF6E0', '#F0DDB0', '#D4B57A', '#6E4A1A'))
            + ''.join(f'<path d="M42 {40 + i * 13} H{86 - (i % 2) * 14}" stroke="#8A6A3A" stroke-width="4" stroke-linecap="round"/>' for i in range(5))
            + shape(ic, 'M20 12 Q20 4 30 4 H98 Q108 4 108 12 Q108 22 98 22 H30 Q20 22 20 12 Z', BROWN, 4)
            + shape(ic, 'M20 116 Q20 106 30 106 H98 Q108 106 108 116 Q108 124 98 124 H30 Q20 124 20 116 Z', BROWN, 4))


@icon('hourglass')
def _(ic):
    return (shape(ic, 'M30 22 H98 Q98 56 70 64 Q98 72 98 106 H30 Q30 72 58 64 Q30 56 30 22 Z', ('#EAF6FF', '#BFE3FF', '#8EC5F0', '#2B4A6B'), 4)
            + '<path d="M42 34 H86 Q80 52 64 58 Q48 52 42 34 Z" fill="#F7C948"/><path d="M44 98 Q64 76 84 98 Z" fill="#F7C948"/>'
            + shape(ic, 'M20 10 H108 V24 H20 Z', BROWN, 4) + shape(ic, 'M20 104 H108 V118 H20 Z', BROWN, 4))


@icon('fire')
def _(ic):
    return (shape(ic, 'M64 6 Q72 34 92 46 Q112 64 104 90 Q96 118 64 120 Q32 118 24 90 Q18 66 40 46 Q44 64 54 66 Q46 34 64 6 Z', ORANGE)
            + '<path d="M64 52 Q70 70 82 78 Q90 92 82 104 Q74 114 64 114 Q52 114 46 104 Q40 90 52 78 Q60 72 64 52 Z" fill="#FFE27A"/>')


@icon('search')
def _(ic):
    return (line('M80 80 L114 114', BROWN[3], 20) + line('M80 80 L114 114', '#B9834A', 13)
            + f'<circle cx="54" cy="54" r="38" fill="#BDE7FF" fill-opacity=".55" stroke="{GOLD[3]}" stroke-width="16"/>'
            + f'<circle cx="54" cy="54" r="38" fill="none" stroke="{ic.g(GOLD)}" stroke-width="10"/>'
            + '<path d="M34 46 Q38 32 52 30" fill="none" stroke="#fff" stroke-width="6" stroke-linecap="round"/>')


@icon('eye')
def _(ic):
    return (shape(ic, 'M6 64 Q64 4 122 64 Q64 124 6 64 Z', WHITE)
            + circle(ic, 64, 64, 26, BLUE, 4, radial=True) + '<circle cx="64" cy="64" r="11" fill="#0B1026"/><circle cx="72" cy="56" r="5" fill="#fff"/>')


@icon('ballot')
def _(ic):
    return (shape(ic, 'M44 8 H84 V58 H44 Z', WHITE, 4) + line('M52 22 H76 M52 34 H70', '#8A8070', 4)
            + shape(ic, 'M14 50 H114 V118 H14 Z', BLUE) + '<rect x="38" y="48" width="52" height="10" rx="4" fill="#0B2E6B"/>'
            + shape(ic, 'M54 72 L60 86 L76 88 L64 98 L67 114 L54 106 L41 114 L44 98 L32 88 L48 86 Z', GOLD, 3) + shine(30, 62, 10, 4, 0, .45))


@icon('dagger')
def _(ic):
    # خنجر عُماني معقوف
    return (shape(ic, 'M58 52 Q52 82 64 104 Q78 122 98 118 Q74 112 70 92 Q66 72 72 52 Z', SILVER, 4)
            + line('M66 58 Q64 86 82 108', '#FFFFFF', 3)
            + shape(ic, 'M40 44 H90 Q94 50 90 56 H40 Q36 50 40 44 Z', GOLD, 4)
            + shape(ic, 'M54 10 H76 L72 44 H58 Z', BROWN, 4) + circle(ic, 65, 10, 9, GOLD, 3.5) + '<circle cx="65" cy="50" r="4" fill="#EF4B55"/>')


@icon('shield')
def _(ic):
    return (shape(ic, 'M64 6 L112 22 V58 Q112 98 64 122 Q16 98 16 58 V22 Z', BLUE)
            + shape(ic, 'M64 22 L96 32 V58 Q96 86 64 104 Q32 86 32 58 V32 Z', GOLD, 3.5)
            + '<path d="M64 40 L70 54 L86 55 L74 65 L78 81 L64 72 L50 81 L54 65 L42 55 L58 54 Z" fill="#1863C9"/>' + shine(42, 30, 12, 6))


@icon('seer')
def _(ic):
    return (f'<circle cx="64" cy="54" r="56" fill="#A855F7" opacity=".25"/>'
            + f'<circle cx="64" cy="54" r="42" fill="{ic.rg(PURPLE)}" stroke="{PURPLE[3]}" stroke-width="4.5"/>'
            + '<path d="M44 46 Q56 30 74 34" fill="none" stroke="#fff" stroke-width="7" stroke-linecap="round" opacity=".75"/>'
            + '<path d="M60 60 L63 66 L70 67 L65 72 L66 79 L60 75 L54 79 L55 72 L50 67 L57 66 Z" fill="#FDE68A"/>'
            + shape(ic, 'M30 104 Q34 88 64 88 Q94 88 98 104 L104 118 H24 Z', GOLD))


@icon('crown')
def _(ic):
    return (shape(ic, 'M14 100 L10 34 L40 64 L64 18 L88 64 L118 34 L114 100 Z', GOLD)
            + shape(ic, 'M14 96 H114 V116 H14 Z', GOLD, 4)
            + circle(ic, 10, 32, 8, GOLD, 3) + circle(ic, 64, 16, 9, GOLD, 3) + circle(ic, 118, 32, 8, GOLD, 3)
            + '<circle cx="64" cy="106" r="7" fill="#EF4B55" stroke="#5E0812" stroke-width="2.5"/><circle cx="36" cy="106" r="5.5" fill="#3FA9F5" stroke="#0B2E6B" stroke-width="2.5"/><circle cx="92" cy="106" r="5.5" fill="#3FA9F5" stroke="#0B2E6B" stroke-width="2.5"/>'
            + shine(40, 60, 6, 14, 20, .45))


@icon('skull')
def _(ic):
    return (shape(ic, 'M64 8 Q112 8 112 54 Q112 76 96 84 V104 Q96 112 88 112 H40 Q32 112 32 104 V84 Q16 76 16 54 Q16 8 64 8 Z', WHITE)
            + '<path d="M36 54 Q36 40 50 42 Q60 44 56 60 Q52 70 40 66 Q36 64 36 54 Z M92 54 Q92 40 78 42 Q68 44 72 60 Q76 70 88 66 Q92 64 92 54 Z" fill="#1A1622"/>'
            + '<path d="M64 66 L70 80 H58 Z" fill="#1A1622"/>' + line('M48 96 V112 M64 96 V112 M80 96 V112', '#5B5347', 4))


@icon('megaphone')
def _(ic):
    return (shape(ic, 'M14 50 H40 L96 18 V110 L40 78 H14 Z', RED)
            + shape(ic, 'M96 16 Q114 64 96 112 Q86 64 96 16 Z', GOLD, 4)
            + shape(ic, 'M30 78 H48 L56 116 H40 Z', SILVER, 4) + shine(30, 56, 9, 4, 0, .5))


@icon('chaos')
def _(ic):
    return (shape(ic, 'M10 18 Q64 4 118 18 Q112 30 96 34 Q108 40 100 50 Q90 56 78 58 Q88 64 80 74 Q72 80 66 82 Q74 92 64 104 Q58 112 60 124 Q48 110 54 98 Q44 88 52 78 Q38 72 42 62 Q26 56 30 46 Q14 40 20 32 Q8 28 10 18 Z', SILVER)
            + line('M26 24 Q64 34 104 22 M38 44 Q64 52 92 42 M48 64 Q64 70 80 62', '#3A4250', 3.5))


@icon('hand')
def _(ic):
    return (shape(ic, 'M40 120 Q20 98 22 72 L24 56 Q26 48 32 50 Q38 52 38 60 L40 68 L40 24 Q40 16 48 16 Q56 16 56 24 V58 L58 14 Q58 6 66 6 Q74 6 74 14 V58 L78 20 Q78 12 86 12 Q94 12 94 22 V62 L98 36 Q100 28 106 30 Q112 32 110 42 L104 88 Q100 114 80 120 Z', SKIN)
            + line('M56 58 V72 M74 58 V72 M92 60 V74', '#B9805A', 3))


@icon('scales')
def _(ic):
    return (line('M64 18 V106', GOLD[3], 9) + line('M64 18 V106', '#F7C948', 5) + line('M20 34 H108', GOLD[3], 9) + line('M20 34 H108', '#F7C948', 5)
            + line('M20 34 L8 72 M20 34 L32 72 M108 34 L96 72 M108 34 L120 72', '#6E4606', 2.5)
            + shape(ic, 'M4 72 H36 Q36 88 20 88 Q4 88 4 72 Z', BLUE, 3.5) + shape(ic, 'M92 72 H124 Q124 88 108 88 Q92 88 92 72 Z', RED, 3.5)
            + shape(ic, 'M40 106 H88 V118 H40 Z', GOLD, 3.5) + circle(ic, 64, 16, 8, GOLD, 3))


def medal(ic, c, n):
    return (shape(ic, 'M36 6 H58 L64 44 L50 56 Z', RED, 3.5) + shape(ic, 'M92 6 H70 L64 44 L78 56 Z', BLUE, 3.5)
            + circle(ic, 64, 82, 38, c, 5, radial=True) + f'<circle cx="64" cy="82" r="28" fill="none" stroke="{c[3]}" stroke-width="3" opacity=".6"/>'
            + text(64, 100, n, 44, '#fff', c[3], 6) + shine(48, 64, 10, 5))


@icon('medal1')
def _(ic):
    return medal(ic, GOLD, '١')


@icon('medal2')
def _(ic):
    return medal(ic, SILVER, '٢')


@icon('medal3')
def _(ic):
    return medal(ic, BROWN, '٣')


# ═════════════ الردود (الكلام) ═════════════
@icon('suspect')
def _(ic):
    return (shape(ic, 'M8 70 Q60 18 112 70 Q60 122 8 70 Z', WHITE)
            + circle(ic, 60, 70, 22, ORANGE, 4, radial=True) + '<circle cx="60" cy="70" r="9" fill="#1A0B02"/>'
            + line('M14 34 Q50 14 96 30', '#3A2310', 9)
            + text(108, 46, '؟', 52, '#EF4B55', '#5E0812', 6))


@icon('trust')
def _(ic):
    return (shape(ic, 'M8 58 L34 40 L60 50 L74 44 Q82 42 86 48 L66 62 Q60 66 66 72 Q72 76 80 70 L98 58 L120 72 L100 100 L86 98 L70 110 Q62 116 54 108 L28 86 L8 82 Z', SKIN)
            + line('M36 82 L48 74 M44 92 L58 82 M54 100 L66 90', '#B9805A', 3)
            + shape(ic, 'M98 58 L120 72 L112 84 L92 68 Z', BLUE, 3) + shape(ic, 'M8 58 L34 40 L28 30 L4 46 Z', WHITE, 3))


@icon('liar')
def _(ic):
    return (shape(ic, 'M16 18 H112 Q120 18 120 26 V82 Q120 90 112 90 H60 L36 112 L40 90 H16 Q8 90 8 82 V26 Q8 18 16 18 Z', WHITE)
            + line('M44 34 L84 74 M84 34 L44 74', '#5E0812', 15) + line('M44 34 L84 74 M84 34 L44 74', '#EF4B55', 9))


@icon('pick')
def _(ic):
    return (shape(ic, 'M10 56 H70 Q80 56 80 64 Q80 70 72 72 H92 Q102 72 102 80 Q102 86 96 88 Q104 90 104 98 Q104 104 96 106 Q102 108 102 114 Q102 122 92 122 H42 Q20 122 16 100 L10 56 Z', SKIN)
            + shape(ic, 'M70 56 H112 Q122 56 122 64 Q122 72 112 72 H70 Z', SKIN, 4)
            + line('M72 88 H92 M72 104 H92', '#B9805A', 3))


@icon('innocent')
def _(ic):
    return (f'<ellipse cx="64" cy="18" rx="30" ry="9" fill="none" stroke="{GOLD[3]}" stroke-width="9"/>'
            + f'<ellipse cx="64" cy="18" rx="30" ry="9" fill="none" stroke="#FDE68A" stroke-width="5"/>'
            + shape(ic, 'M24 122 Q10 96 14 70 L18 46 Q20 38 26 40 Q32 42 32 50 L34 72 L36 40 Q36 32 42 32 Q48 32 48 40 V74 L52 36 Q52 28 58 28 Q64 28 64 36 V122 Z', SKIN, 4)
            + shape(ic, 'M104 122 Q118 96 114 70 L110 46 Q108 38 102 40 Q96 42 96 50 L94 72 L92 40 Q92 32 86 32 Q80 32 80 40 V74 L76 36 Q76 28 70 28 Q64 28 64 36 V122 Z', SKIN, 4))


# ═════════════ الطاولات (المستويات) ═════════════
@icon('tier_starter')
def _(ic):
    return (shape(ic, 'M60 118 Q58 90 64 64 Q70 90 68 118 Z', BROWN, 3.5)
            + shape(ic, 'M64 66 Q40 40 14 52 Q36 34 64 54 Z', GREEN, 3.5) + shape(ic, 'M64 66 Q88 40 114 52 Q92 34 64 54 Z', GREEN, 3.5)
            + shape(ic, 'M64 58 Q50 30 30 24 Q56 22 66 50 Z', GREEN, 3.5) + shape(ic, 'M64 58 Q78 30 98 24 Q72 22 62 50 Z', GREEN, 3.5)
            + shape(ic, 'M30 108 H98 V122 H30 Z', ('#E8C38F', '#B9834A', '#7A4E22', '#3A2310'), 3.5))


@icon('tier_city')
def _(ic):
    return (shape(ic, 'M10 56 H36 V120 H10 Z', SILVER) + shape(ic, 'M92 48 H118 V120 H92 Z', SILVER)
            + shape(ic, 'M44 120 V36 Q44 8 64 6 Q84 8 84 36 V120 Z', BLUE)
            + '<path d="M54 36 Q54 20 64 18 Q74 20 74 36 V44 H54 Z" fill="#0B2E6B"/>'
            + ''.join(f'<rect x="{x}" y="{y}" width="6" height="8" fill="#FDE68A"/>' for x in (16, 26, 98, 108) for y in (66, 82, 98))
            + ''.join(f'<rect x="{x}" y="{y}" width="7" height="9" fill="#FDE68A"/>' for x in (52, 68) for y in (58, 76, 94)))


@icon('tier_palace')
def _(ic):
    return (shape(ic, 'M14 68 H114 V120 H14 Z', WHITE) + shape(ic, 'M40 70 Q40 24 64 14 Q88 24 88 70 Z', GOLD)
            + shape(ic, 'M8 70 Q8 50 20 44 Q32 50 32 70 Z', GOLD, 3.5) + shape(ic, 'M96 70 Q96 50 108 44 Q120 50 120 70 Z', GOLD, 3.5)
            + line('M64 14 V2', '#6E4606', 4) + '<circle cx="64" cy="4" r="4" fill="#F7C948"/>'
            + shape(ic, 'M54 120 V96 Q54 84 64 84 Q74 84 74 96 V120 Z', BROWN, 3)
            + '<path d="M24 84 h12 v18 h-12 Z M92 84 h12 v18 h-12 Z" fill="#7DD3FC" stroke="#5B5347" stroke-width="3"/>' + shine(52, 40, 6, 12, 0, .45))


@icon('tier_kings')
def _(ic):
    return ICONS['crown'](ic)


@icon('tier_vip')
def _(ic):
    return ICONS['gem'](ic) + shape(ic, 'M14 86 H114 L108 100 L114 114 H14 L20 100 Z', RED, 4) + text(64, 108, 'VIP', 22, '#fff', '#5E0812', 4, 'Tajawal', 'bold')


# ═════════════ رموز الكروت ═════════════
def emblem(body):
    return f'<g>{body}</g>'


@icon('card_shield')
def _(ic):
    return ICONS['shield'](ic)


@icon('card_dagger')
def _(ic):
    return ICONS['dagger'](ic)


@icon('card_crown')
def _(ic):
    return ICONS['crown'](ic)


@icon('card_palm')
def _(ic):
    return (shape(ic, 'M58 120 Q54 84 62 54 L70 54 Q66 84 70 120 Z', BROWN, 4)
            + ''.join(shape(ic, d, GREEN, 3.5) for d in (
                'M66 54 Q40 28 8 40 Q36 38 64 60 Z', 'M66 54 Q92 28 120 40 Q92 38 64 60 Z',
                'M66 52 Q54 18 26 10 Q56 16 70 54 Z', 'M66 52 Q78 18 106 10 Q76 16 62 54 Z',
                'M66 54 Q46 50 24 76 Q48 58 66 60 Z', 'M66 54 Q86 50 108 76 Q84 58 66 60 Z'))
            + '<circle cx="58" cy="60" r="6" fill="#B9834A" stroke="#3A2310" stroke-width="2.5"/><circle cx="72" cy="62" r="6" fill="#B9834A" stroke="#3A2310" stroke-width="2.5"/>')


@icon('card_scorpion')
def _(ic):
    return (shape(ic, 'M48 60 Q64 48 80 60 Q86 78 64 88 Q42 78 48 60 Z', ORANGE)
            + line('M64 88 Q64 104 80 112 Q102 118 104 98 Q104 84 92 82', '#6E2B03', 10) + line('M64 88 Q64 104 80 112 Q102 118 104 98 Q104 84 92 82', '#FF9A3D', 5)
            + shape(ic, 'M92 82 L102 70 L98 88 Z', RED, 3)
            + line('M50 58 Q30 44 26 26 M78 58 Q98 44 102 26', '#6E2B03', 8) + line('M50 58 Q30 44 26 26 M78 58 Q98 44 102 26', '#FF9A3D', 4)
            + shape(ic, 'M14 26 Q20 12 30 22 L26 30 Z', ORANGE, 3) + shape(ic, 'M114 26 Q108 12 98 22 L102 30 Z', ORANGE, 3)
            + line('M50 70 L30 76 M50 78 L32 88 M78 70 L98 76 M78 78 L96 88', '#6E2B03', 4))


@icon('card_moon')
def _(ic):
    return shape(ic, 'M80 10 Q36 16 32 62 Q32 112 82 118 Q58 104 56 64 Q56 24 80 10 Z', GOLD) + shine(46, 44, 5, 14, 10, .45)


@icon('card_crescent')
def _(ic):
    return (shape(ic, 'M76 8 Q28 14 26 64 Q28 114 76 120 Q48 104 48 64 Q48 24 76 8 Z', GOLD)
            + shape(ic, 'M92 46 L96 58 L108 60 L98 68 L102 80 L92 72 L82 80 L86 68 L76 60 L88 58 Z', GOLD, 3))


@icon('card_eclipse')
def _(ic):
    return (f'<circle cx="64" cy="64" r="50" fill="#FDE68A" opacity=".5"/>' + circle(ic, 64, 64, 42, GOLD, 4)
            + f'<circle cx="74" cy="56" r="38" fill="{ic.rg(PURPLE)}" stroke="#2A0F66" stroke-width="4"/>')


@icon('card_wolf')
def _(ic):
    return (shape(ic, 'M20 10 L44 40 Q64 32 84 40 L108 10 L104 58 Q114 74 98 92 L64 120 L30 92 Q14 74 24 58 Z', SILVER)
            + shape(ic, 'M30 22 L44 42 L36 50 Z M98 22 L84 42 L92 50 Z', PINK, 2.5)
            + '<path d="M38 66 L56 70 L50 78 Z M90 66 L72 70 L78 78 Z" fill="#FDE047" stroke="#1A1622" stroke-width="2.5"/>'
            + shape(ic, 'M52 96 Q64 88 76 96 L64 110 Z', DARK, 3))


@icon('card_dragon')
def _(ic):
    return (shape(ic, 'M14 70 Q24 30 64 26 Q98 24 112 46 L96 54 L110 62 Q96 70 84 66 L74 84 Q60 104 34 100 L44 88 Q26 90 14 70 Z', GREEN)
            + shape(ic, 'M50 28 L44 8 L60 26 Z M72 26 L76 6 L84 28 Z', GOLD, 3)
            + '<circle cx="84" cy="44" r="6" fill="#FDE047" stroke="#1A1622" stroke-width="2.5"/>'
            + shape(ic, 'M110 62 Q124 66 122 80 Q116 70 104 70 Z', ORANGE, 3))


@icon('card_flame')
def _(ic):
    return ICONS['fire'](ic)


def svg(body, defs):
    sh = ('<filter id="sh" x="-20%" y="-20%" width="140%" height="140%"><feGaussianBlur in="SourceAlpha" stdDeviation="3"/>'
          '<feOffset dx="0" dy="4" result="o"/><feComponentTransfer in="o" result="s"><feFuncA type="linear" slope=".45"/></feComponentTransfer>'
          '<feMerge><feMergeNode in="s"/><feMergeNode in="SourceGraphic"/></feMerge></filter>')
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="-4 -4 136 136"><defs>{"".join(defs)}{sh}</defs>'
            f'<g filter="url(#sh)">{body}</g></svg>')


def render(name):
    ic = Icon()
    body = ICONS[name](ic)
    path = os.path.join(SRC, f'{name}.svg')
    open(path, 'w').write(svg(body, ic.defs))
    out = os.path.join(OUT, f'gfx_{name}.png')
    subprocess.run(['inkscape', path, '-o', out, '-w', '256', '-h', '256'], check=True, capture_output=True)
    return name


if __name__ == '__main__':
    os.makedirs(SRC, exist_ok=True)
    os.makedirs(OUT, exist_ok=True)
    names = [n for n in ICONS if not ONLY or n in ONLY]
    with ThreadPoolExecutor(6) as ex:
        done = list(ex.map(render, names))
    print(len(done), 'icons')
