"""مؤثرات صوت لحظات الطاولة (كشف الدور، التصويت، تمرير القرار، الطرد، نهاية اللعبة).
مولّدة بالكود (موجات وضجيج مفلتر)، ما فيها أي تسجيل خارجي، فما فيها حقوق. تطلع ملفات wav صغيرة (٢٢ كيلو، مونو).

التشغيل:   python -I tools/sfx/make_sfx.py            (يكتب في app/assets/sfx)
معاينة:    python -I tools/sfx/make_sfx.py --sheet out.png   (صورة أطياف الأصوات للفحص بالعين)

كل صوت دالة تعيد مصفوفة؛ SOUNDS في الأسفل يربط الاسم بالدالة. اسم الملف هو اسم الصوت في lib/services/sounds.dart.
"""

import os
import sys
import wave

import numpy as np

SR = 22050
rng = np.random.default_rng(11)

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "app", "assets", "sfx")


# ───────── أدوات

def tt(d):
    return np.arange(int(SR * d)) / SR


def noise(d):
    return rng.uniform(-1, 1, int(SR * d))


def lowpass(x, fc):
    fc = np.broadcast_to(np.asarray(fc, dtype=float), x.shape)
    a = 1 - np.exp(-2 * np.pi * fc / SR)
    y = np.empty_like(x)
    s = 0.0
    for i in range(len(x)):
        s += a[i] * (x[i] - s)
        y[i] = s
    return y


def highpass(x, fc):
    return x - lowpass(x, fc)


def bandpass(x, fc, q=2.0):
    """مرشح حالة متغير: [fc] ثابت أو مصفوفة (يتحرك مع الوقت)."""
    fc = np.broadcast_to(np.asarray(fc, dtype=float), x.shape)
    f = 2 * np.sin(np.pi * np.minimum(fc, SR * 0.4) / SR)
    damp = 1.0 / q
    low = band = 0.0
    y = np.empty_like(x)
    for i in range(len(x)):
        low += f[i] * band
        high = x[i] - low - damp * band
        band += f[i] * high
        y[i] = band
    return y


def sweep(a, b, t, curve=1.0):
    """يتحرك من [a] لـ[b] على طول [t] (curve>1: سريع بالأول)."""
    u = np.clip(t / t[-1], 0, 1) ** (1.0 / curve)
    return a * (b / a) ** u


def sine(f, t, phase=0.0):
    f = np.broadcast_to(np.asarray(f, dtype=float), t.shape)
    return np.sin(2 * np.pi * np.cumsum(f) / SR + phase)


def ex(t, tau):
    return np.exp(-t / tau)


def rise(t, a):
    return np.clip(t / a, 0, 1)


def bell_env(t):
    return np.sin(np.pi * np.clip(t / t[-1], 0, 1)) ** 2


def place(out, x, at, gain=1.0):
    i = int(at * SR)
    if i >= len(out):
        return
    n = min(len(x), len(out) - i)
    out[i:i + n] += x[:n] * gain


def echo(x, taps):
    out = np.zeros(len(x) + int(max(d for d, _ in taps) * SR) + 1)
    out[:len(x)] += x
    for d, g in taps:
        place(out, x, d, g)
    return out[:len(x)]


def finish(x, peak=0.9):
    x = np.asarray(x, dtype=float)
    # بداية ونهاية ناعمة عشان ما يطلع طقطقة
    n_in, n_out = int(.002 * SR), int(.03 * SR)
    x[:n_in] *= np.linspace(0, 1, n_in)
    x[-n_out:] *= np.linspace(1, 0, n_out)
    m = np.max(np.abs(x))
    return x / m * peak if m > 0 else x


def harm(f, t, parts):
    """موجة من توافقيات: parts = [(نسبة التردد، القوة)]."""
    return sum(g * sine(f * r, t) for r, g in parts)


# ───────── الأصوات

def whoosh():
    t = tt(.5)
    x = bandpass(noise(.5), sweep(350, 3200, t), q=1.6)
    return finish(x * bell_env(t) ** .8, .8)


def flip():
    t = tt(.3)
    x = bandpass(noise(.3), sweep(900, 2600, t), q=2.2) * np.sin(np.pi * np.clip(t / .22, 0, 1)) ** 1.5 * .9
    tick = highpass(noise(.3), 2500) * ex(t - .18, .006) * (t > .18) * .6
    tick += sine(1700, t) * ex(t - .18, .012) * (t > .18) * .35
    return finish(x + tick, .8)


