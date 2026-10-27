import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/game_view.dart';
import '../../models/shop.dart';
import '../../theme.dart';
import '../../widgets/bubble.dart';
import '../../widgets/common.dart';
import '../../widgets/fx.dart';
import '../../widgets/game/game_table.dart' show rugRect;
import '../../widgets/game/policy_card.dart';
import '../../widgets/majlis.dart';
import '../../widgets/ui.dart';
import '../../widgets/venues.dart';

part 'ideas_more.dart';

/// نماذج الأفكار الجديدة (نسخة المحاكي على الويب بس): ‎?gallery=ideas‎ ورا بعض، و‎&only=lies‎ نموذج واحد يعيد نفسه.
/// كل شي يمشي على ساعة الحركات، فالتصوير (window.fxTime) يطلع نفس الشي كل مرة.

const sceneW = 800.0, sceneH = 450.0;

class Idea {
  const Idea(this.id, this.title, this.duration, this.build);

  final String id;
  final String title;
  final double duration;
  final Widget Function(double t) build;
}

final ideas = <Idea>[
  Idea('desert', '١ · مبتدئ: بيت شعر في البر', 4.5, (t) => _venue(t, Venue.desert)),
  Idea('city', '٢ · المدينة: مجلس حديث يطل على الأبراج', 4.5, (t) => _venue(t, Venue.city)),
  Idea('palace', '٣ · القصر: قاعة رخام وأعمدة وثريا', 4.5, (t) => _venue(t, Venue.palace)),
  Idea('kings', '٤ · الملوك: قاعة ملكية برايات ومشاعل', 4.5, (t) => _venue(t, Venue.kings)),
  Idea('vip', '٥ · نخبة VIP: صالة سودا وذهبي', 4.5, (t) => _venue(t, Venue.vip)),
  Idea('lies', '٦ · «مين كذب؟»: بنهاية اللعبة ينكشف وش وصل كل واحد ووش قال', 8.5, _lies),
  Idea('rematch', '٧ · «العب مرة ثانية» بنفس الطاولة', 7, _rematch),
  Idea('store', '٨ · الشراء بفلوس حقيقية عن طريق Google Play', 7, _store),
  Idea('iphone', '٩ · نسخة الآيفون، والدخول بحساب Apple', 6.5, _iphone),
  Idea('share', '١٠ · صورة تنشرها بعد اللعبة', 7, _share),
  Idea('roles', '١١ · أدوار جديدة: القاضي، الشيخ، الجاسوس', 8, _roles),
  Idea('spectate', '١٢ · تتفرج على لعبة أصحابك وهي شغالة', 7, _spectate),
  Idea('tournament', '١٣ · بطولة الأسبوع: من دور لدور لين النهائي', 7.5, _tournament),
  Idea('weekend', '١٤ · أحداث نهاية الأسبوع: ذهب مضاعف', 6, _weekend),
  Idea('clans', '١٥ · الدواوين: ديوان مع ربعك وترتيب أسبوعي', 7.5, _clans),
  Idea('voice', '١٦ · صوت مباشر في الروم الخاص', 6.5, _voice),
  Idea('member', '١٧ · الاشتراك الشهري (VIP)', 6.5, _member),
  Idea('ad', '١٨ · إعلان اختياري: تشوفه وتاخذ ذهب', 6.5, _ad),
  Idea('wardrobe', '١٩ · غرفة التبديل: كل اللي اشتريته بمكان واحد', 7.5, _wardrobe),
  Idea('favorites', '٢٠ · الملصقات المفضلة: ٥ بضغطة وحدة وقت اللعب', 6.5, _favorites),
];

class IdeasGalleryApp extends StatelessWidget {
  const IdeasGalleryApp(this.q, {super.key});

  final Map<String, String> q;

