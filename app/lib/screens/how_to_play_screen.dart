import 'package:flutter/material.dart';

import '../models/game_view.dart';
import '../models/profile.dart';
import '../models/shop.dart';
import '../services/backend.dart';
import '../services/sfx.dart';
import '../services/telemetry.dart';
import '../theme.dart';
import '../widgets/bubble.dart';
import '../widgets/common.dart';
import '../widgets/curtain_route.dart';
import '../widgets/game/policy_card.dart';
import '../widgets/design.dart';
import '../widgets/design_social.dart';
import '../widgets/game/tracks.dart';
import '../widgets/ui.dart' show LeaderSeal, Seal;
import 'game_screen.dart';

/// مكافأة أول لعبة شرح (نفس functions/src/economy.ts → TUTORIAL_REWARD).
const tutorialReward = 500;

/// يبدأ لعبة الشرح (أنت و٤ بوتات) ويفتح الطاولة. [replace]: الطاولة تاخذ مكان صفحة الشرح
/// (الشرح الإجباري، عشان بعد اللعبة يرجع للرئيسية).
Future<void> startTutorialGame(BuildContext context, {bool replace = false}) async {
  final backend = Backend.instance;
  if (!backend.isReady) return;
  final navigator = Navigator.of(context);
  final messenger = ScaffoldMessenger.of(context);
  showSocDialog<void>(
    context,
    title: 'الشرح',
    width: 380,
    dismissible: false,
    builder: (_) => const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(color: AppColors.goldDark),
        SizedBox(width: 16),
        SocPopupText('نجهّز مجلس الشرح…'),
      ],
    ),
  );
  try {
    final code = await backend.startTutorial();
    Telemetry.tutorialBegin();
    navigator.pop();
    final route = curtainRoute<void>((_) => GameScreen(code: code));
    replace ? navigator.pushReplacement(route) : navigator.push(route);
  } on BackendException catch (e) {
    navigator.pop();
    messenger.showSnackBar(SnackBar(content: Text(e.message)));
  }
}

/// لاعب جديد (ما خلّص الشرح ولا لعب): لازم يقرا القوانين ويلعب لعبة الشرح قبل ما يلعب، إلا إذا تخطّاه بنفسه.
bool needsOnboarding(Profile p) =>
    Backend.instance.isReady && p.setupDone && !p.tutorialDone && !p.tutorialSkipped && p.gamesPlayed == 0;

/// يفتح الشرح الإجباري لو لازم. يرجع true لو يقدر يكمل للعب (خلّصه من قبل، أو تخطّاه الحين).
Future<bool> ensureOnboarded(BuildContext context) async {
  if (!needsOnboarding(Backend.instance.profile.value)) return true;
  final skipped = await Navigator.of(context)
      .push<bool>(MaterialPageRoute(builder: (_) => const HowToPlayScreen(onboarding: true)));
  return skipped == true || !needsOnboarding(Backend.instance.profile.value);
}

/// صفحة شرح: نص (وفيه نقاط لها عنوان ملوّن) وملاحظة مهمة، ورسمة، وجملة الراوي اللي تقراها.
typedef _Slide = ({
  String voice,
  String title,
  String body,
  List<(String, String, Color)> points,
  String? note,
  Widget art,
});

/// كيف ألعب: فكرة اللعبة وقوانينها في ٧ صفحات قصيرة، والراوي يقرا كل صفحة، وآخرها تبدأ لعبة الشرح.
class HowToPlayScreen extends StatefulWidget {
  const HowToPlayScreen({super.key, this.onboarding = false});

  /// الشرح الإجباري للاعب الجديد: ما يطلع منه إلا بلعبة الشرح أو «تخطّي» بتأكيد.
  final bool onboarding;

  @override
  State<HowToPlayScreen> createState() => _HowToPlayScreenState();
}

class _HowToPlayScreenState extends State<HowToPlayScreen> {
  final _pages = PageController();
  int _page = 0;