def drum(f0=165.0, d=.45):
    t = tt(d)
    f = f0 * (1 + .9 * ex(t, .035))
    body = sine(f, t) * ex(t, .13) + .35 * sine(f * 1.58, t) * ex(t, .07)
    click = lowpass(noise(d), 2200) * ex(t, .012) * .7
    return finish(body + click, .95)


def yes():
    t = tt(1.1)
    out = np.zeros_like(t)
    for at, f in [(0, 659.3), (.09, 830.6), (.18, 987.8), (.3, 1318.5)]:
        u = t[: len(t) - int(at * SR)]
        note = (sine(f, u) * 1 + .45 * sine(f * 2.01, u) * ex(u, .25) + .2 * sine(f * 3.02, u) * ex(u, .15)) * ex(u, .55)
        place(out, note * rise(u, .004), at, 1.0 if at < .3 else 1.2)
    return finish(echo(out, [(.06, .25), (.13, .14)]), .85)


def no():
    t = tt(.75)
    out = np.zeros_like(t)
    for at, f, d in [(0, 135, .3), (.32, 100, .4)]:
        u = tt(d)
        saw = harm(f * (1 - .12 * u / d), u, [(k, 1 / k) for k in range(1, 9)])
        env = rise(u, .01) * ex(u, d * .8)
        trem = .75 + .25 * np.sin(2 * np.pi * 16 * u)
        place(out, lowpass(saw, 1400) * env * trem, at, .9)
    return finish(out, .85)


def stamp():
    t = tt(.5)
    f = 230 * (60 / 230) ** np.clip(t / .12, 0, 1)
    body = (sine(f, t) + .55 * sine(f * 2.1, t)) * ex(t, .1)
    thump = lowpass(noise(.5), 1700) * ex(t, .035) * 1.0
    crack = highpass(noise(.5), 2500) * ex(t, .008) * .85
    return finish(body + thump + crack, .95)


def thud_red():
    t = tt(.9)
    f = 95 * (30 / 95) ** np.clip(t / .25, 0, 1)
    body = (sine(f, t) + .6 * sine(f * 2.4, t)) * ex(t, .2) * 1.1
    ring = (sine(222, t) * .45 + sine(351, t) * .35 + sine(497, t) * .22) * ex(t, .3)
    rumble = lowpass(noise(.9), 280) * ex(t, .3) * .9
    crack = highpass(noise(.9), 2500) * ex(t, .01) * .7
    return finish(body + ring + rumble + crack, .95)


def crack():
    t = tt(.7)
    out = np.zeros_like(t)
    for at, g, tau in [(0, 1, .02), (.07, .7, .015), (.15, .9, .025), (.24, .5, .012), (.38, .8, .03)]:
        u = tt(.2)
        place(out, highpass(noise(.2), 1800) * ex(u, tau), at, g)
        place(out, sine(sweep(260, 90, u), u) * ex(u, .05) * .6, at, g)
    return finish(out, .9)


def shatter():
    t = tt(1.2)
    out = highpass(noise(1.2), 1500) * ex(t, .05) * .9 + lowpass(noise(1.2), 2500) * ex(t, .18) * .5
    for _ in range(34):
        at = rng.uniform(0, .4)
        f = rng.uniform(2400, 7600)
        u = tt(.5)
        ping = sine(f, u) * ex(u, rng.uniform(.05, .22)) * rng.uniform(.08, .3)
        place(out, ping, at)
    return finish(out, .9)


def lamp_out():
    t = tt(1.0)
    hiss = lowpass(noise(1.0), sweep(3500, 200, t)) * rise(t, .03) * ex(t, .35)
    fall = sine(sweep(650, 70, t), t) * ex(t, .3) * .35
    fizz = np.zeros_like(t)
    for _ in range(14):
        at = rng.uniform(0, .6)
        u = tt(.04)
        place(fizz, highpass(noise(.04), 3000) * ex(u, .008), at, rng.uniform(.2, .5))
    return finish(hiss + fall + fizz, .85)


