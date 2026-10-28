import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/backend.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/fx.dart';
import '../widgets/mode_theme.dart';
import '../widgets/ui.dart';
import 'private_screen.dart';
import 'tables_screen.dart';

/// وين يروح بعد ما يختار الطور.
enum ModePurpose { random, private }

/// أول شي قبل اللعب: يختار الطور (الكلاسيكي أو المطوّر)، وبعدها يكمل للطاولات أو الروم الخاص.
class ModeScreen extends StatefulWidget {
  const ModeScreen({super.key, required this.purpose});

  final ModePurpose purpose;

  @override
  State<ModeScreen> createState() => _ModeScreenState();
}

class _ModeScreenState extends State<ModeScreen> {
  static const _lastKey = 'last_mode_roles';

  /// آخر طور اختاره (عشان نعلّم عليه).
  bool? _last;

  @override
  void initState() {
    super.initState();
    _loadLast();
  }

  Future<void> _loadLast() async {
    try {
      final v = (await SharedPreferences.getInstance()).getBool(_lastKey);
      if (mounted) setState(() => _last = v);
    } catch (_) {}
  }

  Future<void> _pick(ModeTheme mode) async {
    setState(() => _last = mode.roles);
    try {
      await (await SharedPreferences.getInstance()).setBool(_lastKey, mode.roles);
    } catch (_) {}
    if (!mounted) return;
    final navigator = Navigator.of(context);
    switch (widget.purpose) {
      case ModePurpose.random:
        navigator.push(MaterialPageRoute(builder: (_) => TablesScreen(mode: mode)));
      case ModePurpose.private:
        navigator.push(MaterialPageRoute(builder: (_) => PrivateScreen(mode: mode)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final (icon, title, cta) = switch (widget.purpose) {
      ModePurpose.random => ('games', 'عشوائي', 'العب '),
      // «ب» تلتصق بـ«ال»: كمّل بالكلاسيكي.
      ModePurpose.private => ('friends', 'روم خاص', 'كمّل ب'),
    };
    return NightScaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [Gfx(icon, size: 30), const SizedBox(width: 8), Text('$title · اختر الطور')],
        ),
        actions: [
          if (widget.purpose == ModePurpose.private)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 10),
              child: TextButton.icon(
                onPressed: Backend.instance.isReady ? () => joinRoomByCode(context) : null,
                icon: const Gfx('key', size: 22),
                label: const Text('عندك كود؟ ادخل روم صاحبك'),
              ),
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 2, 16, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (i, mode) in const [ModeTheme.classic, ModeTheme.advanced].indexed) ...[
                if (i > 0) const SizedBox(width: 14),
                Expanded(
                  child: _ModeCard(
                    mode: mode,
                    cta: '$cta${mode.name}',
                    last: _last == mode.roles,
                    fresh: mode.roles,
                    onTap: () => _pick(mode),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// بطاقة الطور: خلفيته وحركته، ورسمته، واسمه، والأدوار اللي فيه، وزر يدخلك.
class _ModeCard extends StatefulWidget {
  const _ModeCard({required this.mode, required this.cta, required this.onTap, this.last = false, this.fresh = false});

  final ModeTheme mode;
  final String cta;
  final VoidCallback onTap;

  /// آخر طور لعبته.
  final bool last;

  /// شارة «جديد».
  final bool fresh;

  @override
  State<_ModeCard> createState() => _ModeCardState();
}

class _ModeCardState extends State<_ModeCard> {
  bool _down = false;

  void _info() {
    final m = widget.mode;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Gfx(m.icon, size: 28),
            const SizedBox(width: 8),
            ModeName(mode: m, size: 22),
          ],
        ),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.tagline,
                  style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                for (final (icon, name, what) in m.cast)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Gfx(icon, size: 28),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: '$name: ',
                                  style: const TextStyle(fontWeight: FontWeight.w900),
                                ),
                                TextSpan(text: what),
                              ],
                            ),
                            style: const TextStyle(fontSize: 14, height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (m.roles)
                  const Text(
                    'الأدوار الخاصة تنعطى لبعض اللاعبين، وفوقها الزعيم والخونة والأوفياء مثل الكلاسيكي.',
                    style: TextStyle(color: AppColors.muted, fontSize: 12.5, height: 1.5),
                  ),
              ],
            ),
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('تمام'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.mode;
    return Semantics(
      button: true,
      label: 'الطور ${m.name}: ${m.hint}',
      child: GestureDetector(
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _down ? .975 : 1,
          duration: const Duration(milliseconds: 120),
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: m.accentLight.withValues(alpha: .6), width: 2),
              boxShadow: [
                BoxShadow(color: m.glow.withValues(alpha: .5), blurRadius: 26, offset: const Offset(0, 6)),
                const BoxShadow(color: Colors.black54, blurRadius: 12, offset: Offset(0, 8)),
              ],
            ),
            child: Stack(
              children: [
                Positioned.fill(child: ModeBackdrop(mode: m, density: .8)),
                // خط ذهبي رفيع جوا الحافة.
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(19),
                        border: Border.all(color: m.title[1].withValues(alpha: .22)),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                  child: Column(
                    children: [
                      Expanded(
                        child: m.roles ? _AdvancedEmblem(mode: m) : _ClassicEmblem(mode: m),
                      ),
                      ModeName(mode: m, size: 30),
                      Text(
                        m.tagline,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.white.withValues(alpha: .85),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _Cast(mode: m),
                      const SizedBox(height: 10),
                      GameButton(
                        label: widget.cta,
                        icon: Gfx(m.icon, size: 24),
                        tone: m.button,
                        height: 44,
                        fontSize: 17,
                        onPressed: widget.onTap,
                      ),
                    ],
                  ),
                ),
                if (widget.fresh) const PositionedDirectional(top: 14, start: 14, child: _Pill('جديد', hot: true)),
                if (widget.last) const PositionedDirectional(top: 14, end: 52, child: _Pill('آخر طور لعبته')),
                PositionedDirectional(
                  top: 6,
                  end: 6,
                  child: IconButton(
                    tooltip: 'وش فيه؟',
                    onPressed: _info,
                    icon: Icon(Icons.info_outline_rounded, color: m.accentLight, size: 24),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.text, {this.hot = false});

  final String text;
  final bool hot;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(10),
      color: hot ? AppColors.traitor : Colors.black.withValues(alpha: .45),
      border: Border.all(color: Colors.white.withValues(alpha: hot ? .5 : .2)),
    ),
    child: Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
  );
}

/// الأدوار اللي في الطور: أيقونة واسم تحتها.
class _Cast extends StatelessWidget {
  const _Cast({required this.mode});

  final ModeTheme mode;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      for (final (icon, name, _) in mode.cast)
        SizedBox(
          width: mode.cast.length > 3 ? 58 : 76,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: .35),
                  border: Border.all(color: mode.accentLight.withValues(alpha: .35)),
                ),
                child: Gfx(icon, size: 24),
              ),
              const SizedBox(height: 2),
              Text(name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
    ],
  );
}

