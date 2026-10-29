import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme.dart';
import 'common.dart';
import 'design.dart';
import 'fx.dart';

/// جمل تطلع تحت شريط التحميل، كل مرة وحدة عشوائية وتتبدل وهم ينتظرون: نصايح، وكلام عن المجلس، ومزح خفيفة.
const loadingLines = [
  // نصايح
  'الخاين دايم يقول «أنا بريء» أول',
  'راقب مين يصوّت ضد مين، التصويت يفضح',
  'لو صرت رئيس، اختر وزيرك بعناية',
  'الأوفياء أكثر، بس الخونة يعرفون بعض',
  'لا تكشف دورك بدري',
  'ثلاث حكومات فاشلة ورا بعض، وتتمرر أول ورقة تلقائياً',
  'لو صار الزعيم وزير بعد ثلاث قرارات حمرا، يفوز الخونة',
  'اضغط على أي لاعب تشوف ملفه',
  'الملصقات تعبّر عنك أسرع من الكلام',
  'جرّب الطور المطوّر: العرّاف والحارس والقاضي',
  // المجلس
  'نفرش السجادة ونعلّق الفوانيس…',
  'القهوة جاهزة… والخاين بينكم',
  'المجلس ما يكمل إلا بأصحابك',
  'نجهّز الكروت ونخلطها…',
  // مزح
  'اللي يضحك أول، يمكن هو الخاين',
  'اسأل نفسك: مين اللي ما تكلم؟',
  'ثقتك غالية، لا تعطيها بسرعة',
  'ما كل واحد يبتسم صديق',
  'الخاين بينك وبين أقرب صاحب',
];

/// شاشة الافتتاح والتحميل: أيقونة اللعبة تطفو، واسمها بالذهب، وشريط تعبئة، وتحتها جملة عشوائية تتبدل.
/// [loading]: الشريط والجملة (لما ننتظر السيرفر). [progress]: تقدم تحميل الصور من ٠ لين ١ (بدونه الشريط يلمع بس).
class SplashView extends StatefulWidget {
  const SplashView({super.key, this.loading = true, this.progress});

  final bool loading;
  final ValueListenable<double>? progress;

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  final _rng = math.Random();
  late int _line = _rng.nextInt(loadingLines.length);
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.loading) {
      _timer = Timer.periodic(const Duration(milliseconds: 3200), (_) {
        if (!mounted) return;
        setState(() => _line = (_line + 1 + _rng.nextInt(loadingLines.length - 1)) % loadingLines.length);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: const Image(image: AssetImage(DesignAssets.homeBg), fit: BoxFit.cover),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(radius: 1.1, colors: [Color(0x00160A05), Color(0xCC160A05)], stops: [.3, 1]),
            ),
          ),
          // جمر وغبار ذهبي يطلع بشويش
          RepaintBoundary(
            child: FxClock(builder: (context, time) => CustomPaint(painter: _EmberPainter(time))),
          ),
          LayoutBuilder(
            builder: (context, box) {
              final s = (box.maxHeight / 540).clamp(.55, 1.35);
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // الأيقونة تطفو وتنبض عيونها (ضو ذهبي وراها)
                    FxClock(
                      builder: (context, time) => ValueListenableBuilder<double>(
                        valueListenable: time,
                        builder: (context, t, _) => Transform.translate(
                          offset: Offset(0, math.sin(t * 1.3) * 5 * s),
                          child: Container(
                            width: 150 * s,
                            height: 150 * s,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(34 * s),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFFC85A).withValues(alpha: .28 + .14 * math.sin(t * 2)),
                                  blurRadius: 34 * s,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Image.asset('assets/logo.png', width: 150 * s, height: 150 * s),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 14 * s),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: GoldTitle('مجلس الخونة', size: 60 * s),
                    ),
                    SizedBox(height: 16 * s),
                    if (widget.loading) ...[
                      _Bar(width: 260 * s, height: 12 * s, progress: widget.progress),
                      if (widget.progress case final progress?)
                        ValueListenableBuilder<double>(
                          valueListenable: progress,
                          builder: (context, p, _) => Padding(
                            padding: EdgeInsets.only(top: 6 * s),
                            child: Text(
                              'نجهّز اللعبة ${arabicNumber((p * 100).round())}٪',
                              style: TextStyle(
                                fontSize: 13 * s,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFFE8C98A),
                                height: 1.2,
                              ),
                            ),
                          ),
                        ),
                      SizedBox(height: 14 * s),
                      SizedBox(
                        height: 44 * s,
                        width: math.min(box.maxWidth - 40, 460),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 500),
                          child: Text(
                            loadingLines[_line],
                            key: ValueKey(_line),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16 * s,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFF6E2BC),
                              height: 1.4,
                              shadows: const [Shadow(color: Color(0xCC000000), blurRadius: 4)],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// شريط تعبئة ذهبي بلمعة تمر عليه (ما يعرف النسبة، يدل بس إننا نحمّل).
class _Bar extends StatelessWidget {
  const _Bar({required this.width, required this.height, this.progress});

  final double width, height;

  /// تقدم التحميل (null = الشريط كامل ولمعته تمر بس).
  final ValueListenable<double>? progress;

  @override
  Widget build(BuildContext context) => FxClock(
    builder: (context, time) => ValueListenableBuilder<double>(
      valueListenable: time,
      builder: (context, t, _) {
        final p = (t * .55) % 1;
        return Container(
          width: width,
          height: height,
          padding: EdgeInsets.all(height * .16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A0F08),
            borderRadius: BorderRadius.circular(height),
            border: Border.all(color: const Color(0xFF5A3B22), width: height * .22),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(height),
            child: Stack(
              fit: StackFit.expand,
              children: [
                ValueListenableBuilder<double>(
                  valueListenable: progress ?? ValueNotifier<double>(1),
                  builder: (context, p, child) => TweenAnimationBuilder<double>(
                    tween: Tween(end: p.clamp(0.04, 1.0)),
                    duration: const Duration(milliseconds: 250),
                    builder: (context, v, _) => Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: FractionallySizedBox(widthFactor: v, heightFactor: 1, child: child),
                    ),
                  ),
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: goldRingColors,
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment(-1.6 + 3.2 * p, 0),
                  child: FractionallySizedBox(
                    widthFactor: .3,
                    heightFactor: 1,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0),
                            Colors.white.withValues(alpha: .7),
                            Colors.white.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

class _EmberPainter extends CustomPainter {
  _EmberPainter(this.time) : super(repaint: time);

  final ValueListenable<double> time;

  @override
  void paint(Canvas canvas, Size size) {
    final t = time.value;
    final p = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.6);
    for (var i = 0; i < 34; i++) {
      final speed = .04 + rnd(i, 1) * .06;
      final u = (t * speed + rnd(i, 2)) % 1;
      final x = rnd(i, 3) * size.width + math.sin(t * (.5 + rnd(i, 4)) + i) * 16;
      final y = size.height * (1.04 - u * 1.08);
      p.color = Color.lerp(
        const Color(0xFFFFD27A),
        const Color(0xFFFF7A2A),
        rnd(i, 7),
      )!.withValues(alpha: math.sin(u * math.pi) * (.35 + .4 * rnd(i, 5)));
      canvas.drawCircle(Offset(x, y), 1.4 + rnd(i, 6) * 2.4, p);
    }
  }

  @override
  bool shouldRepaint(_EmberPainter old) => false;
}
