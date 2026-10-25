"""ختم زعيم الخونة: ختم الخونة وتاج صغير مائل راكب على حافته فوق يمين، والخنجر يبان (صورة وحدة)."""
import io, sys
import cairosvg
from PIL import Image, ImageFilter
TW, SEAL, OUT = sys.argv[1], sys.argv[2], sys.argv[3]
S = 512
seal = Image.open(SEAL).convert('RGBA').resize((420, 420), Image.LANCZOS)
crown = Image.open(io.BytesIO(cairosvg.svg2png(url=TW, output_width=180, output_height=180))).convert('RGBA')
crown = crown.rotate(-16, resample=Image.BICUBIC, expand=True)
canvas = Image.new('RGBA', (S, S), (0, 0, 0, 0))
canvas.alpha_composite(seal, ((S - 420) // 2 - 20, S - 420))
# ظل التاج على الختم عشان يبان إنه راكب عليه
shadow = Image.new('RGBA', crown.size, (0, 0, 0, 0))
shadow.putalpha(crown.getchannel('A').point(lambda a: a * .55).filter(ImageFilter.GaussianBlur(6)))
x, y = 228, 8
canvas.alpha_composite(shadow, (x + 6, y + 12))
canvas.alpha_composite(crown, (x, y))
canvas.resize((256, 256), Image.LANCZOS).save(OUT, optimize=True)