def shield():
    t = tt(1.1)
    ring = sum(
        g * sine(523 * r, t) * ex(t, tau)
        for r, g, tau in [(1, 1, .6), (1.5, .5, .5), (2.0, .4, .4), (2.74, .3, .3), (3.76, .2, .2), (5.4, .1, .12)]
    )
    attack = bandpass(noise(1.1), sweep(500, 3000, t), q=2) * ex(t, .09) * .7
    return finish(echo(ring * .7 + attack, [(.07, .22), (.15, .12)]), .85)


def heartbeat():
    t = tt(.75)
    out = np.zeros_like(t)
    for at, g in [(0, 1), (.2, .75)]:
        u = tt(.3)
        beat = (sine(sweep(170, 70, u), u) + .8 * sine(sweep(340, 140, u), u) * ex(u, .05) + .4 * sine(sweep(75, 40, u), u)) * ex(u, .08) + lowpass(noise(.3), 1000) * ex(u, .03) * .7
        place(out, beat, at, g)
    return finish(out, .9)


def _chord(freqs, t, gain=1.0, parts=((1, 1), (2, .35), (3, .15))):
    return sum(harm(f, t, list(parts)) for f in freqs) * gain / len(freqs)


def sting_traitor():
    t = tt(2.0)
    pad = _chord([110, 220, 311.1, 329.6, 466.2], t, parts=((1, 1), (2, .6), (3, .45), (4, .3), (5, .2)))
    pad = lowpass(pad, 1800)
    vib = 1 + .02 * np.sin(2 * np.pi * 5.5 * t)
    boom = (sine(sweep(170, 55, t), t) * ex(t, .3) + .6 * sine(sweep(70, 38, t), t) * ex(t, .4)) * 1.1
    swell = rise(t, .35) * ex(t, 1.0)
    return finish(echo(pad * swell * vib + boom, [(.1, .3), (.22, .18)]), .92)


def sting_loyal():
    t = tt(1.7)
    pad = _chord([261.6, 329.6, 392, 587.3], t, 1.0) * rise(t, .04) * ex(t, .8)
    out = pad.copy()
    for at, f in [(.05, 1046.5), (.13, 1318.5), (.21, 1568), (.3, 2093)]:
        u = t[: len(t) - int(at * SR)]
        place(out, (sine(f, u) + .3 * sine(f * 2, u)) * ex(u, .5) * .35, at)
    return finish(echo(out, [(.06, .3), (.14, .18)]), .88)


def _brass(f, d):
    u = tt(d)
    x = harm(f, u, [(k, 1 / k) for k in range(1, 8)])
    x = lowpass(x, sweep(500, 2600, u + 1e-6, curve=2))
    return x * rise(u, .03) * np.clip((d - u) / .06, 0, 1)


def sting_leader():
    out = np.zeros(int(SR * 2.2))
    for at, f, d in [(0, 196, .2), (.2, 261.6, .2), (.4, 329.6, .2), (.6, 392, 1.4)]:
        place(out, _brass(f, d), at)
    for f in (523, 659, 784):
        place(out, _brass(f, 1.3) * .5, .6)
    u = tt(1.5)
    place(out, highpass(noise(1.5), 4500) * ex(u, .5) * .35, .6)
    place(out, sine(sweep(110, 45, u), u) * ex(u, .3) * 1.0, .6)
    return finish(echo(out, [(.08, .25), (.18, .12)]), .9)


def win():
    t = tt(2.6)
    out = np.zeros_like(t)
    for i, f in enumerate([523, 659, 784, 1046, 1318, 1568]):
        u = tt(1.2)
        place(out, (sine(f, u) + .4 * sine(f * 2, u)) * ex(u, .35) * .6, i * .09)
    pad = _chord([261.6, 329.6, 392, 523], tt(2.2), 1.0) * rise(tt(2.2), .08) * ex(tt(2.2), 1.0)
    place(out, pad, .5, .9)
    for _ in range(22):
        at = rng.uniform(.5, 2.0)
        u = tt(.3)
        place(out, sine(rng.uniform(3000, 8500), u) * ex(u, .07) * rng.uniform(.1, .25), at)
    return finish(echo(out, [(.07, .25), (.16, .14)]), .88)


def sparkle():
    t = tt(1.1)
    out = np.zeros_like(t)
    for _ in range(20):
        at = rng.uniform(0, .8)
        u = tt(.3)
        place(out, sine(rng.uniform(3000, 9000), u) * ex(u, rng.uniform(.04, .1)) * rng.uniform(.15, .4), at)
    return finish(out, .7)