  static final List<_Slide> _slides = [
    (
      voice: 'how_1',
      title: 'فكرة اللعبة',
      body:
          'تنقسم اللعبة إلى فريقين: الأوفياء والخونة. لكل فريق هدف مختلف، وهويات اللاعبين سرية.\n'
          'مهمتك هي مساعدة فريقك على الفوز، ومعرفة من يقف في صفك ومن يعارضك.',
      points: const [],
      note: null,
      art: const _WelcomeArt(),
    ),
    (
      voice: 'how_2',
      title: 'الأدوار',
      body: '',
      points: const [
        ('الأوفياء', 'هدفهم الفوز وإيقاف الخونة.', AppColors.loyalLight),
        ('الخونة', 'يعملون سرًا لتحقيق الفوز دون كشف هوياتهم.', AppColors.traitorLight),
        (
          'زعيم الخونة',
          'الشخصية التي يسعى الخونة لإيصالها إلى منصب الوزير بعد تمرير ٣ قرارات حمراء.',
          AppColors.traitorLight,
        ),
        (
          'الطور المطوّر',
          'الطور الكلاسيكي فيه الزعيم والخونة والأوفياء بس. وفي الطور المطوّر: بعض الأوفياء لهم دور خاص (العرّاف أو الحارس)، '
              'وفيه أدوار لأي لاعب إلا الزعيم: القاضي يلغي تصويت مرة، والشيخ صوته بصوتين، والجاسوس يشوف أول كرت '
              'بالكومة مرة. شرح دورك يظهر في بطاقتك.',
          AppColors.gold,
        ),
      ],
      note: null,
      art: const _TeamsArt(),
    ),
    (
      voice: 'how_3',
      title: 'كيف يفوز كل فريق؟',
      body: '',
      points: const [
        ('الأوفياء', 'يفوزون بتمرير ٥ قرارات للأوفياء، أو بإقصاء زعيم الخونة.', AppColors.loyalLight),
        (
          'الخونة',
          'يفوزون بتمرير ٦ قرارات للخونة، أو بإيصال زعيمهم إلى منصب الوزير بعد تمرير ٣ قرارات للخونة.',
          AppColors.traitorLight,
        ),
      ],
      note: null,
      art: const _WinArt(),
    ),
    (
      voice: 'how_4',
      title: 'اختيار الحكومة',
      body:
          'في كل جولة، يختار الرئيس لاعبًا ليكون الوزير. بعد ذلك، يصوّت الجميع على قبول الحكومة أو رفضها.\n'
          'إذا رُفضت، تنتقل الرئاسة إلى اللاعب التالي. وإذا رُفضت ٣ حكومات متتالية، يُمرَّر أول قرار في الكومة تلقائيًا.',
      points: const [],
      note: null,
      art: const _GovernmentArt(),
    ),
    (
      voice: 'how_5',
      title: 'تمرير القرارات',
      body:
          'بعد قبول الحكومة، يسحب الرئيس ٣ قرارات، ويختار منها قرارين ليرسلهما إلى الوزير. '
          'بعدها يختار الوزير قرارًا واحدًا لتمريره، ويتخلص من الثاني.',
      points: const [],
      note: 'مهم: اختيارات الرئيس والوزير سرية، ويقدر أي واحد منهم يكذب!',
      art: const _PassArt(),
    ),
    (
      voice: 'how_6',
      title: 'كيف تكتشف الخونة؟',
      body:
          'راقب اختيارات اللاعبين وتصويتاتهم، والقرارات التي تمرّرها الحكومات.\n'
          'قارن أقوال اللاعبين بأفعالهم، وحاول اتخاذ اختياراتك بناءً على ما يحدث خلال اللعبة.',
      points: const [],
      note: null,
      art: const _DetectArt(),
    ),
    (
      voice: 'how_7',
      title: 'القدرات الخاصة',
      body: 'بعض القرارات الحمراء تعطي الرئيس قدرة خاصة:',
      points: const [
        ('التحقيق', 'يكشف إذا كان اللاعب وفيًا أو خائنًا، لكن لا يكشف إذا كان زعيم الخونة.', AppColors.gold),
        ('الطرد', 'إخراج لاعب من اللعبة نهائيًا.', AppColors.gold),
        ('التلصص', 'الاطلاع على القرارات الثلاثة القادمة.', AppColors.gold),
        ('الانتخاب الخاص', 'يختار الرئيس من يكون الرئيس القادم.', AppColors.gold),
        (
          'حق النقض',
          'بعد ٥ قرارات حمراء، يطلب الوزير رفض القرارين، وإذا وافق الرئيس تُلغى الحكومة وتنتقل الرئاسة للاعب التالي.',
          AppColors.gold,
        ),
      ],
      note: null,
      art: const _PowersArt(),
    ),
    (
      voice: 'how_8',
      title: 'حان وقت اللعب!',
      body: 'أصبحت تعرف الأساسيات، والآن حان وقت اللعب!',
      points: const [],
      note: null,
      art: const _ReadyArt(),
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _say(0));
  }

