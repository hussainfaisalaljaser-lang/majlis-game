"""شخصيات المتجر المميزة، بنفس أسلوب avatars.py مع إضافات: بشت، صقر، تاج، مكبّر، قناع."""
import os, subprocess, sys
OUT = sys.argv[1]
HERE = os.path.dirname(os.path.abspath(__file__))
src = open(os.path.join(HERE, 'avatars.py')).read()
exec(src[src.index('SKIN ='):src.index('CHARACTERS =')])

def bisht(trim='#E8B04B', color='#15121A'):
    return (thobe() +
            f'<path d="M26 200 Q30 160 66 146 L88 200 Z M174 200 Q170 160 134 146 L112 200 Z" fill="{color}"/>'
            f'<path d="M66 146 L88 200 M134 146 L112 200" stroke="{trim}" stroke-width="5"/>'
            f'<path d="M66 146 L88 200 M134 146 L112 200" stroke="#FFF3C4" stroke-width="1.2" stroke-dasharray="3 3"/>')

def falcon_bird():
    return ('<g transform="translate(150 150) scale(.9)">'
            '<path d="M-14 22 Q-22 -4 -6 -22 Q8 -32 18 -20 Q26 -6 20 14 Q12 30 -14 22 Z" fill="#8A6A4A"/>'
            '<path d="M-6 -20 Q4 -40 18 -30 Q24 -24 22 -16 Q12 -24 -6 -20 Z" fill="#6B4E33"/>'
            '<circle cx="12" cy="-24" r="2.6" fill="#111"/><circle cx="12.8" cy="-24.8" r=".8" fill="#fff"/>'
            '<path d="M20 -22 L28 -18 L21 -15 Z" fill="#F2C14E"/>'
            '<path d="M-10 0 Q0 6 14 0 M-12 8 Q0 14 14 8" stroke="#5A4028" stroke-width="2" fill="none"/>'
            '<path d="M-20 26 H24" stroke="#3D2B1F" stroke-width="6" stroke-linecap="round"/></g>')

def tiara():
    return ('<path d="M74 70 Q100 58 126 70 L122 78 Q100 68 78 78 Z" fill="#F2C14E"/>'
            '<path d="M88 66 L92 56 L96 64 L100 50 L104 64 L108 56 L112 66" fill="#F2C14E" stroke="#B87A12" stroke-width="1"/>'
            '<circle cx="100" cy="58" r="3.5" fill="#E03131"/><circle cx="92" cy="62" r="2" fill="#4DABF7"/><circle cx="108" cy="62" r="2" fill="#4DABF7"/>')

def necklace():
    return ''.join(f'<circle cx="{100 + x}" cy="{156 + (x * x) / 90:.1f}" r="3.2" fill="#FFF8E7" stroke="#D9C9A8" stroke-width=".6"/>' for x in range(-24, 25, 8))

def magnifier():
    return ('<g transform="translate(146 156) rotate(-30)">'
            '<rect x="-4" y="14" width="8" height="30" rx="3" fill="#5A3A22"/>'
            '<circle r="17" fill="#BDE7FF" fill-opacity=".45" stroke="#C9A227" stroke-width="5"/>'
            '<path d="M-8 -6 Q-4 -12 4 -12" stroke="#fff" stroke-width="2.5" fill="none" stroke-linecap="round"/></g>')

def assassin():
    return (thobe('#141218', '#24212B') + face('tan', brows='sly') +
            '<path d="M58 106 Q54 62 100 56 Q146 62 142 106 L150 168 Q132 150 126 118 Q122 84 100 82 Q78 84 74 118 Q68 150 50 168 Z" fill="#141218"/>'
            '<path d="M66 108 Q100 102 134 108 L134 152 Q100 164 66 152 Z" fill="#141218"/>'
            '<path d="M66 88 Q100 78 134 88 L134 96 Q100 86 66 96 Z" fill="#141218"/>'
            '<ellipse cx="88" cy="103" rx="6" ry="3.2" fill="#FF2B2B"/><ellipse cx="112" cy="103" rx="6" ry="3.2" fill="#FF2B2B"/>'
            '<ellipse cx="88" cy="103" rx="11" ry="7" fill="#FF2B2B" opacity=".25"/><ellipse cx="112" cy="103" rx="11" ry="7" fill="#FF2B2B" opacity=".25"/>'
            '<g transform="translate(150 170) rotate(-35)"><path d="M0 -40 Q8 -20 4 0 L-4 0 Q-8 -20 0 -40 Z" fill="#D7DCE3"/>'
            '<rect x="-10" y="0" width="20" height="5" rx="2" fill="#C9A227"/><rect x="-3.5" y="5" width="7" height="18" rx="2" fill="#5A3A22"/></g>')

def sultana():
    veil = '#2A0F3D'
    return (abaya('#1C0B28') + hijab(veil, '#F2C14E') + face('tan', ears=False, brows='sly') + hijab_front(veil) +
            f'<path d="M71 112 Q100 108 129 112 L126 152 Q100 164 74 152 Z" fill="{veil}"/>'
            '<path d="M71 112 Q100 108 129 112" stroke="#F2C14E" stroke-width="3" fill="none"/>'
            + ''.join(f'<circle cx="{78 + i * 7}" cy="{114 + (abs(i - 3.5) < 2) * 1}" r="1.8" fill="#F2C14E"/>' for i in range(8)) +
            '<path d="M100 74 L100 86" stroke="#F2C14E" stroke-width="2"/><circle cx="100" cy="88" r="3" fill="#E03131" stroke="#F2C14E"/>')

PREMIUM = {
    'emir': ('#F2C14E', '#7A4E00', bisht() + face('light', beard='full', beard_color='grey') + ghutra()),
    'falconer': ('#8C6D46', '#3A2A16', thobe('#E8DCC4') + face('tan', beard='full') + ghutra('red') + falcon_bird()),
    'lady_gold': ('#E64980', '#5C0F2E', abaya('#2A1220') + hijab('#F8F0E3', '#F2C14E') + face('light', ears=False) + hijab_front('#F8F0E3') + tiara() + necklace()),
    'detective': ('#495C83', '#1B2440', thobe('#3C3A45', '#55525F') + face('brown', beard='goatee', brows='sly') + ghutra() + magnifier()),
    'assassin': ('#5E0B0B', '#120202', assassin()),
    'sultana': ('#9C36B5', '#2B0A3D', sultana()),
}
svgdir = os.path.join(HERE, 'avatars'); os.makedirs(svgdir, exist_ok=True)
for name, (b1, b2, body) in PREMIUM.items():
    p = os.path.join(svgdir, f'{name}.svg')
    open(p, 'w').write(wrap(b1, b2, body))
    subprocess.run(['inkscape', p, '-o', os.path.join(OUT, f'{name}.png'), '-w', '256', '-h', '256'], check=True, capture_output=True)
print(len(PREMIUM), 'premium')
