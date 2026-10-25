"""أشكال الطاولات: سجادة عريضة وصينية لكل شكل، بدقة عالية (WebP).
تشغيل:  python3 tools/art/tables.py app/assets/tables"""
import os, subprocess, sys, math
from PIL import Image
OUT = sys.argv[1]
SRC = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'svg')
os.makedirs(SRC, exist_ok=True); os.makedirs(OUT, exist_ok=True)

def render(name, svg, w, h):
    path = os.path.join(SRC, f'{name}.svg')
    open(path, 'w').write(svg)
    png = os.path.join(OUT, f'{name}.png')
    subprocess.run(['inkscape', path, '-o', png, '-w', str(w), '-h', str(h)], check=True, capture_output=True)
    # WebP: أصغر بكثير من PNG وبدون خطوط في التدرج.
    Image.open(png).convert('RGBA').save(png[:-4] + '.webp', quality=86, method=6)
    os.remove(png)

THEMES = {
    'majlis': (('#A3303F', '#6E1A2B', '#46101D'), '#E8B04B', '#E9D6A8', 'diamond', 'brass'),
    's1':     (('#16656B', '#0D3B45', '#061E28'), '#FCD34D', '#E9D6A8', 'crescent', 'gold'),
    # id: (rug stops, accent, fringe, motif, tray)
    'sand':   (('#E3C590', '#C79A5B', '#8E6534'), '#6B3F1A', '#F5E6C4', 'diamond', 'copper'),
    'oasis':  (('#2F9E6E', '#1B6B4A', '#0E3F2B'), '#F2C14E', '#E9D6A8', 'palm', 'brass'),
    'night':  (('#2D3A8C', '#1A2260', '#0C1236'), '#C9D6F2', '#D6DEEE', 'stars', 'silver'),
    'palace': (('#7B3FB8', '#4E2280', '#2A0F4D'), '#F2C14E', '#EBD9FF', 'arch', 'gold'),
    'gold':   (('#2B2620', '#16130F', '#050403'), '#E8B04B', '#E8C77A', 'sun', 'gold'),
}
TRAYS = {
    'brass':  ('#B8862E', '#F7D88A', '#D9A845', '#9C6A1C', '#FFF3C4'),
    'copper': ('#9A4E24', '#F2A878', '#C66A3A', '#7A3714', '#FFD9C2'),
    'silver': ('#7E8796', '#F4F7FB', '#C4CBD6', '#6B7484', '#FFFFFF'),
    'gold':   ('#C99A1E', '#FFF1B8', '#F2C94C', '#A67A0A', '#FFFBE6'),
}
W, H = 1200, 600

