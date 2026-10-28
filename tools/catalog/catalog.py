"""
كتالوج أغراض اللعبة: المصدر الوحيد للإطارات والفقاعات والشخصيات والطاولات والكروت والملصقات وهدايا المستويات.
يولّد ملفين (لا تعدلهم باليد):
  functions/src/catalog.ts       ← اللي يحتاجه السيرفر (الأسعار، اللي يفتح بالمستوى، الردود المسموحة)
  app/lib/models/catalog.dart    ← نفسه مع الشكل (الألوان والحركات) للتطبيق
تشغيل:  python3 tools/catalog/catalog.py
"""
import json, os

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))

# ───────────── الإطارات ─────────────
# كل إطار له رسمته في app/lib/widgets/frames (sig): النادر ثابت ولمعة تمر كل كم ثانية، والملحمي يتحرك،
# والأسطوري أكثر من طبقة وله لحظة خاصة. ولا إطار فيه تاج (التاج علامة الرئيس في الطاولة).
FRAMES = [
    dict(id='frame_none', name='بدون إطار', rarity='common', default=True),
    dict(id='frame_ice', name='جليد', rarity='rare', coins=3000, sig='ice',
         desc='بلور ثلج مقطّع، وأصابع ثلج معلقة تحت صورتك'),
    dict(id='frame_sand', name='رمل', rarity='rare', coins=4000, sig='sand',
         desc='طبقات حجر رملي، وكثبان ناعمة تحت صورتك'),
    dict(id='frame_oasis', name='واحة', rarity='rare', coins=5000, sig='oasis',
         desc='نخلتين حول صورتك بعذوق التمر، وحلقة ماي صافي'),
    dict(id='frame_pearl', name='لؤلؤ', rarity='rare', coins=6000, sig='pearl',
         desc='عقد لؤلؤ أبيض، وحبة لؤلؤ كبيرة معلقة تحت'),
    dict(id='frame_night', name='ليل نجد', rarity='rare', coins=7000, sig='night',
         desc='بيوت طين نجدية تحت صورتك، ونوافذها تضوي بالليل'),
    dict(id='frame_fire', name='نار', rarity='epic', coins=8000, sig='fire',
         desc='ألسنة لهب تطلع من حول صورتك، وشرار يطير لفوق'),
    dict(id='frame_smoke', name='دخان', rarity='epic', coins=9000, sig='smoke',
         desc='مبخرة تحت صورتك، ودخان البخور يلف حولها ويطلع'),
    dict(id='frame_lightning', name='برق', rarity='epic', coins=10000, sig='lightning',
         desc='شرارات كهربا تنط على الحلقة، وبرق يضرب كل شوي'),
    dict(id='frame_comet', name='شهاب', rarity='epic', coins=11000, sig='comet',
         desc='شهاب يدور حول صورتك ويخلي وراه غبار نجوم'),
    dict(id='frame_neon', name='نيون', rarity='epic', coins=12000, sig='neon',
         desc='أنابيب نيون تطنّ وترمش مثل لوحات المحلات'),
    dict(id='frame_rainbow', name='قوس قزح', rarity='epic', coins=15000, sig='rainbow',
         desc='صبغ ملوّن يسيل حول صورتك وينقّط من تحت'),
    dict(id='frame_emerald', name='زمرد', rarity='epic', diamonds=15, sig='emerald',
         desc='أحجار زمرد مركّبة بذهب، والضو ينتقل من حجر لحجر'),
    dict(id='frame_blood', name='دم الخونة', rarity='epic', diamonds=20, sig='blood',
         desc='الحلقة تنبض مثل القلب، وقطرات دم تنزل منها'),
    dict(id='frame_blackgold', name='الذهب الأسود', rarity='epic', diamonds=25, sig='blackgold',
         desc='حجر أسود فيه عروق ذهب ذايب تمشي وتتوهج'),
    dict(id='frame_sun', name='الشمس', rarity='legendary', diamonds=30, sig='sun',
         desc='شمس بأشعة تدور وتوهج. لحظتها الخاصة: انفجار شمسي'),
    dict(id='frame_arabesque', name='نقوش', rarity='legendary', diamonds=35, sig='arabesque',
         desc='زخرفة إسلامية ترسم نفسها بالذهب حول صورتك وتتوهج'),
    dict(id='frame_king', name='الطاووس', rarity='legendary', diamonds=40, sig='peacock',
         desc='ذيل طاووس ينفرد ورا صورتك، وعيونه تتلوّن مثل الحرير'),
    dict(id='frame_galaxy', name='مجرة', rarity='legendary', diamonds=45, sig='galaxy',
         desc='مجرة تدور ورا صورتك وكواكب تلف حولها. لحظتها الخاصة: انفجار نجمي'),
    # هدايا المستويات
    dict(id='frame_lv10', name='فارس المجلس', rarity='rare', level=10, sig='knight',
         desc='درع برونز بمسامير، وشارة الفارس تحت صورتك'),
    dict(id='frame_lv20', name='النخبة', rarity='epic', level=20, sig='elite',
         desc='فضة مصقولة ينعكس عليها الضو، ولمعات صغيرة حولها'),
    dict(id='frame_lv30', name='الذهبي', rarity='epic', level=30, sig='golden',
         desc='عقد جنيهات ذهب يدور، وكل جنيه ينقلب ويلمع'),
    dict(id='frame_lv40', name='الياقوت', rarity='legendary', level=40, sig='ruby',
         desc='بلورات ياقوت تطلع من الحلقة وداخلها نار ترجف'),
    dict(id='frame_lv50', name='أسطورة المجلس', rarity='legendary', level=50, sig='phoenix',
         desc='عنقاء من نار ملوّنة: جناحينها ينفردون حول صورتك'),
    # الموسم الأول (من الباتل باس)
    dict(id='frame_s1f', name='هلال الموسم', rarity='rare', season='s1', sig='crescent',
         desc='هلال ذهبي يحضن صورتك، ونجوم ذهب'),
    dict(id='frame_s1a', name='ليالي المجلس', rarity='epic', season='s1', sig='lanterns',
         desc='فوانيس رمضان تتمرجح، وزينة أضواء تلمع بالدور'),
    dict(id='frame_s1b', name='عاصفة الموسم', rarity='legendary', season='s1', sig='storm',
         desc='دوامة عاصفة تلف حولك، وبرق يومض داخلها'),
    dict(id='frame_s1c', name='احتفال الموسم الأول', rarity='legendary', season='s1', sig='fireworks',
         desc='ألعاب نارية تنفجر حول صورتك احتفال بالموسم'),
    # أبطال الأسبوع (لأسبوع واحد)
    dict(id='frame_champ1', name='بطل الأسبوع', rarity='legendary', champion=1, sig='champ1',
         desc='إكليل غار ذهبي وميدالية المركز الأول، وقصاصات احتفال'),
    dict(id='frame_champ2', name='وصيف الأسبوع', rarity='legendary', champion=2, sig='champ2',
         desc='إكليل غار فضي وميدالية المركز الثاني، ولمعات صقيع'),
    dict(id='frame_champ3', name='ثالث الأسبوع', rarity='legendary', champion=3, sig='champ3',
         desc='إكليل غار برونزي وميدالية المركز الثالث، وجمر يطير'),
]