  @override
  Widget build(BuildContext context) {
    final only = q['only'];
    final list = [
      for (final c in ideas)
        if (only == null || c.id == only) c,
    ];
    final total = list.fold(0.0, (sum, c) => sum + c.duration);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      locale: const Locale('ar'),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Material(
          color: Colors.black,
          child: Center(
            child: FittedBox(
              child: SizedBox(
                width: sceneW,
                height: sceneH,
                child: ClipRect(
                  child: FxClock(
                    builder: (context, time) => ValueListenableBuilder<double>(
                      valueListenable: time,
                      builder: (context, now, _) {
                        var t = now % total;
                        for (final c in list) {
                          if (t < c.duration) return _Stage(idea: c, t: t);
                          t -= c.duration;
                        }
                        return _Stage(idea: list.last, t: 0);
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Stage extends StatelessWidget {
  const _Stage({required this.idea, required this.t});

  final Idea idea;
  final double t;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned.fill(child: idea.build(t)),
      Positioned(
        top: 6,
        left: 0,
        right: 0,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xEB0B0818),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.gold.withValues(alpha: .6), width: 1.2),
            ),
            child: Text(
              idea.title,
              style: const TextStyle(
                fontFamily: kufi,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.goldLight,
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

// ───────── أدوات

double seg(double t, double a, double b, [Curve curve = Curves.linear]) =>
    curve.transform(((t - a) / (b - a)).clamp(0.0, 1.0));

double bump(double t, double a, double b) => math.sin(seg(t, a, b) * math.pi);

Offset bezier(Offset a, Offset c, Offset b, double t) => a * ((1 - t) * (1 - t)) + c * (2 * (1 - t) * t) + b * (t * t);

Widget zoom(Widget child, Offset focus, double scale, double k) {
  final s = 1 + (scale - 1) * k;
  final to = Offset.lerp(focus, const Offset(sceneW / 2, sceneH / 2), k)!;
  return Transform(
    transform: Matrix4.identity()
      ..translateByDouble(to.dx, to.dy, 0, 1)
      ..scaleByDouble(s, s, 1, 1)
      ..translateByDouble(-focus.dx, -focus.dy, 0, 1),
    child: child,
  );
}

Widget at(Offset c, double w, double h, Widget child) =>
    Positioned(left: c.dx - w / 2, top: c.dy - h / 2, width: w, height: h, child: child);

Widget dim(double a) => Positioned.fill(
  child: IgnorePointer(
    child: ColoredBox(color: Colors.black.withValues(alpha: a.clamp(0.0, 1.0))),
  ),
);

Sticker sticker(String id) => stickers.firstWhere((s) => s.id == id);

/// رقم يعد من [a] لين [b].
int countTo(double t, double t0, double t1, int a, int b) => (a + (b - a) * seg(t, t0, t1, Curves.easeOut)).round();

class _Title extends StatelessWidget {
  const _Title(this.text, {this.color = AppColors.goldLight, this.size = 22});

  final String text;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Text(
    text,
    textAlign: TextAlign.center,
    style: TextStyle(
      fontFamily: kufi,
      fontSize: size,
      fontWeight: FontWeight.w700,
      color: color,
      shadows: const [Shadow(color: Colors.black, blurRadius: 10)],
    ),
  );
}

class _Chip extends StatelessWidget {
  const _Chip(this.text, {this.color = AppColors.goldLight, this.border = AppColors.gold, this.size = 13, this.icon});

  final String text;
  final Color color, border;
  final double size;
  final String? icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
    decoration: BoxDecoration(
      color: const Color(0xEB0B0818),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: border.withValues(alpha: .7)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[Gfx(icon!, size: size + 6), const SizedBox(width: 4)],
        Text(
          text,
          style: TextStyle(fontFamily: kufi, fontSize: size, fontWeight: FontWeight.w700, color: color),
        ),
      ],
    ),
  );
}

/// لوحة داكنة بحافة ذهبية.
class _Panel extends StatelessWidget {
  const _Panel({
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.border = AppColors.gold,
    this.colors,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color border;
  final List<Color>? colors;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(18),
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: colors ?? const [Color(0xF2241C46), Color(0xF2140F2B)],
      ),
      border: Border.all(color: border.withValues(alpha: .6), width: 1.5),
      boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 16, offset: Offset(0, 6))],
    ),
    child: child,
  );
}

/// زر مرسوم ينضغط مع الوقت ([press] ٠–١).
class _Btn extends StatelessWidget {
  const _Btn(
    this.label, {
    this.colors = const [Color(0xFFFFE08A), Color(0xFFD48B12)],
    this.fg = AppColors.goldInk,
    this.press = 0,
    this.height = 40,
    this.size = 16,
    this.icon,
  });

  final String label;
  final List<Color> colors;
  final Color fg;
  final double press, height, size;
  final String? icon;

  @override
  Widget build(BuildContext context) => Transform.scale(
    scale: 1 - .06 * press,
    child: Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: colors),
        border: Border.all(color: Colors.white.withValues(alpha: .4), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black45, offset: Offset(0, 4 - 3 * press), blurRadius: 6)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Gfx(icon!, size: size + 8), const SizedBox(width: 6)],
          Text(
            label,
            style: TextStyle(fontFamily: kufi, fontSize: size, fontWeight: FontWeight.w700, color: fg),
          ),
        ],
      ),
    ),
  );
}

/// إصبع اللاعب: دائرة لمس تنضغط ([press] ٠–١).
class _Touch extends StatelessWidget {
  const _Touch({this.press = 0});

  final double press;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 60,
    height: 60,
    child: Stack(
      alignment: Alignment.center,
      children: [
        if (press > 0)
          Container(
            width: 30 + 30 * press,
            height: 30 + 30 * press,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: .7 * press), width: 2),
            ),
          ),
        Container(
          width: 28 - 6 * press,
          height: 28 - 6 * press,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: .55 + .25 * press),
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 8)],
          ),
        ),
      ],
    ),
  );
}

/// إصبع يتنقل بين نقاط: [path] كل نقطة ووقت وصولها، و[presses] أوقات الضغط.
Widget? finger(double t, List<(double, Offset)> path, List<double> presses, {double hold = .22}) {
  if (t < path.first.$1 - .4 || t > path.last.$1 + .5) return null;
  var p = path.first.$2;
  for (var i = 0; i < path.length - 1; i++) {
    final (t0, a) = path[i];
    final (t1, b) = path[i + 1];
    if (t >= t0 && t <= t1) {
      p = Offset.lerp(
        a,
        b,
        Curves.easeInOut.transform(((t - t0 - .15) / math.max(.01, t1 - t0 - .15)).clamp(0.0, 1.0)),
      )!;
      break;
    }
    if (t > t1) p = b;
  }
  final press = presses.map((s) => bump(t, s, s + hold)).fold(0.0, math.max);
  return at(p, 60, 60, IgnorePointer(child: _Touch(press: press)));
}