  @override
  void dispose() {
    Sfx.hush();
    _pages.dispose();
    super.dispose();
  }

  void _say(int i) {
    Sfx.hush();
    Sfx.say(_slides[i].voice);
  }

  void _go(int i) => _pages.animateToPage(i, duration: const Duration(milliseconds: 380), curve: Curves.easeOutCubic);

  /// يتخطى الشرح الإجباري بعد ما يأكد (يعرف يلعب، أو حساب جديد على جوال جديد).
  Future<void> _skip() async {
    final sure = await showSocDialog<bool>(
      context,
      title: 'تتخطى الشرح؟',
      width: 480,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SocPopupText(
            'الشرح يعلّمك اللعبة في كم دقيقة، ولما تخلص لعبة الشرح تاخذ ${arabicNumber(tutorialReward)} ذهب.\n'
            'تخطّه بس إذا تعرف تلعب (مثلاً نقلت لجوال جديد أو سوّيت حساب جديد).',
            size: 14.5,
          ),
          const SizedBox(height: 14),
          SocActions(
            children: [
              SocButton(
                label: 'تخطّي',
                tone: SocTone.grey,
                height: 44,
                fontSize: 16,
                onPressed: () => Navigator.pop(context, true),
              ),
              SocButton(
                label: 'أكمل الشرح',
                tone: SocTone.green,
                height: 44,
                fontSize: 16,
                onPressed: () => Navigator.pop(context, false),
              ),
            ],
          ),
        ],
      ),
    );
    if (sure != true || !mounted) return;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await Backend.instance.skipTutorial();
      Sfx.hush();
      navigator.pop(true);
    } on BackendException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final last = _page == _slides.length - 1;
    final onboarding = widget.onboarding;
    return PopScope(
      canPop: !onboarding,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _skip();
      },
      child: WoodWall(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Gfx('guide', size: 34),
                      const SizedBox(width: 8),
                      GoldTitle(onboarding ? 'أهلاً في المجلس!' : 'كيف ألعب؟', size: 26),
                      if (onboarding) ...[
                        const SizedBox(width: 12),
                        Flexible(
                          child: SocChip(
                            last ? 'الخطوة ٢ من ٢: لعبة تجريبية مع البوتات' : 'الخطوة ١ من ٢: تعلّم القوانين',
                            kind: SocChipKind.gold,
                          ),
                        ),
                      ],
                      const Spacer(),
                      if (onboarding)
                        SocButton(label: 'تخطّي الشرح', tone: SocTone.grey, height: 34, fontSize: 14, onPressed: _skip)
                      else
                        SocButton(
                          label: 'إغلاق',
                          tone: SocTone.red,
                          icon: const Gfx('cross', size: 20),
                          height: 34,
                          fontSize: 14,
                          onPressed: () => Navigator.of(context).maybePop(),
                        ),
                    ],
                  ),
                  Expanded(
                    child: PageView(
                      controller: _pages,
                      onPageChanged: (i) {
                        setState(() => _page = i);
                        _say(i);
                      },
                      children: [for (final s in _slides) _SlideView(slide: s)],
                    ),
                  ),
                  Row(
                    children: [
                      SizedBox(
                        width: 130,
                        child: _page == 0
                            ? null
                            : SocButton(
                                label: 'السابق',
                                tone: SocTone.grey,
                                height: 42,
                                fontSize: 16,
                                onPressed: () => _go(_page - 1),
                              ),
                      ),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (var i = 0; i < _slides.length; i++)
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                width: i == _page ? 24 : 9,
                                height: 9,
                                decoration: BoxDecoration(
                                  color: i == _page ? const Color(0xFFF2B33E) : const Color(0xFF3A231B),
                                  border: Border.all(color: const Color(0xFF160B06), width: 1.6),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: last ? 230 : 130,
                        child: last
                            ? SocButton(
                                label: 'يالله نجرّب!',
                                semantics: 'ابدأ لعبة الشرح',
                                icon: const Gfx('games', size: 26),
                                tone: SocTone.green,
                                height: 44,
                                fontSize: 18,
                                onPressed: () {
                                  Sfx.hush();
                                  startTutorialGame(context, replace: onboarding);
                                },
                              )
                            : SocButton(
                                label: 'التالي',
                                tone: SocTone.orange,
                                height: 42,
                                fontSize: 17,
                                onPressed: () => _go(_page + 1),
                              ),
                      ),
                    ],
                  ),
                  ValueListenableBuilder(
                    valueListenable: Backend.instance.profile,
                    builder: (context, p, _) => AnimatedSize(
                      duration: const Duration(milliseconds: 200),
                      child: last && !p.tutorialDone
                          ? Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Amount(
                                'coin',
                                'خلّص لعبة الشرح وخذ ${arabicNumber(tutorialReward)} ذهب',
                                size: 18,
                                style: const TextStyle(
                                  color: socGoldHi,
                                  fontFamily: kufi,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                            )
                          : const SizedBox(width: double.infinity),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide});

  final _Slide slide;

  static const _text = TextStyle(
    fontFamily: kufi,
    fontSize: 15.5,
    height: 1.6,
    fontWeight: FontWeight.w700,
    color: socCream,
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: VelvetPanel(
              padding: const EdgeInsets.all(12),
              child: Center(child: FittedBox(child: slide.art)),
            ),
          ),
          const SizedBox(width: 18),
          // النص يتمرر لو طال على الشاشات الصغيرة.
          Expanded(
            flex: 6,
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GoldTitle(slide.title, size: 26, align: TextAlign.start),
                    const SizedBox(height: 8),
                    if (slide.body.isNotEmpty) Text(slide.body, style: _text),
                    for (final (label, text, color) in slide.points)
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              margin: const EdgeInsets.only(top: 9, left: 7, right: 7),
                              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                            ),
                            Expanded(
                              child: Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '$label: ',
                                      style: TextStyle(color: color, fontWeight: FontWeight.w900),
                                    ),
                                    TextSpan(text: text),
                                  ],
                                ),
                                style: _text,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (slide.note case final note?)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: SocCard(
                          gold: true,
                          padding: const EdgeInsets.fromLTRB(10, 6, 12, 6),
                          child: Row(
                            children: [
                              const Gfx('warning', size: 24),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  note,
                                  style: _text.copyWith(color: socGoldHi, fontWeight: FontWeight.w800),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 10),
                    _Replay(voice: slide.voice),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// زر صغير يعيد جملة الراوي (أو يشغّل صوته لو مسكّت).
class _Replay extends StatelessWidget {
  const _Replay({required this.voice});

  final String voice;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const PlayerAvatar(avatar: 'sheikh', size: 30),
      const SizedBox(width: 8),
      ValueListenableBuilder(
        valueListenable: Sfx.muted,
        builder: (context, muted, _) => GestureDetector(
          onTap: () {
            if (muted) {
              Sfx.toggle().then((_) => Sfx.say(voice));
            } else {
              Sfx.hush();
              Sfx.say(voice);
            }
          },
          child: Row(
            children: [
              Gfx(muted ? 'mute' : 'sound', size: 22),
              const SizedBox(width: 4),
              Text(
                muted ? 'شغّل صوت الراوي' : 'اسمعها مرة ثانية',
                style: const TextStyle(color: socMuted, fontSize: 13, fontFamily: kufi, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

/// اسم صغير تحت الرسمة.
class _Caption extends StatelessWidget {
  const _Caption(this.text, {this.color = AppColors.text});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Text(
      text,
      style: TextStyle(fontFamily: kufi, fontSize: 15, fontWeight: FontWeight.w700, color: color),
    ),
  );
}

class _WelcomeArt extends StatelessWidget {
  const _WelcomeArt();

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 330,
    height: 200,
    child: Stack(
      children: [
        const Positioned(left: 0, top: 50, child: PlayerAvatar(avatar: 'pearl', size: 96)),
        const Positioned(right: 0, top: 50, child: PlayerAvatar(avatar: 'desert', size: 96)),
        const Positioned(
          left: 98,
          top: 14,
          child: PlayerAvatar(avatar: 'masked', frame: AppColors.traitor, size: 124),
        ),
        for (final (x, y, s) in const [(30.0, 8.0, 34.0), (282.0, 20.0, 28.0), (160.0, 156.0, 30.0)])
          Positioned(
            left: x,
            top: y,
            child: Text(
              '؟',
              style: TextStyle(fontFamily: kufi, fontSize: s, color: AppColors.gold, fontWeight: FontWeight.w700),
            ),
          ),
      ],
    ),
  );
}

class _TeamsArt extends StatelessWidget {
  const _TeamsArt();

  @override
  Widget build(BuildContext context) => const Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Column(
        children: [
          Row(children: [Seal(loyal: true, size: 64), Seal(loyal: true, size: 84), Seal(loyal: true, size: 64)]),
          _Caption('الأوفياء (الأكثر)', color: AppColors.loyalLight),
        ],
      ),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 18),
        child: Text(
          'ضد',
          style: TextStyle(fontFamily: kufi, fontSize: 22, color: AppColors.muted),
        ),
      ),
      Column(
        children: [
          Row(children: [Seal(loyal: false, size: 64), LeaderSeal(size: 88)]),
          _Caption('الخونة وزعيمهم', color: AppColors.traitorLight),
        ],
      ),
    ],
  );
}

class _GovernmentArt extends StatelessWidget {
  const _GovernmentArt();

  @override
  Widget build(BuildContext context) {
    Widget chip(String icon, String label, Color color) => Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 14, 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 2),
      ),
      child: Row(
        children: [
          Gfx(icon, size: 26),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontFamily: kufi, fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Column(
              children: [
                Gfx('crown', size: 40),
                PlayerAvatar(avatar: 'emir', frame: AppColors.gold, size: 88),
                _Caption('الرئيس', color: AppColors.gold),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 60),
              child: Transform.flip(
                flipX: Directionality.of(context) == TextDirection.rtl,
                child: const Gfx('pick', size: 44),
              ),
            ),
            const Column(
              children: [
                PlayerAvatar(avatar: 'scholar', frame: AppColors.loyalLight, size: 88),
                _Caption('الوزير', color: AppColors.loyalLight),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            chip('check', 'موافق', AppColors.green),
            const SizedBox(width: 12),
            chip('cross', 'رافض', AppColors.traitor),
          ],
        ),
      ],
    );
  }
}

/// صف نتيجة: أيقونة، وكيف يفوز الفريق، وختمه.
class _Outcome extends StatelessWidget {
  const _Outcome(this.icon, this.text, {required this.loyal});

  final String icon;
  final String text;
  final bool loyal;

  @override
  Widget build(BuildContext context) => Container(
    width: 250,
    margin: const EdgeInsets.symmetric(vertical: 4),
    padding: const EdgeInsets.fromLTRB(10, 7, 12, 7),
    decoration: BoxDecoration(
      color: (loyal ? AppColors.loyal : AppColors.traitor).withValues(alpha: .18),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: loyal ? AppColors.loyalLight : AppColors.traitorLight, width: 1.6),
    ),
    child: Row(
      children: [
        Gfx(icon, size: 30),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, height: 1.35)),
        ),
        Seal(loyal: loyal, size: 32),
      ],
    ),
  );
}