# ───────────── افكتات الموت ─────────────
# تطلع على اللاعب لما ينطرد، والكل يشوفها (app/lib/widgets/death_fx.dart). الافتراضي: الغطا الرمادي.
DEATHS = [
    dict(id='death_cloth', name='الغطا', rarity='common', default=True, fx='cloth', desc='يطيح عليه غطا رمادي'),
    dict(id='death_smoke', name='دخان', rarity='rare', coins=6000, fx='smoke', desc='يختفي وسط دخان بنفسجي'),
    dict(id='death_sand', name='رمل', rarity='rare', coins=8000, fx='sand', desc='يتفتت رمل ويطير مع الهوا'),
    dict(id='death_petals', name='ورد', rarity='epic', coins=14000, fx='petals', desc='يتطاير منه ورد أحمر'),
    dict(id='death_ice', name='تجمّد', rarity='epic', coins=16000, fx='ice', desc='يتجمد داخل قالب ثلج'),
    dict(id='death_fire', name='نار', rarity='epic', diamonds=20, fx='fire', desc='تاكله النار ويبقى رماد وجمر'),
    dict(id='death_bats', name='خفافيش', rarity='epic', diamonds=22, fx='bats', desc='يطير منه سرب خفافيش'),
    dict(id='death_lightning', name='صاعقة', rarity='epic', diamonds=25, fx='lightning', desc='تضربه صاعقة من السما'),
    dict(id='death_ghost', name='شبح', rarity='legendary', diamonds=35, fx='ghost', desc='روحه تطلع وتطفو فوقه'),
    dict(id='death_gold', name='تمثال ذهب', rarity='legendary', diamonds=45, fx='gold', desc='يتحول تمثال ذهب يلمع'),
]

# ───────────── فقاعات الكلام ─────────────
# fx: shimmer glow sparkle flame snow stars rainbow neon electric sand bubbles steam leaves spin smoke
BUBBLES = [
    dict(id='bubble_classic', name='رق', rarity='common', default=True, bg=['F7EAD0', 'E9D2A6'], border='C9A86A', text='3A2A12', fx=[]),
    dict(id='bubble_gold', name='ذهبي', rarity='rare', coins=2500, bg=['FFE082', 'F2B33D'], border='8A5A08', text='3A2400', fx=['shimmer']),
    dict(id='bubble_silver', name='فضي', rarity='rare', coins=3000, bg=['F5F7FA', 'C9D1DC'], border='7B8794', text='1F2933', fx=['shimmer']),
    dict(id='bubble_desert', name='صحراوي', rarity='rare', coins=3500, bg=['EED3A6', 'C99A5B'], border='8E6534', text='3B2410', fx=['sand']),
    dict(id='bubble_sea', name='بحري', rarity='rare', coins=4000, bg=['5EEAD4', '0E7490'], border='CCFBF1', text='FFFFFF', fx=['bubbles']),
    dict(id='bubble_coffee', name='قهوة', rarity='rare', coins=4500, bg=['8D6E63', '4E342E'], border='D7A86E', text='FFF3E0', fx=['steam']),
    dict(id='bubble_night', name='ليلي', rarity='epic', coins=6000, bg=['1E3A8A', '0B1026'], border='93C5FD', text='E0E7FF', fx=['stars']),
    dict(id='bubble_emerald', name='زمردي', rarity='epic', coins=7000, bg=['10B981', '065F46'], border='A7F3D0', text='FFFFFF', fx=['glow', 'leaves']),
    dict(id='bubble_fire', name='ناري', rarity='epic', coins=8000, bg=['FF7043', 'B71C1C'], border='FFD180', text='FFFFFF', fx=['flame']),
    dict(id='bubble_ice', name='ثلجي', rarity='epic', coins=8000, bg=['E0F7FF', '7DD3FC'], border='FFFFFF', text='0C4A6E', fx=['snow', 'shimmer']),
    dict(id='bubble_neon', name='نيون', rarity='epic', coins=10000, bg=['0B0B1A', '1A1033'], border='00F5FF', text='00F5FF', fx=['neon']),
    dict(id='bubble_rose', name='وردي', rarity='epic', coins=12000, bg=['F9A8D4', 'DB2777'], border='FCE7F3', text='FFFFFF', fx=['glow', 'sparkle']),
    dict(id='bubble_lightning', name='برق', rarity='epic', diamonds=12, bg=['1E1B4B', '312E81'], border='60A5FA', text='FFFFFF', fx=['electric']),
    dict(id='bubble_blood', name='دموي', rarity='epic', diamonds=15, bg=['7F1D1D', '1C0606'], border='EF4444', text='FECACA', fx=['glow', 'smoke']),
    dict(id='bubble_royal', name='ملكي', rarity='legendary', diamonds=25, bg=['6D28D9', '3B0764'], border='FCD34D', text='FFFFFF', fx=['sparkle', 'shimmer']),
    dict(id='bubble_rainbow', name='قوس قزح', rarity='legendary', diamonds=30, bg=['FFFFFF', 'EEF2FF'], border='FFFFFF', text='111827', fx=['rainbow']),
    dict(id='bubble_galaxy', name='مجرة', rarity='legendary', diamonds=40, bg=['312E81', '701A75', '0E7490'], border='E9D5FF', text='FFFFFF', fx=['spin', 'sparkle']),
    dict(id='bubble_s1f', name='هلال', rarity='rare', season='s1', bg=['134E4A', '042F2E'], border='FCD34D', text='FDE68A', fx=['stars']),
    dict(id='bubble_s1', name='ليالي المجلس', rarity='epic', season='s1', bg=['312E81', '0F766E'], border='FCD34D', text='FFFFFF', fx=['shimmer', 'stars']),
    dict(id='bubble_s1b', name='عاصفة', rarity='legendary', season='s1', bg=['0C4A6E', '1E1B4B'], border='7DD3FC', text='E0F2FE', fx=['electric', 'glow']),
    dict(id='bubble_lv5', name='نجمة المبتدئ', rarity='rare', level=5, bg=['FDE68A', 'F59E0B'], border='FFFBEB', text='451A03', fx=['sparkle']),
    dict(id='bubble_lv25', name='الألماس', rarity='epic', level=25, bg=['BAE6FD', '3B82F6'], border='FFFFFF', text='FFFFFF', fx=['shimmer', 'sparkle']),
    dict(id='bubble_lv45', name='صفوة المجلس', rarity='legendary', level=45, bg=['111827', '374151'], border='FFD54F', text='FFD54F', fx=['shimmer', 'glow']),
]