/// كرت ينقلب: [angle] صفر يبين الوجه، وπ يبين الظهر.
class _Flip extends StatelessWidget {
  const _Flip({required this.angle, required this.front, required this.back});

  final double angle;
  final Widget front, back;

  @override
  Widget build(BuildContext context) {
    final a = angle % (2 * math.pi);
    final face = a < math.pi / 2 || a > 3 * math.pi / 2;
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, .0015)
        ..rotateY(angle),
      child: face ? front : Transform(alignment: Alignment.center, transform: Matrix4.rotationY(math.pi), child: back),
    );
  }
}

/// ورق ملون يطيح.
class _Confetti extends CustomPainter {
  _Confetti(this.t);

  final double t;

  static const _colors = [
    Color(0xFFFFD166),
    Color(0xFF06D6A0),
    Color(0xFFEF476F),
    Color(0xFF4CC9F0),
    Color(0xFFF2C14E),
    Colors.white,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (var k = 0; k < 70; k++) {
      final life = t - rnd(k, 1) * .6;
      if (life < 0) continue;
      final y = -20 + life * (130 + rnd(k, 3) * 120);
      if (y > size.height + 20) continue;
      final x = rnd(k, 2) * size.width + math.sin(life * 3 + k) * 18;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(life * (3 + rnd(k, 4) * 5) + k);
      canvas.scale(1, .25 + .75 * math.cos(life * 6 + k).abs());
      canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: 7, height: 11), Paint()..color = _colors[k % 6]);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_Confetti old) => true;
}

/// عملات (أو جواهر) تطير من [from] لـ[to] ورا بعض.
List<Widget> flyingIcons(double t, double t0, Offset from, Offset to, {String icon = 'coin', int count = 10}) => [
  for (var k = 0; k < count; k++)
    if (t > t0 + k * .06 && t < t0 + k * .06 + .75)
      at(
        bezier(
          from + Offset((rnd(k, 5) - .5) * 40, (rnd(k, 6) - .5) * 20),
          Offset((from.dx + to.dx) / 2 + (rnd(k, 7) - .5) * 120, math.min(from.dy, to.dy) - 80),
          to,
          seg(t, t0 + k * .06, t0 + k * .06 + .75, Curves.easeInCubic),
        ),
        24,
        24,
        Gfx(icon, size: 24),
      ),
];

// ───────── الطاولة (مثل اللعبة)

const _people = [
  ('emir', 'أنت'),
  ('pilot', 'فيصل'),
  ('sultana', 'العنود'),
  ('wolf', 'تركي'),
  ('falconer', 'بدر'),
  ('lady_gold', 'مها'),
];

/// مسافة الطاولة من الحواف بالنماذج (فوق أكثر شوي عشان العنوان).
const _pad = EdgeInsets.fromLTRB(20, 44, 20, 2);
const _tableSize = Size(sceneW - 40, sceneH - 46);

Rect get _rug => rugRect(_tableSize).shift(Offset(_pad.left, _pad.top));

/// نص صورة كل لاعب على الطاولة.
List<Offset> _seats(int n) {
  final rx = (_tableSize.width - 88) / 2, ry = (_tableSize.height - 114) / 2;
  return [
    for (var i = 0; i < n; i++)
      Offset(
        _pad.left + rx - rx * math.cos(math.pi / 2 + i * 2 * math.pi / n) + 44,
        _pad.top + ry + ry * math.sin(math.pi / 2 + i * 2 * math.pi / n) + 31,
      ),
  ];
}

class _Table extends StatelessWidget {
  const _Table({
    this.venue = Venue.majlis,
    this.center,
    this.people = _people,
    this.frameOf,
    this.over,
    this.room = true,
  });

  final Venue venue;
  final Widget? center;
  final List<(String, String)> people;
  final Color? Function(int i)? frameOf;
  final List<Widget> Function(List<Offset> seats)? over;

  /// الغرفة ورا الطاولة (تنطفي لما الغرفة مرسومة برا).
  final bool room;

  @override
  Widget build(BuildContext context) {
    final rug = _rug;
    final trayW = rug.width * .46, trayH = trayW * .625;
    final seats = _seats(people.length);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (room) Positioned.fill(child: MajlisRoom(venue: venue)),
        Positioned.fromRect(
          rect: rug,
          child: Image.asset('assets/tables/carpet_majlis.webp', fit: BoxFit.fill),
        ),
        Positioned(
          left: rug.left + rug.width * .045,
          top: rug.bottom - rug.height * .07 - rug.height * .3 * .62,
          child: CoffeeSet(width: rug.height * .3),
        ),
        Positioned(
          left: rug.right - rug.width * .055 - rug.height * .1,
          top: rug.bottom - rug.height * .06 - rug.height * .3,
          child: Censer(width: rug.height * .1),
        ),
        Positioned.fromRect(
          rect: Rect.fromCenter(center: rug.center, width: trayW, height: trayH),
          child: Image.asset('assets/tables/tray_majlis.webp', fit: BoxFit.fill),
        ),
        if (center != null)
          Positioned.fromRect(
            rect: Rect.fromCenter(center: rug.center, width: trayW * 1.1, height: trayH * 1.1),
            child: Center(child: center),
          ),
        for (final (i, (avatar, name)) in people.indexed)
          Positioned(
            left: seats[i].dx - 44,
            top: seats[i].dy - 31,
            width: 88,
            height: 114,
            child: _Seat(avatar: avatar, name: name, frame: frameOf?.call(i), seed: i),
          ),
        ...?over?.call(seats),
      ],
    );
  }
}