/// كيف يفوز كل فريق: طريقتين لكل واحد.
class _WinArt extends StatelessWidget {
  const _WinArt();

  @override
  Widget build(BuildContext context) => const Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      _Outcome('check', '٥ قرارات للأوفياء', loyal: true),
      _Outcome('dagger', 'إقصاء زعيم الخونة', loyal: true),
      SizedBox(height: 8),
      _Outcome('check', '٦ قرارات للخونة', loyal: false),
      _Outcome('warning', 'الزعيم وزير بعد ٣ قرارات حمراء', loyal: false),
    ],
  );
}

/// ٣ كروت عند الرئيس ← كرتين للوزير ← قرار واحد يتمرر.
class _PassArt extends StatelessWidget {
  const _PassArt();

  @override
  Widget build(BuildContext context) {
    Widget cards(List<Policy> list, {double width = 50, double opacity = 1}) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final p in list)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Opacity(
              opacity: opacity,
              child: PolicyCard(policy: p, width: width),
            ),
          ),
      ],
    );
    Widget arrow() => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Transform.flip(flipX: Directionality.of(context) == TextDirection.rtl, child: const Gfx('pick', size: 34)),
    );
    Widget step(Widget top, Widget cardsRow, String label, Color color) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        top,
        const SizedBox(height: 6),
        cardsRow,
        _Caption(label, color: color),
      ],
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        step(
          const PlayerAvatar(avatar: 'emir', frame: AppColors.gold, size: 64),
          cards(const [Policy.traitor, Policy.loyal, Policy.traitor]),
          'الرئيس يسحب ٣',
          AppColors.gold,
        ),
        arrow(),
        step(
          const PlayerAvatar(avatar: 'scholar', frame: AppColors.loyalLight, size: 64),
          cards(const [Policy.loyal, Policy.traitor]),
          'الوزير ياخذ ٢',
          AppColors.loyalLight,
        ),
        arrow(),
        step(const Seal(loyal: true, size: 64), cards(const [Policy.loyal], width: 58), 'يتمرر ١', AppColors.text),
      ],
    );
  }
}