# ───────────── الشخصيات ─────────────
FREE_AVATARS = ['falcon', 'sheikh', 'cool', 'scholar', 'desert', 'hawk', 'merchant', 'youth',
                'pearl', 'rose', 'night', 'jasmine', 'amber', 'sky', 'masked', 'shadow']
# bg: ألوان الخلفية المتحركة · fx: aurora rays sparkle embers pulse smoke stars bubbles
AVATARS = [
    dict(id='detective', name='المحقق', rarity='rare', coins=6000, bg=['495C83', '1B2440'], fx='pulse'),
    dict(id='spy', name='الجاسوسة', rarity='rare', coins=6000, bg=['0F766E', '042F2E'], fx='pulse'),
    dict(id='doctor', name='الطبيبة', rarity='rare', coins=6000, bg=['5EEAD4', '115E59'], fx='sparkle'),
    dict(id='diver', name='الغوّاص', rarity='rare', coins=7000, bg=['0EA5E9', '0C4A6E'], fx='bubbles'),
    dict(id='poet', name='الشاعر', rarity='rare', coins=7000, bg=['7C3AED', '1E1B4B'], fx='stars'),
    dict(id='camel', name='الجمل', rarity='rare', coins=8000, bg=['F59E0B', '7C2D12'], fx='embers'),
    dict(id='falconer', name='الصقّار', rarity='epic', coins=12000, bg=['8C6D46', '3A2A16'], fx='rays', anim='falconer',
         desc='يرمش ويتنفس، وصقره يلف راسه ويفرد جناحه'),
    dict(id='lady_gold', name='الأميرة', rarity='epic', coins=12000, bg=['E64980', '5C0F2E'], fx='sparkle', anim='lady_gold',
         desc='ترمش وتغمز، وتاجها يلمع'),
    dict(id='pilot', name='الطيّار', rarity='epic', coins=12000, bg=['38BDF8', '1E3A8A'], fx='rays', anim='pilot',
         desc='ينزّل نظارته ويتجهز للطيران'),
    dict(id='seer', name='العرّاف', rarity='epic', coins=14000, bg=['A855F7', '2E1065'], fx='aurora', anim='seer',
         desc='كرته البلورية تضوي، وعيونه تشع لما يشوف شي'),
    dict(id='knight', name='الفارس', rarity='epic', coins=15000, bg=['DC2626', '450A0A'], fx='rays', anim='knight',
         desc='ريشة خوذته تتمايل، ويحييك بخوذته'),
    dict(id='ghost', name='الشبح', rarity='epic', diamonds=18, bg=['4C1D95', '05010D'], fx='smoke', anim='ghost',
         desc='يطفو ويختفي ويرجع… وأحياناً يخرّعك'),
    dict(id='assassin', name='الملثّم', rarity='epic', diamonds=20, bg=['7F0A0A', '120202'], fx='smoke', anim='assassin',
         desc='عيونه الحمرا تضيق، ويقلّب خنجره'),
    dict(id='wolf', name='الذئب', rarity='epic', diamonds=20, bg=['1E3A8A', '020617'], fx='stars', anim='wolf',
         desc='يحرك أذونه، وكل شوي يعوي'),
    dict(id='falcon_bird', name='الصقر', rarity='epic', diamonds=22, bg=['D97706', '451A03'], fx='rays', anim='falcon_bird',
         desc='يلف راسه مثل الصقور ويصرخ'),
    dict(id='tycoon', name='تاجر الذهب', rarity='legendary', diamonds=30, bg=['FBBF24', '78350F'], fx='sparkle', anim='tycoon',
         desc='سلسلته تتمرجح وتطيح حوله عملات ذهب'),
    dict(id='emir', name='الأمير', rarity='legendary', diamonds=35, bg=['F2C14E', '7A4E00'], fx='rays', anim='emir',
         desc='يهز راسه بهيبة، وبشته يلمع'),
    dict(id='sultana', name='السلطانة', rarity='legendary', diamonds=35, bg=['C026D3', '3B0764'], fx='aurora', anim='sultana',
         desc='ترمش، وطرحتها تتمايل وجوهرتها تلمع'),
    dict(id='queen', name='الملكة', rarity='legendary', diamonds=40, bg=['8B5CF6', '2E1065'], fx='sparkle', anim='queen',
         desc='ترمش، وجواهر تاجها تلمع'),
    dict(id='astronaut', name='رائد الفضاء', rarity='legendary', diamonds=45, bg=['312E81', '020617'], fx='stars', anim='astronaut',
         desc='يسبح في الفضاء، وخوذته يمر عليها ضو'),
    dict(id='lv10', name='حارس المجلس', rarity='rare', level=10, bg=['B45309', '431407'], fx='pulse',
         desc='سلوقي وفي يحرس المجلس، ودرعه على صدره'),
    dict(id='lv20', name='البومة الحكيمة', rarity='epic', level=20, bg=['64748B', '0F172A'], fx='stars', anim='lv20',
         desc='تقرأ في كتابها وتقلّب الصفحات، وتلف راسها مثل البوم'),
    dict(id='lv30', name='النمر الذهبي', rarity='epic', level=30, bg=['F59E0B', '78350F'], fx='rays', anim='lv30',
         desc='سلسلته الذهب تتمرجح، وفروه يلمع'),
    dict(id='lv40', name='أسد الياقوت', rarity='legendary', level=40, bg=['E11D48', '4C0519'], fx='embers', anim='lv40',
         desc='لبدته تتمايل وياقوتته تتوهج، ويزأر زأرة حرب'),
    dict(id='lv50', name='العنقاء', rarity='legendary', level=50, bg=['F472B6', '312E81'], fx='aurora', anim='lv50',
         desc='أسطورة المجلس: عرفها نار يتراقص، وجناحينها يرفرفون'),
    dict(id='s1a', name='وشق الليل', rarity='epic', season='s1', bg=['0F766E', '042F2E'], fx='stars', anim='s1a',
         desc='يتلفت يمين ويسار، ويحرك أذونه، وهلاله يلمع'),
    dict(id='s1b', name='غزال القمر', rarity='legendary', season='s1', bg=['6366F1', '1E1B4B'], fx='aurora', anim='s1b',
         desc='هلاله يضوي بين قرونه، ويحرك أذونه'),
    dict(id='s1c', name='أصيل الموسم الأول', rarity='legendary', season='s1', bg=['FCD34D', '134E4A'], fx='rays', anim='s1c',
         desc='حصان عربي أصيل: يهز راسه، وعرفه يتطاير، وهلاله يضوي'),
    dict(id='champ1', name='بطل الأسبوع', rarity='legendary', champion=1, bg=['FFD700', '7A5200'], fx='rays', anim='champ1',
         desc='ميداليتها تتمرجح، وتضحك وتهز أذونها فرحانة بالفوز'),
    dict(id='champ2', name='وصيف الأسبوع', rarity='legendary', champion=2, bg=['E2E8F0', '334155'], fx='rays', anim='champ2',
         desc='ميداليتها تتمرجح، وتضحك وتهز أذونها فرحانة بالفوز'),
    dict(id='champ3', name='ثالث الأسبوع', rarity='legendary', champion=3, bg=['E0A060', '5A2E0E'], fx='rays', anim='champ3',
         desc='ميداليتها تتمرجح، وتضحك وتهز أذونها فرحانة بالفوز'),
]

