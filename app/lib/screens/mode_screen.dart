import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/design.dart';
import '../widgets/fx.dart';
import '../widgets/mode_theme.dart';
import '../widgets/ui.dart';
import 'private_screen.dart';
import 'tables_screen.dart';

/// اختيار الطور بعد «العب الآن»: بطاقتان كبيرتان، لكل طور خلفية تعبّر عنه وأيقونات تطفو.
/// بعدها صفحة عدد اللاعبين والطاولات (أو صفحة الطاولة الخاصة لو جيت من «خاص»).
class ModeScreen extends StatelessWidget {
  const ModeScreen({super.key, this.private = false});

  /// جاي من «خاص»: يفتح صفحة الطاولة الخاصة بدل الطاولات العامة.
  final bool private;

  void _go(BuildContext context, ModeTheme mode) => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => private ? PrivateScreen(mode: mode) : TablesScreen(mode: mode),
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.bg,
    body: Stack(
      children: [
        const Positioned.fill(child: ColoredBox(color: Color(0xFF160A05))),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
            child: Column(
              children: [
                Row(
                  children: [
                    const BackArrow(height: 34),
                    const SizedBox(width: 10),
                    OutlinedText(private ? 'اختر الطور · خاص' : 'اختر الطور', size: 28, strokeWidth: 4),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: _ModeCard(mode: ModeTheme.classic, onTap: () => _go(context, ModeTheme.classic)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _ModeCard(mode: ModeTheme.advanced, onTap: () => _go(context, ModeTheme.advanced)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _ModeCard extends StatefulWidget {
  const _ModeCard({required this.mode, required this.onTap});

  final ModeTheme mode;
  final VoidCallback onTap;

  @override
  State<_ModeCard> createState() => _ModeCardState();
}

class _ModeCardState extends State<_ModeCard> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final m = widget.mode;
    return Semantics(
      button: true,
      label: 'الطور ${m.name}: ${m.hint}',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _down ? .965 : 1,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          child: RepaintBoundary(
            child: FxClock(
              builder: (context, time) => ValueListenableBuilder<double>(
                valueListenable: time,
                builder: (context, t, _) {
                  final pulse = .5 + .5 * math.sin(t * 1.6);
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: const Color(0xFF2A1608), width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: m.glow.withValues(alpha: .35 + .25 * pulse),
                          blurRadius: 18 + 8 * pulse,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ModeBackdrop(mode: m, density: 1.4),
                          CustomPaint(painter: _ModeArtPainter(m, t)),
                          _content(m, t),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(color: m.accentLight.withValues(alpha: .55), width: 2),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// الأيقونات تطفو فوق، والاسم والوصف وزر «العب الآن» تحت.
  Widget _content(ModeTheme m, double t) => LayoutBuilder(
    builder: (context, box) {
      final s = (box.maxHeight / 290).clamp(.62, 1.3);
      final n = m.cast.length;
      return Column(
        children: [
          Expanded(
            flex: 5,
            child: Stack(
              children: [
                for (final (i, c) in m.cast.indexed)
                  Align(
                    alignment: Alignment(n == 1 ? 0 : -.74 + 1.48 * i / (n - 1), -.25 + (i.isOdd ? .3 : -.1)),
                    child: Transform.translate(
                      offset: Offset(math.sin(t * .7 + i) * 4 * s, math.sin(t * 1.25 + i * 1.7) * 7 * s),
                      child: Transform.rotate(
                        angle: math.sin(t * .9 + i * 1.3) * .1,
                        child: Container(
                          width: 64 * s,
                          height: 64 * s,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [m.accentLight.withValues(alpha: .35), m.glow.withValues(alpha: .0)],
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Gfx(c.$1, size: 44 * s),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 4,
            child: Padding(
              padding: EdgeInsets.fromLTRB(14 * s, 0, 14 * s, 12 * s),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: math.max(200, box.maxWidth - 28 * s)),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      OutlinedText(m.name, size: 40, strokeWidth: 5, gradient: m.title),
                      const SizedBox(height: 2),
                      Text(
                        m.tagline,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFFFF0D2),
                          height: 1.35,
                          shadows: [Shadow(color: Color(0xCC000000), blurRadius: 4)],
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: 200,
                        child: GameButton(
                          label: 'العب الآن',
                          tone: m.button,
                          height: 46,
                          fontSize: 20,
                          semantics: 'العب الآن بطور ${m.name}',
                          onPressed: widget.onTap,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}

/// رسمة الطور فوق الخلفية: الكلاسيكي شمس غروب وكثبان تمشي ببطء، والمطوّر هالات ملونة وحلقة تدور.
class _ModeArtPainter extends CustomPainter {
  _ModeArtPainter(this.mode, this.t);

  final ModeTheme mode;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    if (!mode.stars) {
      // شمس تغرب وتتنفس
      final sun = Offset(w * .5, h * .58);
      final r = h * (.12 + .008 * math.sin(t * .8));
      canvas.drawCircle(
        sun,
        r * 2.4,
        Paint()
          ..shader = RadialGradient(colors: [const Color(0xFFFFB04A).withValues(alpha: .5), const Color(0x00FFB04A)])
              .createShader(Rect.fromCircle(center: sun, radius: r * 2.4)),
      );
      canvas.drawCircle(sun, r, Paint()..color = const Color(0xFFFFC46B).withValues(alpha: .85));
      // كثبان بثلاث طبقات تمشي بسرعات مختلفة
      for (var k = 0; k < 3; k++) {
        final base = h * (.66 + .09 * k);
        final path = Path()..moveTo(0, h);
        for (var x = 0.0; x <= w; x += 8) {
          final y =
              base + math.sin(x * .012 + t * (.12 + .08 * k) + k * 2) * h * .035 + math.sin(x * .03 + k) * h * .012;
          path.lineTo(x, y);
        }
        path
          ..lineTo(w, h)
          ..close();
        canvas.drawPath(
          path,
          Paint()..color = Color.lerp(const Color(0xFF6A1F22), const Color(0xFF1C0709), k / 2)!.withValues(alpha: .85),
        );
      }
    } else {
      // هالات ملونة تتحرك، وحلقة تدور حول الأيقونات
      for (var i = 0; i < 3; i++) {
        final c = Offset(
          w * (.25 + .25 * i) + math.sin(t * .4 + i * 2) * w * .06,
          h * (.3 + .1 * math.cos(t * .35 + i)),
        );
        final col = [const Color(0xFF7C4DFF), const Color(0xFF3FD0FF), const Color(0xFFB07CFF)][i];
        canvas.drawCircle(
          c,
          h * .42,
          Paint()
            ..shader = RadialGradient(colors: [col.withValues(alpha: .26), col.withValues(alpha: 0)])
                .createShader(Rect.fromCircle(center: c, radius: h * .42)),
        );
      }
      final c = Offset(w * .5, h * .3);
      final ringR = math.min(w * .44, h * .27);
      canvas.drawCircle(
        c,
        ringR,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = mode.accentLight.withValues(alpha: .22),
      );
      for (var i = 0; i < 5; i++) {
        final a = t * .35 + i * 2 * math.pi / 5;
        canvas.drawCircle(
          c + Offset(math.cos(a), math.sin(a) * .55) * ringR,
          2.6,
          Paint()..color = mode.accentLight.withValues(alpha: .8),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_ModeArtPainter old) => old.t != t || old.mode != mode;
}
