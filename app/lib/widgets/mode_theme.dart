import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme.dart';
import 'common.dart';
import 'fx.dart';
import 'ui.dart';

/// الطورين وثيم كل واحد: الكلاسيكي (الزعيم والخونة والأوفياء بس) بليل خمري وجمر، والمطوّر (فيه أدوار بقدرات)
/// بليل فيروزي ونجوم. الثيم يبان في صفحة اختيار الطور، وفي الطاولات والروم الخاص اللي بعدها، وفي غرفة الانتظار.
class ModeTheme {
  const ModeTheme._({
    required this.roles,
    required this.name,
    required this.tagline,
    required this.hint,
    required this.icon,
    required this.top,
    required this.bottom,
    required this.glow,
    required this.accent,
    required this.accentLight,
    required this.select,
    required this.selectBg,
    required this.title,
    required this.button,
    required this.cast,
    required this.stars,
  });

  /// طور الشخصيات في السيرفر (rooms.roles).
  final bool roles;
  final String name;

  /// سطر تحت الاسم.
  final String tagline;

  /// وش فيه من أدوار.
  final String hint;
  final String icon;

  /// تدرج الخلفية من فوق لتحت، والتوهج اللي ورا الرسمة.
  final Color top, bottom, glow;

  /// الأزرار المختارة والحدود.
  final Color accent, accentLight;

  /// الطاولة المختارة: لون حدها وخلفيتها.
  final Color select, selectBg;

  /// تدرج اسم الطور.
  final List<Color> title;
  final ButtonTone button;

  /// الأدوار: (الأيقونة، الاسم، وش يسوي).
  final List<(String, String, String)> cast;

  /// الحركة ورا: نجوم تلمع (المطوّر) أو جمر يطلع (الكلاسيكي).
  final bool stars;

  static const classic = ModeTheme._(
    roles: false,
    name: 'الكلاسيكي',
    tagline: 'اللعبة الأصلية: أوفياء وخونة وزعيم متخبّي',
    hint: 'الزعيم والخونة والأوفياء فقط، بدون أدوار خاصة',
    icon: 'dagger',
    top: Color(0xFF3D0B17),
    bottom: Color(0xFF0E0407),
    glow: Color(0xFFB3122F),
    accent: Color(0xFFC81E3A),
    accentLight: Color(0xFFFF9AA8),
    select: AppColors.gold,
    selectBg: Color(0xFF2E1B12),
    title: [Color(0xFFFFE9A8), Color(0xFFF2B53A), Color(0xFFD48B12)],
    button: ButtonTone.gold,
    stars: false,
    cast: [
      ('card_crescent', 'الأوفياء', 'هم الأكثر، لكن ما يدرون من الخائن'),
      ('card_dagger', 'الخونة', 'يعرفون بعض، ويمررون قراراتهم بدون ما ينكشفون'),
      ('card_scorpion', 'الزعيم', 'لو صار وزير بعد ٣ قرارات حمرا، يفوزون الخونة'),
    ],
  );

  static const advanced = ModeTheme._(
    roles: true,
    name: 'المطوّر',
    tagline: 'أدوار سرية بقدرات تقلب الموازين',
    hint: 'فيه العرّاف والحارس والقاضي والشيخ والجاسوس',
    icon: 'seer',
    top: Color(0xFF07304A),
    bottom: Color(0xFF130A30),
    glow: Color(0xFF6D28D9),
    accent: Color(0xFF7C4DFF),
    accentLight: Color(0xFF7FE9FF),
    select: Color(0xFF7FE9FF),
    selectBg: Color(0xFF122943),
    title: [Color(0xFFB8F4FF), Color(0xFF7FE9FF), Color(0xFFC4B5FD)],
    button: ButtonTone.purple,
    stars: true,
    cast: [
      ('seer', 'العرّاف', 'مرة وحدة يكشف فريق أي لاعب'),
      ('shield', 'الحارس', 'لو أحد حاول يطرده، ينجو مرة وحدة'),
      ('scales', 'القاضي', 'مرة وحدة يلغي تصويت مهما كانت الأصوات'),
      ('ballot', 'الشيخ', 'صوته بصوتين في كل تصويت'),
      ('eye', 'الجاسوس', 'مرة وحدة يشوف أول كرت بالكومة'),
    ],
  );

  static ModeTheme of(bool roles) => roles ? advanced : classic;

  /// أزرار الاختيار (عدد اللاعبين والوقت) بلون الطور.
  ThemeData segmented(BuildContext context) => Theme.of(context).copyWith(
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        backgroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? accent : Colors.black.withValues(alpha: .25),
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Colors.white : AppColors.text.withValues(alpha: .85),
        ),
        side: WidgetStatePropertyAll(BorderSide(color: accentLight.withValues(alpha: .45))),
        textStyle: const WidgetStatePropertyAll(TextStyle(fontFamily: 'ReadexPro', fontWeight: FontWeight.w800)),
      ),
    ),
  );
}

/// خلفية الطور: تدرج بلونه وزخرفة خفيفة، وفوقها نجوم تلمع أو جمر يطلع. [dim]: يغمّقها عشان الكلام.
class ModeBackdrop extends StatelessWidget {
  const ModeBackdrop({super.key, required this.mode, this.dim = 0, this.density = 1});

  final ModeTheme mode;
  final double dim;