# ───────────── الطاولات والكروت ─────────────
TABLES = [
    dict(id='table_majlis', name='المجلس', rarity='common', default=True, art='majlis'),
    dict(id='table_sand', name='رمال', rarity='rare', coins=6000, art='sand'),
    dict(id='table_oasis', name='واحة', rarity='rare', coins=8000, art='oasis'),
    dict(id='table_night', name='ليل نجد', rarity='epic', coins=15000, art='night'),
    dict(id='table_palace', name='القصر', rarity='epic', diamonds=25, art='palace'),
    dict(id='table_gold', name='الذهب الأسود', rarity='legendary', diamonds=50, art='gold'),
    dict(id='table_s1', name='ليالي المجلس', rarity='legendary', season='s1', art='s1'),
]
# loyal/traitor: ألوان الختم · icons: صور الرموز في assets/icons/card_*.png
CARDS = [
    dict(id='cards_classic', name='كلاسيك', rarity='common', default=True),
    dict(id='cards_oasis', name='واحة', rarity='rare', coins=5000, loyal=['26C6DA', '00695C'], traitor=['FF8A65', 'BF360C'], icons=['palm', 'scorpion'], border='FFE0B2'),
    dict(id='cards_night', name='ليل الصحراء', rarity='epic', coins=12000, loyal=['3949AB', '0D1440'], traitor=['8E24AA', '2A0636'], icons=['moon', 'wolf'], border='B0BEC5'),
    dict(id='cards_dragon', name='التنين', rarity='epic', diamonds=20, loyal=['00B0FF', '01579B'], traitor=['D50000', '3E0000'], icons=['dragon', 'flame'], border='FF5252'),
    dict(id='cards_s1', name='الهلال', rarity='epic', season='s1', loyal=['14B8A6', '134E4A'], traitor=['7C3AED', '2E1065'], icons=['crescent', 'eclipse'], border='FCD34D'),
    dict(id='cards_royal', name='الذهب الملكي', rarity='legendary', diamonds=50, loyal=['1E88E5', '0B2F6B'], traitor=['E53935', '5B0E0E'], icons=['crown', 'dagger'], border='FFD54F'),
]

