"""يولّد صوت الراوي العربي بـ Google Cloud Text-to-Speech.

  python tts.py samples OUT        عينة لكل صوت عربي (ar-XA)، عشان نختار
  python tts.py lines VOICE OUT    كل جمل اللعبة (lines.json) بالصوت المختار

يحتاج GOOGLE_APPLICATION_CREDENTIALS (حساب خدمة لمشروع Firebase).
"""
import base64, json, os, sys, urllib.error, urllib.request

import google.auth
import google.auth.transport.requests

PROJECT = 'majlis-game-1d739'
API = 'https://texttospeech.googleapis.com/v1'
HERE = os.path.dirname(os.path.abspath(__file__))
LINES = json.load(open(os.path.join(HERE, 'lines.json'), encoding='utf-8'))

creds, _ = google.auth.default(scopes=['https://www.googleapis.com/auth/cloud-platform'])
creds.refresh(google.auth.transport.requests.Request())


def call(path, body=None):
    req = urllib.request.Request(
        API + path,
        data=None if body is None else json.dumps(body).encode(),
        headers={'Authorization': f'Bearer {creds.token}', 'x-goog-user-project': PROJECT,
                 'Content-Type': 'application/json'},
        method='GET' if body is None else 'POST')
    try:
        return json.load(urllib.request.urlopen(req))
    except urllib.error.HTTPError as e:
        msg = e.read().decode()
        if 'SERVICE_DISABLED' in msg or 'has not been used' in msg:
            print('::error::فعّل Cloud Text-to-Speech API: https://console.cloud.google.com/apis/library/texttospeech.googleapis.com?project=' + PROJECT)
        print(msg)
        raise


def say(text, voice, path):
    r = call('/text:synthesize', {
        'input': {'text': text},
        'voice': {'languageCode': 'ar-XA', 'name': voice},
        'audioConfig': {'audioEncoding': 'OGG_OPUS'},
    })
    with open(path, 'wb') as f:
        f.write(base64.b64decode(r['audioContent']))


def main():
    mode = sys.argv[1]
    if mode == 'samples':
        out = sys.argv[2]
        os.makedirs(out, exist_ok=True)
        voices = [v for v in call('/voices?languageCode=ar-XA')['voices']]
        # الأصوات العادية (Standard) أضعف، نتركها
        voices = [v for v in voices if 'Standard' not in v['name']]
        json.dump(voices, open(os.path.join(out, 'voices.json'), 'w'), ensure_ascii=False, indent=1)
        for v in voices:
            try:
                say(LINES['sample'], v['name'], os.path.join(out, v['name'] + '.ogg'))
                print('✓', v['name'], v.get('ssmlGender'))
            except Exception as e:  # بعض الأصوات ما تدعم كل شي، نكمل
                print('✗', v['name'], e)
    elif mode == 'lines':
        voice, out = sys.argv[2], sys.argv[3]
        os.makedirs(out, exist_ok=True)
        for key, text in LINES['lines'].items():
            say(text, voice, os.path.join(out, key + '.ogg'))
            print('✓', key)
    else:
        sys.exit(__doc__)


if __name__ == '__main__':
    main()
