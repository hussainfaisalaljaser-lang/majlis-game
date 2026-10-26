import 'package:flutter/material.dart';

import '../models/game_view.dart';
import '../models/shop.dart';
import '../services/backend.dart';
import '../services/sfx.dart';
import '../services/telemetry.dart';
import '../theme.dart';
import '../widgets/bubble.dart';
import '../widgets/common.dart';
import '../widgets/game/policy_card.dart';
import '../widgets/ui.dart';
import 'game_screen.dart';

/// مكافأة أول لعبة شرح (نفس functions/src/economy.ts → TUTORIAL_REWARD).
const tutorialReward = 500;

/// يبدأ لعبة الشرح (أنت و٤ بوتات) ويفتح الطاولة.
Future<void> startTutorialGame(BuildContext context) async {
  final backend = Backend.instance;
  if (!backend.isReady) return;
  final navigator = Navigator.of(context);
  final messenger = ScaffoldMessenger.of(context);
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const AlertDialog(
      content: Row(
        children: [
          CircularProgressIndicator(color: AppColors.gold),
          SizedBox(width: 16),
          Text('نجهّز مجلس الشرح…'),
        ],
      ),
    ),
  );
  try {
    final code = await backend.startTutorial();
    Telemetry.tutorialBegin();
    navigator.pop();
    navigator.push(MaterialPageRoute(builder: (_) => GameScreen(code: code)));
  } on BackendException catch (e) {
    navigator.pop();
    messenger.showSnackBar(SnackBar(content: Text(e.message)));
  }
}

/// أول مرة يفتح اللعبة: نعرض عليه الشرح (مرة وحدة، ويقدر يرجع له من "كيف ألعب").
Future<void> offerTutorial(BuildContext context) async {
  final go = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      contentPadding: const EdgeInsets.fromLTRB(22, 20, 22, 6),
      content: Row(
        children: [
          const PlayerAvatar(avatar: 'sheikh', frame: AppColors.gold, size: 84),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const GoldText('أول مرة في المجلس؟', size: 22, align: TextAlign.start),
                const SizedBox(height: 6),
                const Text(
                  'خلني أعلمك اللعبة في دقيقتين، وبعدها نلعب جولة تجريبية مع البوتات.',
                  style: TextStyle(fontSize: 14, height: 1.5),
                ),
                const SizedBox(height: 8),
                Amount(
                  'coin',
                  'هديتك لما تخلص: ${arabicNumber(tutorialReward)} ذهب',
                  size: 20,
                  style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w800, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: GameButton(
                label: 'أعرف ألعب',
                tone: ButtonTone.ghost,
                height: 46,
                fontSize: 15,
                onPressed: () => Navigator.pop(context, false),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GameButton(
                label: 'علّمني',
                icon: const Gfx('guide', size: 26),
                height: 46,
                fontSize: 16,
                onPressed: () => Navigator.pop(context, true),
              ),
            ),
          ],
        ),
      ],
    ),
  );
  if (go == true && context.mounted) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HowToPlayScreen()));
  }
}

typedef _Slide = ({String voice, String title, String body, Widget art});

/// كيف ألعب: ٦ صفحات قصيرة، والراوي يقرا كل صفحة، وآخرها تبدأ لعبة الشرح.
class HowToPlayScreen extends StatefulWidget {
  const HowToPlayScreen({super.key});

  @override
  State<HowToPlayScreen> createState() => _HowToPlayScreenState();
}

class _HowToPlayScreenState extends State<HowToPlayScreen> {
  final _pages = PageController();
  int _page = 0;