# ───────────── الردود ─────────────
# الكلام: % مكان اسم اللاعب اللي اخترته.
TEXT_REACTIONS = [
    dict(id='suspect', label='أشك في…', target=True, say='أشك في %', icon='suspect'),
    dict(id='trust', label='أثق في…', target=True, say='أثق في %', icon='trust'),
    dict(id='liar', label='كذاب', target=True, say='% كذاب!', icon='liar'),
    dict(id='pick', label='جربوا فلان', target=True, say='جربوا %', icon='pick'),
    dict(id='innocent', label='أنا بريء', target=False, say='أنا بريء!', icon='innocent'),
    dict(id='sure', label='متأكد ١٠٠٪', target=False, say='متأكد ١٠٠٪', pack='pack_phrases'),
    dict(id='khayin', label='فلان خاين!', target=True, say='% خاين!', pack='pack_phrases'),
    dict(id='stab', label='فلان طعنني!', target=True, say='% طعنني!', pack='pack_phrases'),
    dict(id='calm', label='هدّوا اللعب', target=False, say='هدّوا اللعب', pack='pack_phrases'),
    dict(id='hurry', label='يلا بسرعة', target=False, say='يلا بسرعة', pack='pack_phrases'),
    dict(id='trustme', label='ثقوا فيني', target=False, say='ثقوا فيني', pack='pack_phrases'),
    dict(id='gg', label='قيم مرتب', target=False, say='قيم مرتب', pack='pack_phrases'),
]
# باقات الملصقات (ميمز مرسومة للعبة). كل ملصق: (المعرف، الكلام اللي عليه)
STICKER_PACKS = [
    dict(id='stk_basic', name='الأساسي', rarity='common', default=True, stickers=[
        ('b_laugh', 'ههههه'), ('b_think', 'ممم…'), ('b_eyes', 'شايفك!'), ('b_shh', 'ششش'), ('b_smirk', 'فهمتك'), ('b_angry', 'لا تكذب!')]),
    dict(id='stk_shock', name='صدمة', rarity='rare', coins=3000, stickers=[
        ('shock_jaw', 'مستحيل!'), ('shock_hands', 'يا ساتر'), ('shock_what', 'وش صار؟!'), ('shock_no', 'لا لا لا'), ('shock_dizzy', 'دوّخوني'), ('shock_faint', 'انصدمت')]),
    dict(id='stk_laugh', name='ضحك', rarity='rare', coins=3000, stickers=[
        ('laugh_tears', 'ميت ضحك'), ('laugh_roll', 'هههههههه'), ('laugh_clap', 'قوية!'), ('laugh_point', 'شوفوه!'), ('laugh_grin', 'هيهي'), ('laugh_wink', 'تمزح؟')]),
    dict(id='stk_coffee', name='القهوة', rarity='rare', coins=3500, stickers=[
        ('cof_cup', 'تقهوى'), ('cof_pour', 'صبّ صبّ'), ('cof_welcome', 'حيّاك'), ('cof_cold', 'بردت القهوة'), ('cof_dates', 'قهوة وتمر'), ('cof_enough', 'بس بس')]),
    dict(id='stk_angry', name='الزعل', rarity='rare', coins=3500, stickers=[
        ('ang_steam', 'معصّب'), ('ang_never', 'ما راح أسامح'), ('ang_upset', 'زعلت'), ('ang_bored', 'طفشت'), ('ang_ugh', 'أخ منكم'), ('ang_fist', 'تعال!')]),
    dict(id='stk_nervous', name='التوتر', rarity='rare', coins=3500, stickers=[
        ('nerv_sweat', 'أوبس'), ('nerv_cover', 'فشلة'), ('nerv_heart', 'قلبي يدق'), ('nerv_luck', 'يا حظي'), ('nerv_notme', 'مو أنا'), ('nerv_bite', 'يا ويلي')]),
    dict(id='stk_detective', name='المحقق', rarity='rare', coins=4000, stickers=[
        ('det_who', 'مين الخاين؟'), ('det_clue', 'عندي دليل'), ('det_watch', 'أراقبكم'), ('det_obvious', 'واضح مرة'), ('det_solved', 'انحلّت!'), ('det_hmm', 'فيه شي غلط')]),
    dict(id='stk_innocent', name='البريء', rarity='rare', coins=4000, stickers=[
        ('inn_me', 'أنا بريء!'), ('inn_cry', 'مظلوم'), ('inn_trust', 'ثقوا فيني'), ('inn_halo', 'ملاك'), ('inn_hands', 'ما سويت شي'), ('inn_pls', 'صدقوني')]),
    dict(id='stk_party', name='الاحتفال', rarity='epic', coins=5000, stickers=[
        ('par_kafu', 'كفو!'), ('par_won', 'فزنا!'), ('par_clap', 'تصفيق'), ('par_fireworks', 'يا سلام'), ('par_dance', 'رقصة النصر'), ('par_best', 'الأفضل')]),
    dict(id='stk_traitor', name='الخاين', rarity='epic', coins=6000, stickers=[
        ('tr_evil', 'ما عرفتوني'), ('tr_dagger', 'طعنة!'), ('tr_poker', 'وجه بوكر'), ('tr_plan', 'الخطة تمشي'), ('tr_mask', 'مين أنا؟'), ('tr_laugh', 'مواهاهاها')]),
    dict(id='stk_vip', name='الفخامة', rarity='legendary', diamonds=15, stickers=[
        ('vip_falcon', 'صقر'), ('vip_bisht', 'هيبة'), ('vip_gg', 'قيم مرتب'), ('vip_crown', 'على راسي'), ('vip_gold', 'ذهب'), ('vip_cool', 'رايق')]),
    dict(id='stk_hype', name='الحماس', rarity='epic', level=15, stickers=[
        ('hype_fire', 'ولّعت!'), ('hype_go', 'يلا!'), ('hype_strong', 'وحش'), ('hype_100', '١٠٠٪'), ('hype_rocket', 'طيران'), ('hype_eyes', 'ركّزوا')]),
    dict(id='stk_s1', name='الموسم الأول', rarity='epic', season='s1', stickers=[
        ('s1_night', 'سهرة!'), ('s1_champ', 'بطل الموسم'), ('s1_tea', 'شاي؟'), ('s1_lantern', 'نوّرت'), ('s1_sleep', 'نعسان'), ('s1_star', 'نجم المجلس')]),
    dict(id='stk_legend', name='الأساطير', rarity='legendary', level=35, stickers=[
        ('leg_king', 'الملك'), ('leg_genius', 'عبقري'), ('leg_ghost', 'اختفيت'), ('leg_mind', 'أقرأ أفكاركم'), ('leg_storm', 'عاصفة'), ('leg_legend', 'أسطورة')]),
]
PHRASE_PACK = dict(id='pack_phrases', name='سوالف المجلس', rarity='epic', coins=4000)

# ───────────── هدايا المستويات وأبطال الأسبوع ─────────────
LEVEL_REWARDS = [
    dict(level=5, coins=1000, diamonds=5, items=['bubble_lv5']),
    dict(level=10, coins=2000, diamonds=0, items=['frame_lv10', 'avatar_lv10']),
    dict(level=15, coins=3000, diamonds=10, items=['stk_hype']),
    dict(level=20, coins=4000, diamonds=0, items=['frame_lv20', 'avatar_lv20']),
    dict(level=25, coins=5000, diamonds=15, items=['bubble_lv25']),
    dict(level=30, coins=6000, diamonds=0, items=['frame_lv30', 'avatar_lv30']),
    dict(level=35, coins=7000, diamonds=20, items=['stk_legend']),
    dict(level=40, coins=8000, diamonds=0, items=['frame_lv40', 'avatar_lv40']),
    dict(level=45, coins=9000, diamonds=25, items=['bubble_lv45']),
    dict(level=50, coins=15000, diamonds=50, items=['frame_lv50', 'avatar_lv50']),
]
# بعد مستوى ٥٠: كل ٥ مستويات
LATE_REWARD = dict(every=5, coins=10000, diamonds=20)
CHAMPIONS = {1: dict(coins=5000, items=['frame_champ1', 'avatar_champ1']),
             2: dict(coins=3000, items=['frame_champ2', 'avatar_champ2']),
             3: dict(coins=1500, items=['frame_champ3', 'avatar_champ3'])}