  /// كم حبة (١ = الكثافة العادية).
  final double density;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [mode.top, mode.bottom],
          ),
        ),
      ),
      DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -.35),
            radius: .9,
            colors: [mode.glow.withValues(alpha: .45), mode.glow.withValues(alpha: 0)],
          ),
        ),
      ),
      const Opacity(
        opacity: .45,
        child: DecoratedBox(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/pattern.png'),
              repeat: ImageRepeat.repeat,
              scale: 2,
            ),
          ),
        ),
      ),
      RepaintBoundary(
        child: FxClock(builder: (context, time) => CustomPaint(painter: _ParticlesPainter(mode, time, density))),
      ),
      if (dim > 0) ColoredBox(color: Colors.black.withValues(alpha: dim)),
    ],
  );
}

class _ParticlesPainter extends CustomPainter {
  _ParticlesPainter(this.mode, this.time, this.density) : super(repaint: time);

  final ModeTheme mode;
  final ValueListenable<double> time;
  final double density;

  @override
  void paint(Canvas canvas, Size size) {
    final t = time.value;
    final paint = Paint();
    if (mode.stars) {
      // نجوم صغيرة تلمع في مكانها، وكم لمعة كبيرة تطفو بشويش.
      final n = (60 * density).round();
      for (var i = 0; i < n; i++) {
        final x = rnd(i, 1) * size.width, y = rnd(i, 2) * size.height;
        final tw = .5 + .5 * math.sin(t * (1 + rnd(i, 3) * 2) + rnd(i, 4) * 6.3);
        paint.color = (i.isEven ? mode.accentLight : Colors.white).withValues(alpha: .15 + .55 * tw);
        canvas.drawCircle(Offset(x, y), .6 + rnd(i, 5) * 1.3, paint);
      }
      for (var i = 0; i < (9 * density).round(); i++) {
        final p = (t * (.02 + rnd(i, 7) * .02) + rnd(i, 8)) % 1;
        final x = rnd(i, 9) * size.width + math.sin(t * .5 + i) * 12;
        final y = size.height * (1.05 - p * 1.1);
        final a = math.sin(p * math.pi);
        paint.color = mode.accentLight.withValues(alpha: .55 * a);
        canvas.drawPath(star4(Offset(x, y), 3 + rnd(i, 10) * 4), paint);
      }
    } else {
      // جمر يطلع من تحت ويتمايل ويطفى.
      final n = (34 * density).round();
      for (var i = 0; i < n; i++) {
        final p = (t * (.06 + rnd(i, 1) * .08) + rnd(i, 2)) % 1;
        final x = rnd(i, 3) * size.width + math.sin(t * (1 + rnd(i, 4)) + i) * 10 * p;
        final y = size.height * (1.02 - p * 1.05);
        final a = (1 - p) * math.min(1, p * 6);
        final r = (1 + rnd(i, 5) * 2.2) * (1 - p * .5);
        paint
          ..color = Color.lerp(const Color(0xFFFFC46B), const Color(0xFFE0314B), p)!.withValues(alpha: .75 * a)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2);
        canvas.drawCircle(Offset(x, y), r, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_ParticlesPainter old) => old.mode != mode || old.density != density;
}

/// شارة الطور الصغيرة (غرفة الانتظار، فوق الطاولات).
class ModeChip extends StatelessWidget {
  const ModeChip({super.key, required this.mode, this.onTap});

  final ModeTheme mode;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: onTap != null,
    label: 'الطور ${mode.name}',
    excludeSemantics: true,
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsetsDirectional.fromSTEB(6, 3, 10, 3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(colors: [mode.top, mode.bottom]),
          border: Border.all(color: mode.accentLight.withValues(alpha: .55), width: 1.5),
          boxShadow: [BoxShadow(color: mode.glow.withValues(alpha: .35), blurRadius: 10)],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Gfx(mode.icon, size: 20),
            const SizedBox(width: 5),
            ModeName(mode: mode, size: 14),
            if (onTap != null) ...[
              const SizedBox(width: 6),
              Icon(Icons.swap_horiz_rounded, size: 16, color: mode.accentLight),
            ],
          ],
        ),
      ),
    ),
  );
}

/// اسم الطور بخط العناوين وتدرج لونه.
class ModeName extends StatelessWidget {
  const ModeName({super.key, required this.mode, this.size = 28, this.text});

  final ModeTheme mode;
  final double size;

  /// كلام بدال الاسم (بنفس التدرج).
  final String? text;

  @override
  Widget build(BuildContext context) => ShaderMask(
    blendMode: BlendMode.srcIn,
    shaderCallback: (r) =>
        LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: mode.title).createShader(r),
    child: Text(
      text ?? mode.name,
      style: TextStyle(fontFamily: kufi, fontSize: size, fontWeight: FontWeight.w700, height: 1.25),
    ),
  );
}

/// ملخص الطور (تحت أزرار الاختيار): أيقونات أدواره ووش فيه.
class ModeSummary extends StatelessWidget {
  const ModeSummary({super.key, required this.mode});

  final ModeTheme mode;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(10, 7, 10, 7),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(14),
      color: Colors.black.withValues(alpha: .28),
      border: Border.all(color: mode.accentLight.withValues(alpha: .3)),
    ),
    child: Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final (icon, name, _) in mode.cast)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Tooltip(message: name, child: Gfx(icon, size: 24)),
              ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          mode.hint,
          textAlign: TextAlign.center,
          style: TextStyle(color: mode.accentLight.withValues(alpha: .9), fontSize: 11.5, fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}