def mask_drop():
    t = tt(.55)
    sw = bandpass(noise(.55), sweep(2500, 300, t), q=2) * ex(t, .12) * .7
    thump = sine(sweep(240, 70, t), t) * ex(t, .09)
    tick = highpass(noise(.55), 3000) * ex(t, .008) * .5
    return finish(sw + thump + tick, .9)


def tick():
    t = tt(.09)
    return finish(sine(1500, t) * ex(t, .018) + .4 * sine(3000, t) * ex(t, .01), .6)


def thunder():
    t = tt(1.8)
    crack = noise(1.8) * ex(t, .03) * 1.0
    zap = np.zeros_like(t)
    for _ in range(9):
        at = rng.uniform(0, .2)
        u = tt(.03)
        place(zap, highpass(noise(.03), 2000) * ex(u, .006), at, rng.uniform(.3, .7))
    roll = lowpass(noise(1.8), sweep(1500, 200, t)) * rise(t, .04) * ex(t, .75) * (1 + .5 * np.sin(2 * np.pi * 7 * t))
    sub = sine(sweep(140, 55, t), t) * rise(t, .06) * ex(t, .6) * .8
    return finish(crack + zap + roll * 1.6 + sub, .95)


def fire():
    t = tt(1.5)
    boom = bandpass(noise(1.5), sweep(250, 1400, t), q=1.2) * rise(t, .08) * ex(t, .5)
    low = lowpass(noise(1.5), 220) * rise(t, .05) * ex(t, .5) * .9
    clicks = np.zeros_like(t)
    for _ in range(70):
        at = rng.uniform(.05, 1.3) ** 1.0
        u = tt(.03)
        place(clicks, highpass(noise(.03), 1500) * ex(u, rng.uniform(.003, .01)), at, rng.uniform(.15, .6) * np.exp(-at / .9))
    return finish(boom * 1.1 + low + clicks, .9)


def ice():
    t = tt(1.4)
    burst = highpass(noise(1.4), 3500) * ex(t, .04) * .9
    whoosh = bandpass(noise(1.4), sweep(4500, 1500, t), q=2) * ex(t, .25) * .5
    pings = np.zeros_like(t)
    for i, f in enumerate([2093, 2637, 3136, 4186, 3520]):
        u = tt(.9)
        place(pings, (sine(f, u) + .3 * sine(f * 2.76, u)) * ex(u, .3) * .4, .02 + i * .05)
    return finish(echo(burst + whoosh + pings, [(.05, .25)]), .88)


def wings():
    t = tt(1.3)
    flutter = bandpass(noise(1.3), 650, q=1.4) * (.55 + .45 * np.sin(2 * np.pi * 21 * t)) * rise(t, .05) * ex(t, .8)
    out = flutter * 1.3
    for at in (.1, .35, .62):
        u = tt(.09)
        place(out, sine(sweep(4000, 7000, u), u) * np.sin(np.pi * u / .09) * .25, at)
    return finish(out, .85)


def ghost():
    t = tt(1.8)
    f = 360 + 260 * np.sin(np.pi * np.clip(t / 1.6, 0, 1)) + 7 * np.sin(2 * np.pi * 5.5 * t)
    wail = (sine(f, t) + .4 * sine(f * 2, t) + .2 * sine(f * 3.01, t)) * rise(t, .35) * ex(t, 1.0)
    breath = bandpass(noise(1.8), 900, q=3) * rise(t, .3) * ex(t, .9) * .45
    return finish(echo(wail * .8 + breath, [(.12, .3), (.26, .18)]), .85)


def gong():
    t = tt(2.0)
    f0 = 180
    body = sum(g * sine(f0 * r, t) * ex(t, tau) for r, g, tau in [
        (1, 1, 1.3), (1.51, .7, 1.1), (2.04, .6, .9), (2.6, .45, .7), (3.4, .3, .5), (4.2, .2, .4)])
    strike = bandpass(noise(2.0), 1800, q=1.5) * ex(t, .05) * .6
    shimmer = sine(2400, t) * ex(t, .5) * (.5 + .5 * np.sin(2 * np.pi * 9 * t)) * .15
    return finish(body * .8 + strike + shimmer, .9)