# ───────────── الإنجازات ─────────────
# stat: الإحصائية اللي تنعد بعد كل لعبة (functions/src/achievements.ts). الدرجات: برونزي، فضي، ذهبي،
# وكل درجة لها ذهب. {n} في الوصف = الرقم المطلوب للدرجة.
ACHIEVEMENT_REWARDS = [150, 400, 1000]
ACHIEVEMENTS = [
    dict(id='games', stat='games', tiers=[10, 50, 200], name='ابن المجلس', desc='العب {n} لعبة', icon='games'),
    dict(id='loyal', stat='winsLoyal', tiers=[5, 25, 100], name='الوفي', desc='افز {n} مرة وأنت من الأوفياء', icon='innocent'),
    dict(id='traitor', stat='winsTraitor', tiers=[5, 25, 100], name='خاين محترف', desc='افز {n} مرة وأنت خاين', icon='liar'),
    dict(id='leader', stat='winsLeader', tiers=[1, 10, 30], name='الزعيم', desc='افز {n} مرة وأنت زعيم الخونة', icon='crown'),
    dict(id='hunter', stat='caught', tiers=[1, 10, 30], name='صياد الخونة', desc='اطرد {n} خاين وأنت الرئيس', icon='skull'),
    dict(id='detective', stat='found', tiers=[1, 10, 30], name='المحقق', desc='اكشف {n} خاين بالتحقيق', icon='search'),
    dict(id='minister', stat='loyalLaws', tiers=[5, 25, 100], name='وزير نزيه', desc='مرّر {n} قرار أزرق وأنت الوزير', icon='scales'),
    dict(id='streak', stat='bestStreak', tiers=[3, 5, 10], name='ما ينغلب', desc='افز {n} ألعاب ورا بعض', icon='fire'),
    dict(id='seer', stat='seerWins', tiers=[1, 5, 20], name='العرّاف', desc='افز {n} مرة وأنت العرّاف', icon='seer'),
    dict(id='guardian', stat='saved', tiers=[1, 5, 15], name='الحارس', desc='انجُ من الطرد {n} مرة وأنت الحارس', icon='shield'),
]


# ───────────── التصنيف (الطاولات العامة) ─────────────
# نقاط التصنيف تتصفّر كل موسم. أول ما توصل رتبة في الموسم تاخذ مكافأتها (مرة وحدة).
RANK_WIN, RANK_LOSS = 24, 16
RANK_TIERS = [
    dict(id='bronze', name='برونزي', min=0, coins=0, diamonds=0, color='CD7F32'),
    dict(id='silver', name='فضي', min=200, coins=1500, diamonds=0, color='C9D1DC'),
    dict(id='gold', name='ذهبي', min=500, coins=3000, diamonds=10, color='F2C14E'),
    dict(id='diamond', name='ماسي', min=900, coins=5000, diamonds=25, color='7DD8FF'),
    dict(id='legend', name='أسطوري', min=1400, coins=10000, diamonds=60, color='E879F9'),
]


# ───────────── الموسم (الباتل باس) ─────────────
def R(coins=0, diamonds=0, items=()):
    return dict(coins=coins, diamonds=diamonds, items=list(items))


SEASON = dict(
    id='s1', name='الموسم الأول: ليالي المجلس',
    # بداية ونهاية الموسم بتوقيت الخليج
    start='2026-10-25', end='2026-12-27',
    price=150,  # جواهر: المسار المدفوع ومعه bonus_tiers درجات هدية
    full_price=750,  # جواهر: الباتل باس كامل (كل الدرجات مفتوحة على طول)
    bonus_tiers=10,
    tier_points=150, tiers=30,
    free={2: R(300), 4: R(500), 6: R(diamonds=5), 8: R(800), 10: R(items=['bubble_s1f']), 12: R(1000), 14: R(diamonds=5),
          16: R(1200), 18: R(items=['frame_s1f']), 20: R(1500), 22: R(diamonds=10), 24: R(1800), 26: R(diamonds=10), 28: R(2000),
          30: R(3000, 15)},
    premium={1: R(items=['avatar_s1a']), 2: R(500), 3: R(1000), 4: R(diamonds=5), 5: R(items=['stk_s1']), 6: R(1000),
             7: R(diamonds=10), 8: R(1500), 9: R(items=['bubble_s1']), 10: R(items=['frame_s1a']), 11: R(1500),
             12: R(items=['cards_s1']), 13: R(diamonds=10), 14: R(2000), 15: R(items=['avatar_s1b']), 16: R(2000),
             17: R(diamonds=15), 18: R(items=['table_s1']), 19: R(2500), 20: R(items=['frame_s1b']), 21: R(2500),
             22: R(diamonds=15), 23: R(3000), 24: R(items=['bubble_s1b']), 25: R(diamonds=20), 26: R(3500), 27: R(4000),
             28: R(diamonds=25), 29: R(5000), 30: R(diamonds=30, items=['avatar_s1c', 'frame_s1c'])},
)


# ═════════════════════════ التوليد ═════════════════════════
def items():
    """كل الأغراض بصيغة وحدة: (المعرف، النوع، القاموس)."""
    out = []
    for f in FRAMES: out.append(('frame', f['id'], f))
    for b in BUBBLES: out.append(('bubble', b['id'], b))
    for d in DEATHS: out.append(('death', d['id'], d))
    for a in AVATARS: out.append(('avatar', 'avatar_' + a['id'], a))
    for t in TABLES: out.append(('table', t['id'], t))
    for c in CARDS: out.append(('cards', c['id'], c))
    for p in STICKER_PACKS: out.append(('reactions', p['id'], p))
    out.append(('reactions', PHRASE_PACK['id'], PHRASE_PACK))
    return out


def check():
    ids = [i for _, i, _ in items()]
    assert len(ids) == len(set(ids)), 'معرف مكرر'
    stickers = [s for p in STICKER_PACKS for s, _ in p['stickers']]
    texts = [t['id'] for t in TEXT_REACTIONS]
    assert len(stickers + texts) == len(set(stickers + texts)), 'رد مكرر'
    known = set(ids)
    for r in LEVEL_REWARDS:
        for it in r['items']: assert it in known, it
    for c in CHAMPIONS.values():
        for it in c['items']: assert it in known, it
    assert [t['min'] for t in RANK_TIERS] == sorted(t['min'] for t in RANK_TIERS) and RANK_TIERS[0]['min'] == 0
    ach = [a['id'] for a in ACHIEVEMENTS]
    assert len(ach) == len(set(ach)), 'إنجاز مكرر'
    for a in ACHIEVEMENTS:
        assert len(a['tiers']) == len(ACHIEVEMENT_REWARDS) and a['tiers'] == sorted(a['tiers']), a['id']
    for track in ('free', 'premium'):
        for t, r in SEASON[track].items():
            assert 1 <= t <= SEASON['tiers']
            for it in r['items']: assert it in known, it
    for slot, i, d in items():
        kinds = [k for k in ('default', 'coins', 'diamonds', 'level', 'champion', 'season') if k in d]
        assert len(kinds) == 1, (i, kinds)