class _Seat extends StatelessWidget {
  const _Seat({required this.avatar, required this.name, this.frame, this.seed = 0});

  final String avatar, name;
  final Color? frame;
  final int seed;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Stack(
        clipBehavior: Clip.none,
        children: [
          const Positioned(left: -11, top: -12, child: Cushion(width: 84, height: 58)),
          Positioned(right: -18, top: 34, child: FloorLantern(width: 14, seed: seed)),
          PlayerAvatar(avatar: avatar, size: 62, frame: frame),
        ],
      ),
      const SizedBox(height: 3),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 7),
        decoration: BoxDecoration(
          color: const Color(0xD90B0818),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: .14)),
        ),
        child: Text(name, style: const TextStyle(fontSize: 12, height: 1.35, fontWeight: FontWeight.w800)),
      ),
    ],
  );
}

// ───────── ١–٥ الأماكن

Widget _venue(double t, Venue v) {
  final table = seg(t, 1.4, 2.1, Curves.easeOutCubic);
  return zoom(
    Stack(
      children: [
        Positioned.fill(child: MajlisRoom(venue: v)),
        if (table > 0)
          Positioned.fill(
            child: Opacity(
              opacity: table,
              child: Transform.translate(offset: Offset(0, 18 * (1 - table)), child: const _Table(room: false)),
            ),
          ),
      ],
    ),
    const Offset(400, 225),
    1.06,
    seg(t, 0, 4.5, Curves.easeInOut),
  );
}

// ───────── ٦ مين كذب؟

typedef _Gov = ({
  String pres,
  String presAv,
  String min,
  String minAv,
  String drew,
  String gave,
  String enacted,
  String presSaid,
  String minSaid,
});

const List<_Gov> _govs = [
  (
    pres: 'بدر',
    presAv: 'falconer',
    min: 'مها',
    minAv: 'lady_gold',
    drew: 'TLL',
    gave: 'LL',
    enacted: 'L',
    presSaid: 'TLL',
    minSaid: 'LL',
  ),
  (
    pres: 'تركي',
    presAv: 'wolf',
    min: 'فيصل',
    minAv: 'pilot',
    drew: 'TTL',
    gave: 'TT',
    enacted: 'T',
    presSaid: 'TTT',
    minSaid: 'TT',
  ),
  (
    pres: 'فيصل',
    presAv: 'pilot',
    min: 'مها',
    minAv: 'lady_gold',
    drew: 'LTT',
    gave: 'LT',
    enacted: 'T',
    presSaid: 'LTT',
    minSaid: 'TT',
  ),
];

int _traitors(String s) => s.split('').where((c) => c == 'T').length;

Widget _lies(double t) => Stack(
  clipBehavior: Clip.none,
  children: [
    const Positioned.fill(child: MajlisRoom()),
    dim(.78),
    const Positioned(top: 38, left: 0, right: 0, child: _Title('مين كذب؟', size: 26)),
    for (final (i, g) in _govs.indexed) _govCard(t, i, g),
    if (t > 6.1) ...[
      at(
        const Offset(248, 396),
        290,
        64,
        Transform.scale(
          scale: Curves.elasticOut.transform(seg(t, 6.1, 6.9)),
          child: const _Award(
            avatar: 'wolf',
            title: 'أكبر كذاب',
            name: 'تركي',
            color: AppColors.traitorLight,
            sticker: 'tr_mask',
          ),
        ),
      ),
      at(
        const Offset(552, 396),
        290,
        64,
        Transform.scale(
          scale: Curves.elasticOut.transform(seg(t, 6.4, 7.2)),
          child: const _Award(
            avatar: 'pilot',
            title: 'أصدق واحد',
            name: 'فيصل',
            color: AppColors.green,
            sticker: 'inn_halo',
          ),
        ),
      ),
    ],
  ],
);