/// راقب الكلام والتصويت: واحد يدّعي (ويمكن يكذب)، وتحته تصويت الطاولة.
class _DetectArt extends StatelessWidget {
  const _DetectArt();

  @override
  Widget build(BuildContext context) {
    Widget vote(String avatar, bool yes) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Column(
        children: [
          PlayerAvatar(avatar: avatar, size: 46),
          const SizedBox(height: 3),
          Container(
            width: 50,
            padding: const EdgeInsets.symmetric(vertical: 1),
            decoration: BoxDecoration(
              color: yes ? AppColors.green : AppColors.traitor,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Text(
              yes ? 'نعم' : 'لا',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: kufi,
                fontWeight: FontWeight.w700,
                color: yes ? const Color(0xFF062814) : Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PlayerAvatar(avatar: 'merchant', size: 80),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: ChatBubble(style: bubbleStyle(null), text: 'والله وصلني ٣ حمر!', fontSize: 16, maxWidth: 200),
            ),
            const SizedBox(width: 6),
            const Gfx('liar', size: 50),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            vote('pearl', true),
            vote('desert', false),
            vote('rose', true),
            vote('sheikh', false),
            const SizedBox(width: 6),
            const Gfx('search', size: 44),
          ],
        ),
      ],
    );
  }
}

/// قدرات الرئيس، والنقض.
class _PowersArt extends StatelessWidget {
  const _PowersArt();

  @override
  Widget build(BuildContext context) {
    Widget tile(String icon, String label) => Container(
      width: 96,
      margin: const EdgeInsets.all(5),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.traitor.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.traitor.withValues(alpha: .6)),
      ),
      child: Column(
        children: [
          Gfx(icon, size: 40),
          const SizedBox(height: 3),
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
        ],
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final p in [Power.investigate, Power.execute, Power.peek]) tile(powerIcon[p]!, powerName[p]!),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [tile(powerIcon[Power.specialElection]!, powerName[Power.specialElection]!), tile('hand', 'النقض')],
        ),
      ],
    );
  }
}

/// آخر صفحة: الشعار بين الختمين.
class _ReadyArt extends StatelessWidget {
  const _ReadyArt();

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Seal(loyal: true, size: 70),
      const SizedBox(width: 16),
      Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          boxShadow: [BoxShadow(color: AppColors.gold.withValues(alpha: .45), blurRadius: 36, spreadRadius: 2)],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: Image.asset('assets/logo.png', width: 150, height: 150),
        ),
      ),
      const SizedBox(width: 16),
      const Seal(loyal: false, size: 70),
    ],
  );
}