/// رسمة الكلاسيكي: كروت الأدوار الثلاثة (الوفي والزعيم والخاين) ووراها توهج أحمر، والزعيم يطفو بشويش.
class _ClassicEmblem extends StatelessWidget {
  const _ClassicEmblem({required this.mode});

  final ModeTheme mode;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final base = math.min(box.maxHeight, 170.0);
      final big = base * .92, side = base * .66;
      return FxClock(
        builder: (context, time) => AnimatedBuilder(
          animation: time,
          builder: (context, _) {
            final t = time.value;
            final float = math.sin(t * 1.6) * base * .03;
            return Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: base * 1.5,
                  height: base * 1.1,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        mode.glow.withValues(alpha: .55 + .1 * math.sin(t * 2)),
                        mode.glow.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
                Transform.translate(
                  offset: Offset(-base * .68, base * .1),
                  child: Transform.rotate(angle: -.26, child: Gfx('card_shield', size: side)),
                ),
                Transform.translate(
                  offset: Offset(base * .68, base * .1),
                  child: Transform.rotate(angle: .26, child: Gfx('card_dagger', size: side)),
                ),
                Transform.translate(
                  offset: Offset(0, -base * .04 + float),
                  child: Gfx('card_scorpion', size: big),
                ),
              ],
            );
          },
        ),
      );
    },
  );
}

/// رسمة المطوّر: كرة العرّاف تضوي في النص، والأدوار الثانية تلف حولها في مدار.
class _AdvancedEmblem extends StatelessWidget {
  const _AdvancedEmblem({required this.mode});

  final ModeTheme mode;

  static const _orbit = ['shield', 'scales', 'ballot', 'eye'];

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final base = math.min(box.maxHeight, 170.0);
      final rx = math.min(box.maxWidth / 2 - base * .22, base * 1.05), ry = base * .26;
      final center = base * .66, small = base * .34;
      return FxClock(
        builder: (context, time) => AnimatedBuilder(
          animation: time,
          builder: (context, _) {
            final t = time.value;
            final pulse = .5 + .5 * math.sin(t * 2.2);
            // كل أيقونة: زاويتها في المدار، واللي ورا تصغر وتبهت.
            final orbiters = [for (final (i, icon) in _orbit.indexed) (icon: icon, a: t * .5 + i * math.pi / 2)]
              ..sort((x, y) => math.sin(x.a).compareTo(math.sin(y.a)));
            Widget orbiter(({String icon, double a}) o) {
              final depth = (math.sin(o.a) + 1) / 2;
              return Transform.translate(
                offset: Offset(math.cos(o.a) * rx, math.sin(o.a) * ry + base * .02),
                child: Opacity(
                  opacity: .55 + .45 * depth,
                  child: Gfx(o.icon, size: small * (.78 + .22 * depth)),
                ),
              );
            }

            return Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // المدار نفسه: خط بيضاوي خفيف.
                CustomPaint(size: Size(rx * 2, ry * 2), painter: _OrbitPainter(mode.accentLight)),
                for (final o in orbiters.where((o) => math.sin(o.a) < 0)) orbiter(o),
                Container(
                  width: center * (1.7 + .15 * pulse),
                  height: center * (1.7 + .15 * pulse),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        mode.accentLight.withValues(alpha: .45 + .2 * pulse),
                        mode.accent.withValues(alpha: .25),
                        mode.accent.withValues(alpha: 0),
                      ],
                      stops: const [0, .45, 1],
                    ),
                  ),
                ),
                Gfx('seer', size: center),
                for (final o in orbiters.where((o) => math.sin(o.a) >= 0)) orbiter(o),
              ],
            );
          },
        ),
      );
    },
  );
}

class _OrbitPainter extends CustomPainter {
  _OrbitPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawOval(
      Offset.zero & size,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = color.withValues(alpha: .28),
    );
  }

  @override
  bool shouldRepaint(_OrbitPainter old) => old.color != color;
}