def motif(kind, a):
    g = f'<g transform="translate({W/2} {H/2})" fill="none" stroke="{a}" stroke-width="3" opacity=".85">'
    if kind == 'diamond':
        g += ('<path d="M0 -190 L120 -60 L380 0 L120 60 L0 190 L-120 60 L-380 0 L-120 -60 Z"/>'
              '<path d="M0 -150 L90 -45 L300 0 L90 45 L0 150 L-90 45 L-300 0 L-90 -45 Z" opacity=".6"/>'
              '<ellipse rx="230" ry="128"/><ellipse rx="244" ry="138" opacity=".5"/>')
    elif kind == 'palm':
        g += '<ellipse rx="240" ry="136"/><ellipse rx="256" ry="148" opacity=".5"/>'
        for sx in (-1, 1):
            x = sx * 330
            g += f'<path d="M{x} 120 Q{x+sx*6} 40 {x} -40" stroke-width="6"/>'
            for ang in (-70, -35, 0, 35, 70, 110, 145):
                r = math.radians(ang - 90)
                g += f'<path d="M{x} -40 Q{x+math.cos(r)*40} {-40+math.sin(r)*30-14} {x+math.cos(r)*70} {-40+math.sin(r)*55}" stroke-width="4"/>'
        g += '<path d="M0 -170 L60 0 L0 170 L-60 0 Z" opacity=".6"/>'
    elif kind == 'stars':
        g += '<ellipse rx="236" ry="132"/><ellipse rx="250" ry="142" opacity=".5"/>'
        g += '<path d="M40 -60 A70 70 0 1 0 40 60 A56 56 0 1 1 40 -60 Z" fill="' + a + '" opacity=".9"/>'
        import random; random.seed(7)
        for _ in range(46):
            x, y = random.uniform(-470, 470), random.uniform(-200, 200)
            if (x/250)**2 + (y/142)**2 < 1.1: continue
            r = random.choice((2, 2.5, 3.5))
            g += f'<circle cx="{x:.0f}" cy="{y:.0f}" r="{r}" fill="{a}" stroke="none"/>'
        for x, y in ((-380, -150), (360, 140), (420, -120), (-300, 160)):
            g += f'<path d="M{x} {y-14} L{x+4} {y-4} L{x+14} {y} L{x+4} {y+4} L{x} {y+14} L{x-4} {y+4} L{x-14} {y} L{x-4} {y-4} Z" fill="{a}" stroke="none"/>'
    elif kind == 'arch':
        g += '<ellipse rx="236" ry="132"/><ellipse rx="250" ry="142" opacity=".5"/>'
        for i in range(-4, 5):
            if abs(i) < 2: continue
            x = i * 105
            g += f'<path d="M{x-34} 130 V-40 Q{x-34} -110 {x} -140 Q{x+34} -110 {x+34} -40 V130" stroke-width="3"/>'
        g += '<path d="M0 -180 L40 -40 L180 0 L40 40 L0 180 L-40 40 L-180 0 L-40 -40 Z" opacity=".7"/>'
    elif kind == 'crescent':
        g += '<ellipse rx="236" ry="132"/><ellipse rx="250" ry="142" opacity=".5"/>'
        for sx in (-1, 1):
            x = sx * 340
            g += (f'<path d="M{x + 22} -60 Q{x - 40} -50 {x - 40} 0 Q{x - 36} 52 {x + 22} 60 Q{x - 14} 36 {x - 14} 0 Q{x - 14} -36 {x + 22} -60 Z" '
                  f'fill="{a}" stroke="none" opacity=".9"/>')
        import random; random.seed(11)
        for _ in range(40):
            x, y = random.uniform(-470, 470), random.uniform(-200, 200)
            if (x / 250) ** 2 + (y / 142) ** 2 < 1.15 or abs(abs(x) - 340) < 70: continue
            r = random.choice((2, 2.5, 3))
            g += f'<circle cx="{x:.0f}" cy="{y:.0f}" r="{r}" fill="{a}" stroke="none"/>'
        for x, y in ((-230, -170), (230, 170), (0, -185), (0, 185)):
            g += f'<path d="M{x} {y - 12} L{x + 4} {y - 4} L{x + 12} {y} L{x + 4} {y + 4} L{x} {y + 12} L{x - 4} {y + 4} L{x - 12} {y} L{x - 4} {y - 4} Z" fill="{a}" stroke="none"/>'
    elif kind == 'sun':
        g += '<ellipse rx="236" ry="132" stroke-width="4"/><ellipse rx="252" ry="144" opacity=".5"/>'
        for i in range(32):
            r = math.radians(i * 360 / 32)
            r1, r2 = (270, 330) if i % 2 == 0 else (270, 300)
            g += f'<path d="M{math.cos(r)*r1*1.55:.0f} {math.sin(r)*r1*.72:.0f} L{math.cos(r)*r2*1.55:.0f} {math.sin(r)*r2*.72:.0f}" stroke-width="3"/>'
        g += '<path d="M0 -150 L90 -45 L300 0 L90 45 L0 150 L-90 45 L-300 0 L-90 -45 Z" opacity=".6"/>'
    g += '<path d="M-430 0 H-400 M400 0 H430" stroke-width="5"/></g>'
    return g