Widget _govCard(double t, int i, _Gov g) {
  final s = .3 + i * 1.85;
  final appear = seg(t, s, s + .35, Curves.easeOut);
  final real = seg(t, s + .35, s + .8);
  final said = seg(t, s + .8, s + 1.1);
  final verdict = seg(t, s + 1.15, s + 1.4, Curves.easeInCubic);
  final presLied = _traitors(g.presSaid) != _traitors(g.drew);
  final minLied = _traitors(g.minSaid) != _traitors(g.gave);
  final shake = (presLied || minLied) ? bump(t, s + 1.4, s + 1.7) : 0.0;
  Widget seals(String cards, double k, double size) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (final (j, c) in cards.split('').indexed)
        Transform.scale(
          scale: seg(k, j * .2, j * .2 + .6, Curves.easeOutBack),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: Seal(loyal: c == 'L', size: size),
          ),
        ),
    ],
  );
  Widget side(String avatar, String name, String role, String real0, String said0, bool lied) => Expanded(
    child: Column(
      children: [
        PlayerAvatar(avatar: avatar, size: 40),
        Text(name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
        Text(role, style: const TextStyle(color: AppColors.muted, fontSize: 11)),
        const SizedBox(height: 4),
        const Text(
          'وصله',
          style: TextStyle(fontSize: 11, color: AppColors.goldLight, fontWeight: FontWeight.w700),
        ),
        seals(real0, real, 20),
        const SizedBox(height: 4),
        const Text(
          'قال',
          style: TextStyle(fontSize: 11, color: AppColors.goldLight, fontWeight: FontWeight.w700),
        ),
        seals(said0, said, 20),
        const SizedBox(height: 5),
        SizedBox(
          height: 26,
          child: verdict > 0
              ? Transform.rotate(
                  angle: -.18,
                  child: Transform.scale(
                    scale: 1 + (1 - verdict) * 1.6,
                    child: Opacity(
                      opacity: verdict,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          color: (lied ? AppColors.traitor : AppColors.green).withValues(alpha: .25),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: lied ? AppColors.traitorLight : AppColors.green, width: 2),
                        ),
                        child: Text(
                          lied ? 'كذاب' : 'صادق',
                          style: TextStyle(
                            fontFamily: kufi,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: lied ? AppColors.traitorLight : const Color(0xFF6DE3A0),
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              : null,
        ),
      ],
    ),
  );
  return Positioned(
    left: 400 + (i - 1) * 262.0 - 120,
    top: 76 + 30 * (1 - appear),
    width: 240,
    height: 272,
    child: Opacity(
      opacity: appear,
      child: Transform.translate(
        offset: Offset(math.sin(t * 60) * 5 * shake, 0),
        child: _Panel(
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
          border: shake > 0 ? AppColors.traitor : AppColors.gold,
          child: Column(
            children: [
              Text(
                'الحكومة ${const ['الأولى', 'الثانية', 'الثالثة'][i]}',
                style: const TextStyle(
                  fontFamily: kufi,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gold,
                  fontSize: 14,
                ),
              ),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    side(g.presAv, g.pres, 'الرئيس', g.drew, g.presSaid, presLied),
                    Container(width: 1, margin: const EdgeInsets.symmetric(vertical: 8), color: Colors.white12),
                    side(g.minAv, g.min, 'الوزير', g.gave, g.minSaid, minLied),
                  ],
                ),
              ),
              Opacity(
                opacity: said,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('تمرر ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    Seal(loyal: g.enacted == 'L', size: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _Award extends StatelessWidget {
  const _Award({
    required this.avatar,
    required this.title,
    required this.name,
    required this.color,
    required this.sticker,
  });

  final String avatar, title, name, sticker;
  final Color color;

  @override
  Widget build(BuildContext context) => _Panel(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    border: color,
    child: Row(
      children: [
        PlayerAvatar(avatar: avatar, size: 48, frame: color),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontFamily: kufi, fontSize: 17, fontWeight: FontWeight.w700, color: color),
              ),
              Text(name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
            ],
          ),
        ),
        StickerView(sticker: stickers.firstWhere((s) => s.id == sticker), size: 54, pop: false),
      ],
    ),
  );
}

// ───────── ٧ العب مرة ثانية

const _readyAt = [1.25, 1.7, 2.1, 2.5, 2.9, 3.3];

Widget _rematch(double t) {
  final ready = _readyAt.where((s) => t >= s).length;
  final count = t < 3.8 ? null : 3 - ((t - 3.9) / .5).floor();
  Widget center;
  if (t < 3.8) {
    center = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const GoldText('فزت!', size: 26),
        const SizedBox(height: 4),
        t < 1.25
            ? _Btn('العب مرة ثانية', press: bump(t, 1.0, 1.25), height: 34, size: 14)
            : const _Btn(
                'جاهز',
                colors: [Color(0xFF6DE3A0), Color(0xFF1E8E52)],
                fg: Color(0xFF062814),
                height: 34,
                size: 14,
                icon: 'check',
              ),
        const SizedBox(height: 4),
        _Chip('جاهزين ${arabicNumber(ready)} من ٦', size: 12),
      ],
    );
  } else if (count != null && count >= 1) {
    final k = ((t - 3.9) % .5) / .5;
    center = Transform.scale(
      scale: 1.6 - .6 * Curves.easeOut.transform(k),
      child: GoldText(arabicNumber(count), size: 60),
    );
  } else {
    center = Transform.scale(
      scale: Curves.elasticOut.transform(seg(t, 5.4, 6.1)),
      child: const GoldText('جولة جديدة!', size: 32),
    );
  }
  return _Table(
    venue: Venue.palace,
    center: _plate(center),
    frameOf: (i) => t >= _readyAt[i] ? AppColors.green : null,
    over: (seats) => [
      for (final (i, c) in seats.indexed)
        if (t >= _readyAt[i] && t < 5.4)
          at(
            c + const Offset(22, -22),
            26,
            26,
            Transform.scale(
              scale: Curves.elasticOut.transform(seg(t, _readyAt[i], _readyAt[i] + .5)),
              child: const Gfx('check', size: 26),
            ),
          ),
      // كروت الدور تطير لكل واحد
      for (final (i, c) in seats.indexed)
        if (t > 5.5 + i * .08 && t < 6.6 + i * .08)
          at(
            Offset.lerp(_rug.center, c, seg(t, 5.5 + i * .08, 6.2 + i * .08, Curves.easeOutCubic))!,
            30,
            42,
            Opacity(opacity: 1 - seg(t, 6.3 + i * .08, 6.6 + i * .08), child: const _MiniBack()),
          ),
      ?finger(t, [(.6, const Offset(640, 470)), (1.05, _rug.center + const Offset(0, 6))], [1.0]),
    ],
  );
}

/// لوحة داكنة فوق الصينية عشان الكلام يبان.
Widget _plate(Widget child) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
  decoration: BoxDecoration(
    color: const Color(0xE60B0818),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: AppColors.gold.withValues(alpha: .55), width: 1.5),
  ),
  child: child,
);

