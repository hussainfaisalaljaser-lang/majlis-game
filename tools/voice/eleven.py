"""صوت الراوي الخليجي بـ ElevenLabs.

  python eleven.py samples "ID1,ID2,..." OUT   عينة الجملة بكل صوت، عشان نختار
  python eleven.py lines VOICE_ID OUT          كل جمل اللعبة (lines.json) بالصوت المختار

يحتاج ELEVENLABS_API_KEY. الصوت لازم يكون مضاف في حسابك (My Voices).
"""
import json, os, sys, urllib.error, urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
LINES = json.load(open(os.path.join(HERE, 'lines.json'), encoding='utf-8'))
KEY = os.environ['ELEVENLABS_API_KEY']
MODEL = os.environ.get('ELEVEN_MODEL') or 'eleven_v3'


def say(text, voice, path):
    req = urllib.request.Request(
        f'https://api.elevenlabs.io/v1/text-to-speech/{voice}?output_format=mp3_44100_128',
        data=json.dumps({'text': text, 'model_id': MODEL, 'language_code': 'ar'}).encode(),
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


def main():
    mode = sys.argv[1]
    if mode == 'samples':
        voices, out = [v.strip() for v in sys.argv[2].split(',') if v.strip()], sys.argv[3]
        os.makedirs(out, exist_ok=True)
        for v in voices:
            say(LINES['sample'], v, os.path.join(out, v + '.mp3'))
            print('✓', v)
    elif mode == 'lines':
        voice, out = sys.argv[2], sys.argv[3]
        os.makedirs(out, exist_ok=True)
        for key, text in LINES['lines'].items():
            say(text, voice, os.path.join(out, key + '.mp3'))
            print('✓', key)
    else:
        sys.exit(__doc__)


if __name__ == '__main__':
    main()