def ts():
    L = ['// مولّد من tools/catalog/catalog.py — لا تعدله باليد.', '',
         "export type Slot = 'frame' | 'avatar' | 'table' | 'cards' | 'bubble' | 'death' | 'reactions';",
         "/** الأغراض اللي تنلبس (واحد بس من كل نوع). */",
         "export type EquipSlot = 'frame' | 'cards' | 'table' | 'bubble' | 'death';", '',
         'export interface CatalogItem {', '  id: string;', '  slot: Slot;', '  coins?: number;', '  diamonds?: number;',
         '  /** يجي هدية في هذا المستوى (ما ينشرى). */', '  level?: number;',
         '  /** لأبطال الأسبوع (المركز)، لمدة أسبوع. */', '  champion?: number;',
         '  /** من الباتل باس لهذا الموسم. */', '  season?: string;', '}', '']
    defaults = {s: d['id'] for s, _, d in items() if d.get('default') and s in ('frame', 'cards', 'table', 'bubble', 'death')}
    L.append('export const DEFAULT_EQUIPPED: Record<EquipSlot, string> = ' + json.dumps(defaults, ensure_ascii=False) + ';')
    L.append('')
    L.append('export const CATALOG: CatalogItem[] = [')
    for slot, i, d in items():
        if d.get('default'): continue
        o = {'id': i, 'slot': slot}
        for k in ('coins', 'diamonds', 'level', 'champion', 'season'):
            if k in d: o[k] = d[k]
        L.append('  ' + json.dumps(o, ensure_ascii=False) + ',')
    L.append('];')
    L.append('')
    L.append('/** الشخصيات المجانية (assets/avatars). الباقي من الكتالوج: avatar_<الاسم>. */')
    L.append('export const FREE_AVATARS = ' + json.dumps(FREE_AVATARS) + ';')
    L.append('')
    L.append('/** الردود المسموحة: target = لازم يختار لاعب، pack = لازم يملك الباقة، sticker = ملصق (ينرسل في الدردشة بعد). */')
    L.append('export const REACTIONS: Record<string, { target: boolean; pack?: string; sticker?: boolean }> = {')
    for t in TEXT_REACTIONS:
        o = {'target': t['target']}
        if 'pack' in t: o['pack'] = t['pack']
        L.append(f"  {t['id']}: {json.dumps(o)},")
    for p in STICKER_PACKS:
        for s, _ in p['stickers']:
            o = {'target': False, 'sticker': True}
            if not p.get('default'): o['pack'] = p['id']
            L.append(f"  {s}: {json.dumps(o)},")
    L.append('};')
    L.append('')
    L.append('export interface Reward {\n  coins: number;\n  diamonds: number;\n  items: string[];\n}')
    L.append('export const LEVEL_REWARDS: (Reward & { level: number })[] = [')
    for r in LEVEL_REWARDS: L.append('  ' + json.dumps(r, ensure_ascii=False) + ',')
    L.append('];')
    L.append(f"export const LATE_REWARD = {json.dumps(LATE_REWARD)};")
    L.append('export const CHAMPION_REWARDS: Record<number, Reward> = {')
    for k, v in CHAMPIONS.items(): L.append(f"  {k}: {json.dumps(dict(coins=v['coins'], diamonds=0, items=v['items']))},")
    L.append('};')
    L.append('')
    L.append('/** الإنجازات: الإحصائية اللي تنعد، والأرقام المطلوبة لكل درجة (برونزي، فضي، ذهبي). */')
    L.append('export const ACHIEVEMENTS: { id: string; stat: string; tiers: number[] }[] = [')
    for a in ACHIEVEMENTS: L.append('  ' + json.dumps({k: a[k] for k in ('id', 'stat', 'tiers')}) + ',')
    L.append('];')
    L.append(f'/** ذهب كل درجة. */\nexport const ACHIEVEMENT_REWARDS = {json.dumps(ACHIEVEMENT_REWARDS)};')
    L.append('')
    L.append('/** التصنيف: نقاط الفوز والخسارة، ورتب الموسم (أقل نقاط لكل رتبة ومكافأة أول وصول لها). */')
    L.append(f'export const RANK_WIN = {RANK_WIN};')
    L.append(f'export const RANK_LOSS = {RANK_LOSS};')
    L.append('export const RANK_TIERS: { id: string; min: number; coins: number; diamonds: number }[] = [')
    for t in RANK_TIERS: L.append('  ' + json.dumps({k: t[k] for k in ('id', 'min', 'coins', 'diamonds')}) + ',')
    L.append('];')
    L.append('')
    L.append('/** الموسم الحالي (الباتل باس). start/end بتوقيت الخليج، والمكافآت حسب الدرجة. */')
    season = {k: SEASON[k] for k in ('id', 'start', 'end', 'price', 'full_price', 'bonus_tiers', 'tier_points', 'tiers')}
    season['free'] = {str(k): v for k, v in SEASON['free'].items()}
    season['premium'] = {str(k): v for k, v in SEASON['premium'].items()}
    L.append('export const SEASON = ' + json.dumps(season, ensure_ascii=False) + ' as {')
    L.append('  id: string; start: string; end: string; price: number; full_price: number; bonus_tiers: number;')
    L.append('  tier_points: number; tiers: number;')
    L.append('  free: Record<string, Reward>; premium: Record<string, Reward>;')
    L.append('};')
    return '\n'.join(L) + '\n'


def col(h):
    return f'Color(0xFF{h.upper()})'


def cols(hs):
    return '[' + ', '.join(col(h) for h in hs) + ']'


def dstr(s):
    return "'" + s.replace("\\", "\\\\").replace("'", "\\'") + "'"


def price(d):
    out = []
    for k in ('coins', 'diamonds', 'level', 'champion'):
        if k in d: out.append(f'{k}: {d[k]}')
    if 'season' in d: out.append(f"season: {dstr(d['season'])}")
    return out