/// ظهر كرت صغير.
class _MiniBack extends StatelessWidget {
  const _MiniBack();

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(6),
      gradient: const LinearGradient(colors: [Color(0xFF4A3592), Color(0xFF1C1638)]),
      border: Border.all(color: AppColors.gold, width: 1.5),
    ),
    child: Center(
      child: CustomPaint(size: const Size(12, 12), painter: _Star()),
    ),
  );
}

class _Star extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) =>
      canvas.drawPath(star4(size.center(Offset.zero), size.width / 2), Paint()..color = AppColors.gold);

  @override
  bool shouldRepaint(_Star old) => false;
}

// ───────── ٨ المتجر بفلوس حقيقية

const _packs = [
  ('١٠٠', '', '٠٫٩٩ \$', 'gems', null),
  ('٥٥٠', '+١٠٪ زيادة', '٤٫٩٩ \$', 'gems', null),
  ('١٬٢٠٠', '+٢٠٪ زيادة', '٩٫٩٩ \$', 'gem_chest', 'الأكثر شراء'),
  ('٢٬٥٠٠', '+٢٥٪ زيادة', '١٩٫٩٩ \$', 'gem_chest', 'أفضل قيمة'),
];

Widget _store(double t) {
  final sheet = seg(t, 1.3, 1.65, Curves.easeOutCubic) * (1 - seg(t, 4.3, 4.65, Curves.easeInCubic));
  final gems = countTo(t, 5.0, 6.2, 340, 1540);
  const pill = Offset(70, 56);
  final chosen = Offset(400 + (2 - 1.5) * 182, 232);
  return NightBackground(
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: 44,
          right: 24,
          child: Row(
            children: [
              const Gfx('cat_cards', size: 30),
              const SizedBox(width: 6),
              const Text(
                'المتجر · الجواهر',
                style: TextStyle(fontFamily: kufi, fontSize: 20, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        Positioned(
          top: 44,
          left: 20,
          child: Transform.scale(
            scale: 1 + .15 * bump(t, 5.0, 6.3),
            child: CurrencyPill(icon: 'gem', amount: gems),
          ),
        ),
        for (final (i, (amount, bonus, price, icon, ribbon)) in _packs.indexed)
          at(
            Offset(400 + (i - 1.5) * 182, 232),
            164,
            206,
            Transform.scale(
              scale: i == 2 ? 1 - .05 * bump(t, .95, 1.2) + .04 * seg(t, 1.0, 1.3) * (1 - seg(t, 4.3, 4.6)) : 1,
              child: _Pack(
                amount: amount,
                bonus: bonus,
                price: price,
                icon: icon,
                ribbon: ribbon,
                selected: i == 2 && t > 1.0 && t < 4.6,
              ),
            ),
          ),
        if (sheet > 0) ...[
          dim(.45 * sheet),
          Positioned(
            left: 140,
            right: 140,
            bottom: -230 + 230 * sheet,
            height: 225,
            child: _PlaySheet(t: t),
          ),
        ],
        const Positioned(
          bottom: 30,
          left: 0,
          right: 0,
          child: Center(
            child: _Chip(
              'الدفع عن طريق Google Play، وما تدخل بطاقتك باللعبة',
              color: AppColors.text,
              border: AppColors.muted,
              size: 13,
            ),
          ),
        ),
        ...flyingIcons(t, 4.7, chosen, pill, icon: 'gem', count: 12),
        ?finger(
          t,
          [(.5, const Offset(680, 470)), (.95, chosen), (2.2, chosen), (2.65, const Offset(400, 412))],
          [.95, 2.65],
        ),
      ],
    ),
  );
}

class _Pack extends StatelessWidget {
  const _Pack({
    required this.amount,
    required this.bonus,
    required this.price,
    required this.icon,
    required this.ribbon,
    required this.selected,
  });

  final String amount, bonus, price, icon;
  final String? ribbon;
  final bool selected;

  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    children: [
      Positioned.fill(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF2E2266), Color(0xFF17123A)],
            ),
            border: Border.all(
              color: selected ? AppColors.gold : AppColors.diamond.withValues(alpha: .5),
              width: selected ? 3 : 1.5,
            ),
            boxShadow: [if (selected) BoxShadow(color: AppColors.gold.withValues(alpha: .5), blurRadius: 20)],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Gfx(icon, size: 74),
              Text(
                amount,
                style: const TextStyle(fontFamily: kufi, fontSize: 26, fontWeight: FontWeight.w700, height: 1.1),
              ),
              const Text(
                'جوهرة',
                style: TextStyle(color: AppColors.diamond, fontWeight: FontWeight.w800),
              ),
              SizedBox(
                height: 18,
                child: Text(
                  bonus,
                  style: const TextStyle(color: AppColors.green, fontSize: 12, fontWeight: FontWeight.w800),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(colors: [Color(0xFF6DE3A0), Color(0xFF1E8E52)]),
                ),
                child: Text(
                  price,
                  style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF062814)),
                ),
              ),
            ],
          ),
        ),
      ),
      if (ribbon != null)
        Positioned(
          top: -10,
          left: 0,
          right: 0,
          child: Center(
            child: _Chip(ribbon!, color: Colors.white, border: AppColors.traitor, size: 11),
          ),
        ),
    ],
  );
}