def airy():
    t = tt(1.1)
    breath = bandpass(noise(1.1), sweep(1800, 3600, t), q=2.5) * bell_env(t) * .35
    out = breath.copy()
    for at, f in [(.08, 1318), (.2, 1760), (.33, 1568), (.5, 2093), (.62, 1760), (.78, 2349)]:
        u = tt(.4)
        place(out, sine(f, u) * ex(u, .13) * .35, at)
    return finish(out, .75)


def puff():
    t = tt(.95)
    x = lowpass(noise(.95), sweep(1800, 260, t)) * rise(t, .04) * ex(t, .3)
    thump = sine(sweep(130, 50, t), t) * ex(t, .09) * .8
    return finish(x * 1.4 + thump, .85)


def coin():
    """رنّة عملة: جرس قصير بتوافقيات غير متناسقة، فيها نقرة معدن في أولها."""
    t = tt(.42)
    f = 1760.0
    x = sine(f, t) * ex(t, .09) + .55 * sine(f * 1.5, t) * ex(t, .07) + .25 * sine(f * 2.76, t) * ex(t, .035)
    x += highpass(noise(.42), 4000) * ex(t, .004) * .3
    return finish(x, .8)


def level():
    """ترقية المستوى: أربع نغمات تصعد (دو مي صول دو) مع لمعان فوقها."""
    out = np.zeros(int(1.3 * SR))
    for k, f in enumerate([1046.5, 1318.5, 1568.0, 2093.0]):
        u = tt(.9)
        place(out, (sine(f, u) + .4 * sine(f * 2, u)) * ex(u, .22) * rise(u, .005), k * .09)
    place(out, sparkle()[:int(.9 * SR)], .25, .5)
    return finish(echo(out, [(.1, .25)]), .85)


SOUNDS = {
    "whoosh": whoosh, "flip": flip, "drum": lambda: drum(165), "drum2": lambda: drum(235, .4),
    "yes": yes, "no": no, "stamp": stamp, "thud_red": thud_red,
    "crack": crack, "shatter": shatter, "lamp_out": lamp_out, "shield": shield, "heartbeat": heartbeat,
    "sting_traitor": sting_traitor, "sting_loyal": sting_loyal, "sting_leader": sting_leader,
    "win": win, "sparkle": sparkle, "mask_drop": mask_drop, "tick": tick,
    "thunder": thunder, "fire": fire, "ice": ice, "wings": wings, "ghost": ghost, "gong": gong,
    "airy": airy, "puff": puff,
    # الجديدة تنضاف في الآخر عشان الأصوات اللي قبلها تبقى نفسها (الضجيج بترتيب ثابت)
    "coin": coin, "level": level,
}


def save(name, x):
    os.makedirs(OUT, exist_ok=True)
    pcm = (np.clip(x, -1, 1) * 32767).astype("<i2")
    with wave.open(os.path.join(OUT, name + ".wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())


def sheet(path, made):
    """صورة أطياف الأصوات (للفحص بالعين: مين يتحرك وين وكم يطول)."""
    from PIL import Image, ImageDraw

    cols, w, h = 4, 300, 150
    rows = (len(made) + cols - 1) // cols
    img = Image.new("RGB", (cols * w, rows * h), (20, 16, 12))
    d = ImageDraw.Draw(img)
    for i, (name, x) in enumerate(made):
        n = 512
        hop = max(1, (len(x) - n) // w)
        frames = [np.abs(np.fft.rfft(x[j:j + n] * np.hanning(n))) for j in range(0, len(x) - n, hop)][:w]
        spec = np.log1p(np.array(frames).T * 30)[::-1]
        spec = spec / (spec.max() + 1e-9)
        tile = Image.fromarray((spec * 255).astype("uint8")).resize((w, h - 14)).convert("RGB")
        img.paste(tile, ((i % cols) * w, (i // cols) * h + 14))
        d.text(((i % cols) * w + 4, (i // cols) * h + 1), f"{name} {len(x) / SR:.2f}s", fill=(255, 230, 160))
    img.save(path)


if __name__ == "__main__":
    made = []
    for name, fn in SOUNDS.items():
        x = fn()
        save(name, x)
        made.append((name, x))
        print(f"{name:14s} {len(x) / SR:5.2f}s  peak {np.max(np.abs(x)):.2f}")
    if "--sheet" in sys.argv:
        sheet(sys.argv[sys.argv.index("--sheet") + 1], made)