  static final List<_Slide> _slides = [
    (
      voice: 'tut_s1',
      title: 'هلا والله في المجلس!',
      body: 'هذا مجلس الخونة: بيننا أوفياء… وبيننا خونة متخبّين.\nتعال أعلمك كيف تلعب في دقيقتين.',
      art: const _WelcomeArt(),
    ),
    (
      voice: 'tut_s2',
      title: 'الأوفياء والخونة',
      body: 'الأوفياء هم الأكثر، بس ما يدرون مين الخاين.\nأما الخونة فيعرفون بعض، ومعهم زعيمهم.',
      art: const _TeamsArt(),
    ),
    (
      voice: 'tut_s3',
      title: 'الرئيس والوزير',
      body: 'كل جولة فيه رئيس، يختار له وزير.\nوبعدين الكل يصوّت: موافق أو رافض.',
      art: const _GovernmentArt(),
    ),
    (
      voice: 'tut_s4',
      title: 'القرارات',
      body: 'إذا انتخبوا الحكومة، يمرّرون قرار.\n٥ قرارات زرقا يفوز الأوفياء، و٦ حمرا يفوزون الخونة.',
      art: const _PoliciesArt(),
    ),
    (
      voice: 'tut_s5',
      title: 'الكلام… والكذب!',
      body: 'بعد كل قرار، الرئيس والوزير يقولون وش وصلهم… وممكن يكذبون!\nوالقرار الأحمر يعطي الرئيس قدرة قوية.',
      art: const _ClaimsArt(),
    ),
    (
      voice: 'tut_s6',
      title: 'انتبه للزعيم!',
      body: 'إذا انطرد الزعيم فاز الأوفياء.\nوإذا صار وزير بعد ٣ قرارات حمرا، فازوا الخونة.',
      art: const _LeaderArt(),
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

  @override
  Widget build(BuildContext context) {
    final last = _page == _slides.length - 1;
    return NightScaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
          child: Column(
            children: [
              Row(
                children: [
                  const Gfx('guide', size: 34),
                  const SizedBox(width: 8),
                  const GoldText('كيف ألعب؟', size: 24),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Gfx('cross', size: 22),
                    label: const Text(
                      'إغلاق',
                      style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700),
                    ),
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
                        : GameButton(
                            label: 'السابق',
                            tone: ButtonTone.ghost,
                            height: 44,
                            fontSize: 15,
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
                            width: i == _page ? 22 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: i == _page ? AppColors.gold : AppColors.line,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: last ? 230 : 130,
                    child: last
                        ? GameButton(
                            label: 'يالله نجرّب!',
                            semantics: 'ابدأ لعبة الشرح',
                            icon: const Gfx('games', size: 26),
                            tone: ButtonTone.green,
                            height: 44,
                            fontSize: 16,
                            onPressed: () {
                              Sfx.hush();
                              startTutorialGame(context);
                            },
                          )
                        : GameButton(label: 'التالي', height: 44, fontSize: 15, onPressed: () => _go(_page + 1)),
                  ),
                ],
              ),
              ValueListenableBuilder(
                valueListenable: Backend.instance.profile,
                builder: (context, p, _) => AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  child: last && !p.tutorialDone
                      ? Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Amount(
                            'coin',
                            'خلّص لعبة الشرح وخذ ${arabicNumber(tutorialReward)} ذهب',
                            size: 18,
                            style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w800, fontSize: 13),
                          ),
                        )
                      : const SizedBox(width: double.infinity),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide});

  final _Slide slide;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 6,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const RadialGradient(
                  center: Alignment(0, -.3),
                  radius: 1.1,
                  colors: [Color(0xFF4A3394), Color(0xFF1E1645)],
                ),
                border: Border.all(color: AppColors.gold.withValues(alpha: .4), width: 2),
              ),
              padding: const EdgeInsets.all(12),
              child: Center(child: FittedBox(child: slide.art)),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            flex: 5,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GoldText(slide.title, size: 26, align: TextAlign.start),
                const SizedBox(height: 10),
                Text(slide.body, style: const TextStyle(fontSize: 16.5, height: 1.65, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const PlayerAvatar(avatar: 'sheikh', size: 30),
                    const SizedBox(width: 8),
                    ValueListenableBuilder(
                      valueListenable: Sfx.muted,
                      builder: (context, muted, _) => GestureDetector(
                        onTap: () {
                          if (muted) {
                            Sfx.toggle().then((_) => Sfx.say(slide.voice));
                          } else {
                            Sfx.hush();
                            Sfx.say(slide.voice);
                          }
                        },
                        child: Row(
                          children: [
                            Gfx(muted ? 'mute' : 'sound', size: 22),
                            const SizedBox(width: 4),
                            Text(
                              muted ? 'شغّل صوت الراوي' : 'اسمعها مرة ثانية',
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
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

class _PoliciesArt extends StatelessWidget {
  const _PoliciesArt();

  @override
  Widget build(BuildContext context) {
    Widget track(int n, Color color, String label) => Column(
      children: [
        Row(
          children: [
            for (var i = 0; i < n; i++)
              Container(
                width: 22,
                height: 22,
                margin: const EdgeInsets.all(2.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: .25),
                  border: Border.all(color: color, width: 2.5),
                ),
              ),
          ],
        ),
        _Caption(label, color: color),
      ],
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PolicyCard(policy: Policy.loyal, width: 84),
            SizedBox(width: 26),
            PolicyCard(policy: Policy.traitor, width: 84),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            track(5, AppColors.loyalLight, '٥ للأوفياء'),
            const SizedBox(width: 20),
            track(6, AppColors.traitorLight, '٦ للخونة'),
          ],
        ),
      ],
    );
  }
}

class _ClaimsArt extends StatelessWidget {
  const _ClaimsArt();

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PlayerAvatar(avatar: 'merchant', size: 84),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: ChatBubble(style: bubbleStyle(null), text: 'والله وصلني ٣ حمر!', fontSize: 16, maxWidth: 200),
          ),
          const SizedBox(width: 6),
          const Gfx('liar', size: 54),
        ],
      ),
      const SizedBox(height: 16),
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (icon, label) in const [
            ('search', 'تحقيق'),
            ('eye', 'كشف الكروت'),
            ('crown', 'رئيس جديد'),
            ('dagger', 'طرد'),
          ])
            Container(
              width: 82,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.traitor.withValues(alpha: .14),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.traitor.withValues(alpha: .6)),
              ),
              child: Column(
                children: [
                  Gfx(icon, size: 34),
                  const SizedBox(height: 2),
                  Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
        ],
      ),
    ],
  );
}

class _LeaderArt extends StatelessWidget {
  const _LeaderArt();

  @override
  Widget build(BuildContext context) {
    Widget outcome(String icon, String text, bool loyal) => Container(
      width: 250,
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.fromLTRB(10, 8, 12, 8),
      decoration: BoxDecoration(
        color: (loyal ? AppColors.loyal : AppColors.traitor).withValues(alpha: .18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: loyal ? AppColors.loyalLight : AppColors.traitorLight, width: 1.6),
      ),
      child: Row(
        children: [
          Gfx(icon, size: 32),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, height: 1.35)),
          ),
          Seal(loyal: loyal, size: 34),
        ],
      ),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: AppColors.traitor.withValues(alpha: .55), blurRadius: 40, spreadRadius: 4)],
          ),
          child: const LeaderSeal(size: 150),
        ),
        const SizedBox(width: 16),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            outcome('dagger', 'انطرد الزعيم: يفوزون الأوفياء', true),
            outcome('warning', 'صار وزير بعد ٣ حمر: يفوزون الخونة', false),
          ],
        ),
      ],
    );
  }
}