/// ورقة الدفع (مثل اللي تطلع من جوجل بلاي): الباقة والسعر، وزر الشراء.
class _PlaySheet extends StatelessWidget {
  const _PlaySheet({required this.t});

  final double t;

  @override
  Widget build(BuildContext context) {
    final busy = t > 2.9 && t < 3.6;
    final done = t >= 3.6;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: DefaultTextStyle(
        style: const TextStyle(color: Color(0xFF202124), fontWeight: FontWeight.w700),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Google Play', style: TextStyle(color: Color(0xFF5F6368), fontSize: 13)),
            const SizedBox(height: 10),
            Row(
              children: [
                const Gfx('gem_chest', size: 40),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('١٬٢٠٠ جوهرة', style: TextStyle(fontSize: 16)),
                      Text('مجلس الخونة', style: TextStyle(color: Color(0xFF5F6368), fontSize: 12)),
                    ],
                  ),
                ),
                const Text('٩٫٩٩ \$', style: TextStyle(fontSize: 16)),
              ],
            ),
            const Divider(height: 22),
            const Text('الدفع: بطاقة •••• ٤٢٤٢', style: TextStyle(color: Color(0xFF5F6368), fontSize: 13)),
            const Spacer(),
            Container(
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: done ? const Color(0xFF1E8E3E) : const Color(0xFF01875F),
                borderRadius: BorderRadius.circular(21),
              ),
              child: busy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (done) ...[
                          const Icon(Icons.check_circle, color: Colors.white, size: 20),
                          const SizedBox(width: 6),
                        ],
                        Text(done ? 'تم الشراء' : 'شراء', style: const TextStyle(color: Colors.white, fontSize: 16)),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────── ٩ الآيفون