def dart():
    L = ['// مولّد من tools/catalog/catalog.py — لا تعدله باليد.', '// ignore_for_file: lines_longer_than_80_chars', '',
         "import 'package:flutter/material.dart';", '', "import 'achievements.dart';", "import 'shop.dart';", '']
    L.append('const catalog = <ShopItem>[')
    for slot, i, d in items():
        args = [f'id: {dstr(i)}', f'slot: ShopSlot.{slot}', f'name: {dstr(d["name"])}', f'rarity: Rarity.{d["rarity"]}'] + price(d)
        if slot == 'frame' and 'sig' in d:
            motion = 'glint' if d['rarity'] == 'rare' else 'live'
            args.append(f'frame: FrameStyle({dstr(d["sig"])}, motion: FrameMotion.{motion})')
        if slot == 'death':
            args.append(f'death: DeathFx.{d["fx"]}')
        if slot == 'bubble':
            fx = ', '.join('BubbleFx.' + f for f in d['fx'])
            args.append(f'bubble: BubbleStyle(bg: {cols(d["bg"])}, border: {col(d["border"])}, text: {col(d["text"])}, fx: [{fx}])')
        if slot == 'avatar':
            args.append(f'avatar: {dstr(d["id"])}')
            anim = f', anim: {dstr(d["anim"])}' if 'anim' in d else ''
            args.append(f'avatarArt: AvatarArt({cols(d["bg"])}, AvatarFx.{d["fx"]}{anim})')
        if 'desc' in d:
            args.append(f'desc: {dstr(d["desc"])}')
        if slot == 'table':
            args.append('table: TableSkin.majlis' if d['art'] == 'majlis' else f'table: TableSkin.of({dstr(d["art"])})')
        if slot == 'cards' and 'loyal' in d:
            args.append(f'cards: CardSkin(loyal: {cols(d["loyal"])}, traitor: {cols(d["traitor"])}, loyalIcon: {dstr(d["icons"][0])}, traitorIcon: {dstr(d["icons"][1])}, border: {col(d["border"])})')
        if slot == 'reactions':
            if 'stickers' in d:
                args.append('stickers: [' + ', '.join(dstr(s) for s, _ in d['stickers']) + ']')
            else:
                args.append('phrases: true')
        L.append('  ShopItem(' + ', '.join(args) + '),')
    L.append('];')
    L.append('')
    L.append('/// الشخصيات المجانية (نفس functions/src/catalog.ts → FREE_AVATARS).')
    L.append('const freeAvatars = [' + ', '.join(dstr(a) for a in FREE_AVATARS) + '];')
    L.append('')
    L.append('const stickers = <Sticker>[')
    for p in STICKER_PACKS:
        for s, cap in p['stickers']:
            L.append(f"  Sticker({dstr(s)}, {dstr(p['id'])}, {dstr(cap)}),")
    L.append('];')
    L.append('')
    L.append('const textReactions = <TextReaction>[')
    for t in TEXT_REACTIONS:
        args = [dstr(t['id']), dstr(t['label']), dstr(t['say'])]
        if t['target']: args.append('target: true')
        if 'pack' in t: args.append(f"pack: {dstr(t['pack'])}")
        if 'icon' in t: args.append(f"icon: {dstr(t['icon'])}")
        L.append('  TextReaction(' + ', '.join(args) + '),')
    L.append('];')
    L.append('')
    L.append('const levelRewards = <LevelReward>[')
    for r in LEVEL_REWARDS:
        L.append(f"  LevelReward({r['level']}, coins: {r['coins']}, diamonds: {r['diamonds']}, items: [" + ', '.join(dstr(x) for x in r['items']) + ']),')
    L.append('];')
    L.append(f"const lateReward = (every: {LATE_REWARD['every']}, coins: {LATE_REWARD['coins']}, diamonds: {LATE_REWARD['diamonds']});")
    L.append('')
    L.append('const championRewards = <int, LevelReward>{')
    for k, v in CHAMPIONS.items():
        L.append(f"  {k}: LevelReward(0, coins: {v['coins']}, items: [" + ', '.join(dstr(x) for x in v['items']) + ']),')
    L.append('};')
    L.append('')
    def rw(t, r):
        return f"LevelReward({t}, coins: {r['coins']}, diamonds: {r['diamonds']}, items: [" + ', '.join(dstr(x) for x in r['items']) + '])'
    L.append('/// الإنجازات (نفس functions/src/catalog.ts → ACHIEVEMENTS).')
    L.append('const achievements = <Achievement>[')
    for a in ACHIEVEMENTS:
        L.append(f"  Achievement({dstr(a['id'])}, stat: {dstr(a['stat'])}, tiers: {a['tiers']}, name: {dstr(a['name'])}, desc: {dstr(a['desc'])}, icon: {dstr(a['icon'])}),")
    L.append('];')
    L.append(f"const achievementRewards = {ACHIEVEMENT_REWARDS};")
    L.append('')
    L.append('/// رتب التصنيف (نفس functions/src/catalog.ts → RANK_TIERS).')
    L.append('const rankTiers = <RankTier>[')
    for i, t in enumerate(RANK_TIERS):
        L.append(f"  RankTier({i}, id: {dstr(t['id'])}, name: {dstr(t['name'])}, min: {t['min']}, coins: {t['coins']}, diamonds: {t['diamonds']}, color: {col(t['color'])}),")
    L.append('];')
    L.append(f'const rankWin = {RANK_WIN};')
    L.append(f'const rankLoss = {RANK_LOSS};')
    L.append('')
    L.append('/// الموسم الحالي (الباتل باس). نفس functions/src/catalog.ts → SEASON.')
    L.append('final season = Season(')
    L.append(f"  id: {dstr(SEASON['id'])},")
    L.append(f"  name: {dstr(SEASON['name'])},")
    L.append(f"  start: DateTime.utc({', '.join(str(int(x)) for x in SEASON['start'].split('-'))}).subtract(const Duration(hours: 3)),")
    L.append(f"  end: DateTime.utc({', '.join(str(int(x)) for x in SEASON['end'].split('-'))}).subtract(const Duration(hours: 3)),")
    L.append(f"  price: {SEASON['price']},")
    L.append(f"  fullPrice: {SEASON['full_price']},")
    L.append(f"  bonusTiers: {SEASON['bonus_tiers']},")
    L.append(f"  tierPoints: {SEASON['tier_points']},")
    L.append(f"  tiers: {SEASON['tiers']},")
    L.append('  free: {' + ', '.join(f'{t}: {rw(t, r)}' for t, r in SEASON['free'].items()) + '},')
    L.append('  premium: {' + ', '.join(f'{t}: {rw(t, r)}' for t, r in SEASON['premium'].items()) + '},')
    L.append(');')
    return '\n'.join(L) + '\n'


if __name__ == '__main__':
    check()
    open(os.path.join(ROOT, 'functions/src/catalog.ts'), 'w').write(ts())
    open(os.path.join(ROOT, 'app/lib/models/catalog.dart'), 'w').write(dart())
    n = len(items())
    print(f'catalog: {n} items, {sum(len(p["stickers"]) for p in STICKER_PACKS)} stickers, {len(TEXT_REACTIONS)} phrases')