for tid, (stops, a, fr, kind, tray) in THEMES.items():
    fringe = ''.join(f'<line x1="{x}" y1="{y}" x2="{x+dx}" y2="{y}" stroke="{fr}" stroke-width="3" stroke-linecap="round" opacity=".9"/>'
                     for y in range(70, H-60, 11) for (x, dx) in ((40, -26), (W-40, 26)))
    def corner(cx, cy, rot):
        return (f'<g transform="translate({cx} {cy}) rotate({rot})" fill="none" stroke="{a}" stroke-width="3" opacity=".9">'
                f'<path d="M0 0 L60 0 Q40 20 40 40 Q20 40 0 60 Z"/><circle cx="18" cy="18" r="6" fill="{a}"/></g>')
    corners = corner(96, 86, 0) + corner(W-96, 86, 90) + corner(W-96, H-86, 180) + corner(96, H-86, 270)
    beads = ''.join(f'<circle cx="{120+i*40}" cy="78" r="4"/><circle cx="{120+i*40}" cy="{H-78}" r="4"/>' for i in range(25))
    gold = f'<linearGradient id="gold" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FFFFFF" stop-opacity=".9"/><stop offset=".25" stop-color="{a}"/><stop offset="1" stop-color="{a}" stop-opacity=".7"/></linearGradient>'
    render(f'carpet_{tid}', f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="-30 0 {W+60} {H}">
<defs>{gold}
<radialGradient id="rug" cx="50%" cy="50%" r="60%"><stop offset="0" stop-color="{stops[0]}"/><stop offset=".7" stop-color="{stops[1]}"/><stop offset="1" stop-color="{stops[2]}"/></radialGradient>
<pattern id="dots" width="18" height="18" patternUnits="userSpaceOnUse"><circle cx="9" cy="9" r="1.5" fill="{a}" opacity=".3"/></pattern>
<pattern id="band" width="28" height="28" patternUnits="userSpaceOnUse"><path d="M0 14 L14 0 L28 14 L14 28 Z" fill="none" stroke="{a}" stroke-width="2" opacity=".55"/></pattern>
</defs>
{fringe}
<rect x="40" y="20" width="{W-80}" height="{H-40}" rx="26" fill="#000" opacity=".35" transform="translate(0 8)"/>
<rect x="40" y="20" width="{W-80}" height="{H-40}" rx="26" fill="url(#rug)"/>
<rect x="40" y="20" width="{W-80}" height="{H-40}" rx="26" fill="url(#dots)"/>
<rect x="52" y="32" width="{W-104}" height="{H-64}" rx="20" fill="none" stroke="url(#gold)" stroke-width="7"/>
<rect x="66" y="46" width="{W-132}" height="{H-92}" rx="14" fill="none" stroke="url(#band)" stroke-width="22"/>
<rect x="80" y="60" width="{W-160}" height="{H-120}" rx="10" fill="none" stroke="{a}" stroke-width="2.5" stroke-dasharray="12 9"/>
<g fill="{a}" opacity=".85">{beads}</g>
{corners}
{motif(kind, a)}
</svg>''', 2400, 600*2400//1260)
    rim, hi, mid, lo, shine = TRAYS[tray]
    render(f'tray_{tid}', f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 320 200">
<defs><radialGradient id="m" cx="40%" cy="35%" r="70%"><stop offset="0" stop-color="{hi}"/><stop offset=".6" stop-color="{mid}"/><stop offset="1" stop-color="{lo}"/></radialGradient></defs>
<ellipse cx="160" cy="106" rx="154" ry="92" fill="#000" opacity=".35"/>
<ellipse cx="160" cy="100" rx="154" ry="92" fill="{rim}"/>
<ellipse cx="160" cy="100" rx="144" ry="84" fill="url(#m)"/>
<ellipse cx="160" cy="100" rx="132" ry="74" fill="none" stroke="{lo}" stroke-width="2.5"/>
<ellipse cx="160" cy="100" rx="125" ry="68" fill="none" stroke="{shine}" stroke-width="1.2" opacity=".6"/>
</svg>''', 1100, 688)
print('ok')