Widget _iphone(double t) {
  final enter = seg(t, 0, .7, Curves.easeOutCubic);
  final game = seg(t, 2.9, 3.3);
  return Stack(
    children: [
      Positioned.fill(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(colors: [const Color(0xFF2A2350), Colors.black.withValues(alpha: 1)], radius: .9),
          ),
        ),
      ),
      at(
        Offset(400 + 300 * (1 - enter), 226),
        610,
        292,
        Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, .001)
            ..rotateY(-.35 * (1 - enter)),
          child: _Phone(
            child: Stack(
              children: [
                Positioned.fill(child: _Welcome(t: t)),
                if (game > 0)
                  Positioned.fill(
                    child: Opacity(
                      opacity: game,
                      child: const FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(width: sceneW, height: sceneH * .9, child: _Table()),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      Positioned(
        bottom: 26,
        left: 0,
        right: 0,
        child: Opacity(
          opacity: enter,
          child: const Center(child: _Chip('قريباً على App Store', size: 15)),
        ),
      ),
      ?finger(t, [(.9, const Offset(560, 470)), (1.4, const Offset(330, 180))], [1.4]),
    ],
  );
}

class _Phone extends StatelessWidget {
  const _Phone({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(
      color: const Color(0xFF0A0A0C),
      borderRadius: BorderRadius.circular(46),
      border: Border.all(color: const Color(0xFF8A8F98), width: 2.5),
      boxShadow: const [BoxShadow(color: Colors.black, blurRadius: 30, offset: Offset(0, 12))],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(36),
      child: Stack(
        children: [
          Positioned.fill(child: child),
          // الجزيرة على الجنب (الجوال بالعرض)
          Positioned(
            left: 8,
            top: 0,
            bottom: 0,
            child: Center(
              child: Container(
                width: 20,
                height: 86,
                decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _Welcome extends StatelessWidget {
  const _Welcome({required this.t});

  final double t;

  @override
  Widget build(BuildContext context) {
    final confirm = seg(t, 1.7, 1.95) * (1 - seg(t, 2.7, 2.9));
    return Stack(
      children: [
        const Positioned.fill(child: MajlisRoom()),
        dim(.55),
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.asset('assets/logo.png', width: 90, height: 90),
                  ),
                  const SizedBox(height: 6),
                  const GoldText('مجلس الخونة', size: 22),
                ],
              ),
              const SizedBox(width: 30),
              SizedBox(
                width: 230,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _Btn(
                      'تسجيل الدخول عبر Apple',
                      colors: const [Color(0xFF111111), Color(0xFF000000)],
                      fg: Colors.white,
                      press: bump(t, 1.4, 1.62),
                      height: 38,
                      size: 14,
                    ),
                    const SizedBox(height: 8),
                    const _Btn(
                      'المتابعة بحساب قوقل',
                      colors: [Colors.white, Color(0xFFE8E8E8)],
                      fg: Color(0xFF202124),
                      height: 38,
                      size: 14,
                    ),
                    const SizedBox(height: 8),
                    const _Btn(
                      'ادخل كضيف',
                      colors: [Color(0x33FFFFFF), Color(0x22FFFFFF)],
                      fg: Colors.white,
                      height: 38,
                      size: 14,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (confirm > 0)
          Positioned(
            left: 0,
            right: 0,
            bottom: -90 + 100 * confirm,
            child: Center(
              child: _Panel(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const PlayerAvatar(avatar: 'emir', size: 36),
                    const SizedBox(width: 10),
                    const Text('دخلت باسم: أبو فهد', style: TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(width: 8),
                    const Gfx('check', size: 22),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ───────── ١٠ صورة تنشرها

Widget _share(double t) {
  final pop = Curves.easeOutBack.transform(seg(t, .15, .7));
  final sheet = seg(t, 2.2, 2.55, Curves.easeOutCubic) * (1 - seg(t, 4.9, 5.3));
  final fly = seg(t, 4.1, 4.8, Curves.easeInCubic);
  const target = Offset(612, 392);
  final cardPos = Offset.lerp(const Offset(400, 214), target, fly)!;
  return Stack(
    clipBehavior: Clip.none,
    children: [
      const Positioned.fill(child: _Table()),
      dim(.6),
      if (fly < 1) at(cardPos, 232, 312, Transform.scale(scale: pop * (1 - .88 * fly), child: const _ShareCard())),
      if (sheet > 0)
        Positioned(
          left: 60,
          right: 60,
          bottom: -130 + 136 * sheet,
          height: 124,
          child: _Panel(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Column(
              children: [
                const Text(
                  'شارك مع',
                  style: TextStyle(fontFamily: kufi, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _ShareTarget('واتساب', const Color(0xFF25D366), Icons.chat_bubble, press: bump(t, 3.9, 4.12)),
                    const _ShareTarget('سناب', Color(0xFFFFE600), Icons.circle_outlined, dark: true),
                    const _ShareTarget('انستقرام', Color(0xFFD62976), Icons.crop_square_rounded),
                    const _ShareTarget('إكس', Color(0xFF111111), Icons.close),
                    const _ShareTarget('حفظ', Color(0xFF475569), Icons.download_rounded),
                  ],
                ),
              ],
            ),
          ),
        ),
      if (t > 5.1)
        at(
          const Offset(400, 214),
          320,
          90,
          Opacity(
            opacity: seg(t, 5.1, 5.4),
            child: Transform.scale(
              scale: Curves.elasticOut.transform(seg(t, 5.1, 5.8)),
              child: const _Panel(
                border: AppColors.green,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _Title('انرسلت لأصحابك!', color: Color(0xFF6DE3A0), size: 20),
                    Text('أي واحد يدخل من صورتك ينضاف لأصحابك', style: TextStyle(fontSize: 12, color: AppColors.muted)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ?finger(t, [(3.2, const Offset(500, 470)), (3.85, target)], [3.9]),
    ],
  );
}

class _ShareTarget extends StatelessWidget {
  const _ShareTarget(this.label, this.color, this.icon, {this.dark = false, this.press = 0});

  final String label;
  final Color color;
  final IconData icon;
  final bool dark;
  final double press;

  @override
  Widget build(BuildContext context) => Transform.scale(
    scale: 1 - .1 * press,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border: Border.all(color: Colors.white24, width: 1.5),
          ),
          child: Icon(icon, color: dark ? Colors.black : Colors.white, size: 24),
        ),
        const SizedBox(height: 3),
        Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
      ],
    ),
  );
}

/// الصورة اللي تنشرها: شخصيتك ونتيجتك، ودعوة للعبة.
class _ShareCard extends StatelessWidget {
  const _ShareCard();

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.gold, width: 3),
      boxShadow: [BoxShadow(color: AppColors.gold.withValues(alpha: .4), blurRadius: 30)],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(17),
      child: Stack(
        children: [
          const Positioned.fill(child: MajlisRoom(venue: Venue.kings)),
          dim(.35),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                const Text(
                  'مجلس الخونة',
                  style: TextStyle(fontFamily: kufi, color: AppColors.goldLight, fontSize: 13),
                ),
                const SizedBox(height: 8),
                const SizedBox(
                  width: 120,
                  height: 120,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      PlayerAvatar(avatar: 'wolf', size: 120, frame: AppColors.traitor),
                      Positioned(right: -8, bottom: -6, child: LeaderSeal(size: 46)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const GoldText('كنت الزعيم', size: 26),
                const Text(
                  'ومحد كشفني!',
                  style: TextStyle(fontFamily: kufi, fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                const Wrap(
                  spacing: 6,
                  children: [
                    _Chip('فزت', color: Color(0xFF6DE3A0), border: AppColors.green, size: 11),
                    _Chip('٨ جولات', size: 11),
                    _Chip('كذبت ٣ مرات', color: AppColors.traitorLight, border: AppColors.traitor, size: 11),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(10)),
                  child: const Text(
                    'حمّل اللعبة وتحداني · رمزي ٤٨٢٩',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
