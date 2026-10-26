"""صوت الراوي السعودي بـ ElevenLabs.

  python eleven.py lines VOICE_ID OUT [key1,key2]   جمل اللعبة (lines.json)، كلها أو المذكورة بس

لو lines.json فيه "check": true، كل جملة تنسمع بعد ما تتولد (heard.json) عشان نلقى الكلمات اللي انقرت غلط.

الإعداد المعتمد في lines.json → config، وأي جملة لها إعداد خاص في overrides.
يحتاج ELEVENLABS_API_KEY. الصوت لازم يكون مضاف في حسابك (My Voices).
"""
import json, os, re, sys, urllib.error, urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
LINES = json.load(open(os.path.join(HERE, 'lines.json'), encoding='utf-8'))
KEY = os.environ['ELEVENLABS_API_KEY']
MODEL = os.environ.get('ELEVEN_MODEL') or 'eleven_v3'


def say(text, voice, path, stability=None, cfg=None):
    cfg = cfg or {}
    model = cfg.get('model', MODEL)
    if cfg.get('strip_tags'):
        text = re.sub(r'\[[^\]]+\]\s*', '', text)
    text = cfg.get('prefix', '') + text
    body = {'text': text, 'model_id': model}
    if not cfg.get('no_lang') and model == 'eleven_v3':
        body['language_code'] = 'ar'
    stability = os.environ.get('ELEVEN_STABILITY') if stability is None else stability
    stability = cfg.get('stability', stability)
    settings = {}
    if stability not in (None, ''):
        settings['stability'] = float(stability)
    if cfg.get('similarity') is not None:
        settings['similarity_boost'] = cfg['similarity']
    if cfg.get('style') is not None:
        settings['style'] = cfg['style']
    if cfg.get('boost'):
        settings['use_speaker_boost'] = True
    if settings:
        body['voice_settings'] = settings
    req = urllib.request.Request(
        f'https://api.elevenlabs.io/v1/text-to-speech/{voice}?output_format=mp3_44100_128',
        data=json.dumps(body).encode(),
        headers={'xi-api-key': KEY, 'Content-Type': 'application/json', 'Accept': 'audio/mpeg'},
        method='POST')
    try:
        data = urllib.request.urlopen(req).read()
    except urllib.error.HTTPError as e:
        msg = e.read().decode(errors='replace')
        print(f'::error::ElevenLabs {e.code} للصوت {voice}: {msg[:300]}')
        raise
    with open(path, 'wb') as f:
        f.write(data)


def hear(path):
    """يسمع الملف (تحويل الكلام لنص) ويرجع اللي انقال فعلاً، عشان نلقى الكلمات اللي انقرت غلط."""
    boundary = 'majlis' + os.urandom(8).hex()
    head = lambda name, extra='': f'--{boundary}\r\nContent-Disposition: form-data; name="{name}"{extra}\r\n'
    body = b''.join([
        (head('model_id') + '\r\nscribe_v1\r\n').encode(),
        (head('language_code') + '\r\nar\r\n').encode(),
        (head('file', f'; filename="{os.path.basename(path)}"') + 'Content-Type: audio/mpeg\r\n\r\n').encode(),
        open(path, 'rb').read(),
        f'\r\n--{boundary}--\r\n'.encode(),
    ])
    req = urllib.request.Request(
        'https://api.elevenlabs.io/v1/speech-to-text',
        data=body,
        headers={'xi-api-key': KEY, 'Content-Type': f'multipart/form-data; boundary={boundary}'},
        method='POST')
    try:
        return json.loads(urllib.request.urlopen(req, timeout=120).read())['text']
    except urllib.error.HTTPError as e:
        return f'(ما قدرنا نسمعه: {e.code} {e.read().decode(errors="replace")[:200]})'


def compose(prompt, length_ms, path):
    req = urllib.request.Request(
        'https://api.elevenlabs.io/v1/music?output_format=mp3_44100_128',
        data=json.dumps({'prompt': prompt, 'music_length_ms': length_ms, 'force_instrumental': True}).encode(),
        headers={'xi-api-key': KEY, 'Content-Type': 'application/json', 'Accept': 'audio/mpeg'},
        method='POST')
    try:
        data = urllib.request.urlopen(req, timeout=300).read()
    except urllib.error.HTTPError as e:
        msg = e.read().decode(errors='replace')
        print(f'::error::Eleven Music {e.code}: {msg[:400]}')
        raise
    with open(path, 'wb') as f:
        f.write(data)


def cfg_for(key):
    """الإعداد المعتمد (config) ومعه أي تعديل خاص بهالجملة (overrides)."""
    return {**LINES.get('config', {}), **LINES.get('overrides', {}).get(key, {})}


def main():
    mode = sys.argv[1]
    voice, out = sys.argv[2], sys.argv[3]
    os.makedirs(out, exist_ok=True)
    keys = sys.argv[4].split(',') if len(sys.argv) > 4 and sys.argv[4] else list(LINES['lines'])
    if mode == 'music':
        # موسيقى اللعبة بـ Eleven Music (music.json)
        spec = json.load(open(os.path.join(HERE, 'music.json'), encoding='utf-8'))
        for name, prompt in spec['tracks'].items():
            if keys and len(sys.argv) > 4 and sys.argv[4] and name not in keys:
                continue
            compose(prompt, spec['length_ms'], os.path.join(out, name + '.mp3'))
            print('✓', name)
    elif mode == 'experiment':
        # نفس الجمل بأكثر من إعداد، عشان نقارن الإحساس
        exp = LINES['experiment']
        for name, cfg in exp['configs'].items():
            for key, text in exp['texts'].items():
                say(text, voice, os.path.join(out, f'{name}__{key}.mp3'), cfg=cfg)
                print('✓', name, key)
    elif mode == 'lines':
        heard = {}
        for key in keys:
            path = os.path.join(out, key + '.mp3')
            say(LINES['lines'][key], voice, path, cfg=cfg_for(key))
            print('✓', key)
            # "check": نسمع كل جملة بعد ما تتولد ونحفظ اللي انقال، نقارنه بالنص
            if LINES.get('check'):
                heard[key] = {'text': LINES['lines'][key], 'heard': hear(path)}
                print('  سمعناه:', heard[key]['heard'])
        if heard:
            json.dump(heard, open(os.path.join(out, 'heard.json'), 'w', encoding='utf-8'), ensure_ascii=False, indent=2)
    else:
        sys.exit(__doc__)


if __name__ == '__main__':
    main()
