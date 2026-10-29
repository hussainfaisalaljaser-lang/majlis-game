import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/shop.dart';
import '../theme.dart';
import 'design.dart';
import 'design_shop.dart';

/// كروت باقات الملصقات بالتصميم الجديد (المتجر وغرفة التبديل):
/// فوق شريط رق فيه أول أربع ملصقات من الباقة جنب بعض، وتحته لوح مخمل بورغندي باسم الباقة بالأبيض،
/// وبعده زر أخضر «عندك» لو تملكها (أو زر السعر)، ودرجتها فوق اليمين وعين المعاينة فوق اليسار،
/// وحدود الكرت بلون الدرجة (الملحمي والأسطوري أسمك وفيهم توهج).

const _edge = Color(0xFF2B190E);

/// مقاس كرت الباقة بالمتجر (يتكبر ويصغر مع الشبكة بنفس النسبة).
const stickerPackCardW = 214.0;
const stickerPackCardH = 176.0;

/// الفراغ بين طرف الكرت والمحتوى (حد غامق + حد الدرجة + حد غامق داخلي).
const _inset = 8.0;

/// فوق الشريط: مكان درجة الباقة وعين المعاينة.
const _topRoom = 22.0;

/// ارتفاع لوح الاسم (بدون زر / مع زر).
const _plateBare = 36.0;
const _plateFull = 76.0;

/// شكل حدود الكرت لكل درجة.
typedef _Look = ({Color light, Color mid, Color dark, double band, double glow});

_Look _lookOf(Rarity r) => switch (r) {
  Rarity.common => (light: const Color(0xFFC9CDDB), mid: const Color(0xFF9097B3), dark: const Color(0xFF5D6485), band: 4, glow: 0),
  Rarity.rare => (light: const Color(0xFFABCEFF), mid: const Color(0xFF5E9BF1), dark: const Color(0xFF2B5BAA), band: 4, glow: .22),
  Rarity.epic => (light: const Color(0xFFDFC4FF), mid: const Color(0xFFA872EB), dark: const Color(0xFF5F30A5), band: 4.5, glow: .5),
  Rarity.legendary => (light: const Color(0xFFFFF0B8), mid: const Color(0xFFFFC94D), dark: const Color(0xFFB9741A), band: 5, glow: .7),
};

/// عينات كلام باقة العبارات (تطلع بالفقاعات على كرتها).
List<String> stickerPackPhrases(String packId, {int take = 2}) => [
  for (final r in textReactions)
    if (r.pack == packId) r.label,
].take(take).toList();

/// ارتفاع الكرت لعرض معيّن: [shown] ملصقات بصف أو أكثر (كل صف [perRow])، و[action] لو فيه زر تحت الاسم.
double stickerPackHeight(double width, {int shown = 4, int perRow = 4, bool action = true}) {
  final size = _stickerSize(width, shown < perRow ? shown : perRow, perRow);
  final rows = (shown / perRow).ceil().clamp(1, 9);
  return _inset * 2 + _topRoom + rows * size + 8 + (action ? _plateFull : _plateBare);
}

/// حجم الملصق بالشريط: ربع عرض الكرت تقريباً (ويتداخلون شوي لو الكرت ضيق).
double _stickerSize(double width, int count, int perRow) {
  final inner = width - _inset * 2 - 6;
  return math.min(64, inner / perRow * (perRow == 4 ? 1.15 : 1));
}

/// كرت باقة ملصقات (أو باقة كلام لو [phrases] بدال [stickers]).
/// [width] هو عرضه الفعلي، وارتفاعه من [stickerPackHeight]. بالشبكة يتحط داخل FittedBox ويصغر مع الخلية.
class StickerPackCard extends StatelessWidget {
  const StickerPackCard({
    super.key,
    required this.name,
    required this.rarity,
    this.stickers,
    this.phrases,
    this.action,
    this.width = stickerPackCardW,
    this.shown = 4,
    this.perRow = 4,
    this.dim = false,
    this.onTap,
    this.onPreview,
    this.semantics,
    this.stickerBuilder,
  }) : assert(stickers != null || phrases != null, 'لازم ملصقات أو عبارات');

  final String name;
  final Rarity rarity;

  /// معرفات ملصقات الباقة (تنعرض أول [shown] منها).
  final List<String>? stickers;

  /// باقة كلام: نصوص عينات تطلع بفقاعات بدال الملصقات.
  final List<String>? phrases;

  /// الزر اللي تحت الاسم (عندك، السعر، من وين ينكسب). بدونه يطلع لوح الاسم بس.
  final Widget? action;
  final double width;

  /// عدد الملصقات الظاهرة، وكم بالصف الواحد.
  final int shown;
  final int perRow;

  /// الباقة مقفولة: الملصقات تبهت.
  final bool dim;
  final VoidCallback? onTap;
  final VoidCallback? onPreview;
  final String? semantics;

  /// لو انعطى، كل ملصق ينرسم فيه (غرفة التبديل: ضغطة مطوّلة للمفضلة)، بدون ميلان ولا تداخل.
  final Widget Function(String id, double size)? stickerBuilder;

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final ids = stickers?.take(shown).toList() ?? const <String>[];
    final count = phrases != null ? 1 : ids.length;
    final size = _stickerSize(width, count < perRow ? count : perRow, perRow);
    final rows = phrases != null ? 1 : (ids.length / perRow).ceil().clamp(1, 9);
    final stripH = _topRoom + rows * size + 8;
    final plateH = action == null ? _plateBare : _plateFull;
    final height = _inset * 2 + stripH + plateH;
    final inner = width - _inset * 2;
    final interactive = stickerBuilder != null;
    return Semantics(
      label: semantics,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: width,
          height: height,
          child: _PackFrame(
            rarity: rarity,
            child: Stack(
              children: [
                // شريط الرق (ورا الملصقات)
                Positioned(top: 0, left: 0, right: 0, height: stripH, child: _Strip(rarity: rarity)),
                // لوح المخمل: الاسم والزر
                Positioned(
                  top: stripH,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _Plate(name: name, action: action),
                ),
                // الملصقات (تنزل شوي فوق اللوح عشان تبان طالعة من الشريط)
                if (phrases != null)
                  Positioned(
                    top: _topRoom - 3,
                    left: 6,
                    right: 6,
                    height: rows * size + 8,
                    child: Opacity(opacity: dim ? .55 : 1, child: _PhraseBubbles(texts: phrases!, width: inner - 12)),
                  )
                else
                  for (var i = 0; i < ids.length; i++)
                    _place(
                      i: i,
                      n: ids.length,
                      size: size,
                      inner: inner,
                      rtl: rtl,
                      tilt: !interactive,
                      child: Opacity(
                        opacity: dim ? .55 : 1,
                        child: interactive ? stickerBuilder!(ids[i], size) : _StaticSticker(id: ids[i], size: size),
                      ),
                    ),
                if (rarity == Rarity.epic || rarity == Rarity.legendary)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: stripH,
                    child: IgnorePointer(
                      child: CustomPaint(painter: _SparklePainter(_lookOf(rarity).light)),
                    ),
                  ),
                PositionedDirectional(top: 4, start: 5, child: ShopRarityTag(rarity)),
                if (onPreview != null) PositionedDirectional(top: 3, end: 3, child: ShopEyeButton(onTap: onPreview)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// مكان الملصق رقم [i]: صفوف من [perRow]، والأول عند بداية الكرت، ويميلون شوي مثل الصورة.
  Widget _place({
    required int i,
    required int n,
    required double size,
    required double inner,
    required bool rtl,
    required bool tilt,
    required Widget child,
  }) {
    final row = i ~/ perRow;
    final inRow = math.min(perRow, n - row * perRow);
    final col = i % perRow;
    final span = inner - size - 6;
    // تباعد الملصقات بالصف: لو ما ساعد العرض يتداخلون شوي
    final step = inRow == 1 ? 0.0 : (tilt ? span / (inRow - 1) : math.min(span / (inRow - 1), size + 4));
    final used = step * (inRow - 1);
    final start = 3 + (span - used) / 2 + col * step;
    const tilts = [-.06, .045, -.035, .06, -.05, .04];
    Widget w = SizedBox(width: size, height: size, child: child);
    if (tilt) w = Transform.rotate(angle: tilts[i % tilts.length], child: w);
    return Positioned(
      top: _topRoom + row * size,
      left: rtl ? null : start,
      right: rtl ? start : null,
      child: w,
    );
  }
}

/// ملصق ثابت بظل خفيف (كروت الشبكة كثيرة، فما نحركها: الحركة داخل المعاينة).
class _StaticSticker extends StatelessWidget {
  const _StaticSticker({required this.id, required this.size});

  final String id;
  final double size;

  @override
  Widget build(BuildContext context) {
    final s = stickerById(id);
    if (s == null) return const SizedBox.shrink();
    Widget img() => Image.asset(
      s.asset,
      width: size,
      height: size,
      cacheWidth: (size * 3).round(),
      filterQuality: FilterQuality.medium,
    );
    return ExcludeSemantics(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            top: size * .05,
            child: ColorFiltered(colorFilter: const ColorFilter.mode(Color(0x66000000), BlendMode.srcIn), child: img()),
          ),
          img(),
        ],
      ),
    );
  }
}

/// حدود الكرت بلون الدرجة: حد غامق، ثم شريط الدرجة، ثم حد غامق داخلي، وبعدها المحتوى.
class _PackFrame extends StatelessWidget {
  const _PackFrame({required this.rarity, required this.child});

  final Rarity rarity;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final k = _lookOf(rarity);
    const outer = 20.0;
    final band = outer - 1.5;
    final dark = band - k.band;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(outer),
        color: _edge,
        boxShadow: [
          if (k.glow > 0) BoxShadow(color: k.mid.withValues(alpha: k.glow), blurRadius: 12, spreadRadius: 1),
          BoxShadow(color: Colors.black.withValues(alpha: .4), blurRadius: 7, offset: const Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(1.5),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(band),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [k.light, k.mid, k.dark],
              stops: const [0, .5, 1],
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(k.band),
            child: DecoratedBox(
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(dark), color: _edge),
              child: Padding(
                padding: EdgeInsets.all(_inset - 1.5 - k.band),
                child: ClipRRect(borderRadius: BorderRadius.circular(dark - (_inset - 1.5 - k.band)), child: child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// شريط الرق اللي تقعد عليه الملصقات (أطرافه أغمق مثل كروت المتجر، وتحته لمسة من لون الدرجة).
class _Strip extends StatelessWidget {
  const _Strip({required this.rarity});

  final Rarity rarity;

  @override
  Widget build(BuildContext context) {
    final tint = _lookOf(rarity).mid;
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.parchmentDark,
        image: DecorationImage(image: AssetImage(DesignAssets.parchmentWide), fit: BoxFit.fill),
      ),
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            radius: 1.0,
            colors: [Colors.transparent, Colors.transparent, const Color(0xFF5A3418).withValues(alpha: .32)],
            stops: const [0, .6, 1],
          ),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, tint.withValues(alpha: .1)],
            ),
          ),
        ),
      ),
    );
  }
}

/// لوح المخمل البورغندي: خط ذهب فوق، واسم الباقة بالأبيض بحد غامق، وتحته [action].
class _Plate extends StatelessWidget {
  const _Plate({required this.name, required this.action});

  final String name;
  final Widget? action;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      color: Color(0xFF45131E),
      image: DecorationImage(image: AssetImage(DesignAssets.velvet), fit: BoxFit.cover),
    ),
    child: Stack(
      children: [
        // تعتيم خفيف لتحت (ورا النص والزر، عشان ما يغمّقهم)
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, const Color(0xFF14030A).withValues(alpha: .45)],
              ),
            ),
          ),
        ),
        Column(
          children: [
            // خط الذهب اللي يفصل الرق عن المخمل
            Container(
              height: 3.5,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: goldRingColors,
                ),
                border: Border(bottom: BorderSide(color: Color(0xFF24130A), width: 1)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 1, 12, 0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: OutlinedText(
                        name,
                        size: 17,
                        maxLines: 1,
                        color: Colors.white,
                        stroke: const Color(0xFF1C0509),
                        strokeWidth: 3.6,
                      ),
                    ),
                    if (action != null) ...[
                      const SizedBox(height: 1),
                      SizedBox(height: 31, child: action),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

/// زر الباقة: لو تملكها أخضر لامع «عندك» وعليه علامة صح، وغير كذا زر الشراء أو من وين ينكسب (مثل بقية المتجر).
class StickerPackPill extends StatelessWidget {
  const StickerPackPill({
    super.key,
    required this.state,
    this.icon,
    this.price,
    this.source,
    this.sourceIcon = 'trophy',
    this.onTap,
    this.busy = false,
    this.height = 31,
    this.fontSize = 15,
    this.ownedLabel = 'عندك',
  });

  final ShopItemState state;
  final String? icon;
  final int? price;
  final String? source;
  final String sourceIcon;
  final VoidCallback? onTap;
  final bool busy;
  final double height;
  final double fontSize;
  final String ownedLabel;

  @override
  Widget build(BuildContext context) {
    final owned = state == ShopItemState.owned || state == ShopItemState.equipped;
    if (busy || !owned) {
      return ShopActionButton(
        state: state,
        icon: icon,
        price: price,
        source: source,
        sourceIcon: sourceIcon,
        onTap: onTap,
        busy: busy,
        height: height,
        fontSize: fontSize,
      );
    }
    return ShopButton(
      onPressed: null,
      dimWhenOff: false,
      height: height,
      radius: 12,
      semantics: ownedLabel,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(width: height * .55, height: height * .55, child: CustomPaint(painter: _CheckPainter())),
          const SizedBox(width: 6),
          OutlinedText(
            ownedLabel,
            size: fontSize + 1,
            maxLines: 1,
            stroke: const Color(0xFF143A0B),
            strokeWidth: (fontSize + 1) * .2,
          ),
        ],
      ),
    );
  }
}

/// علامة صح بقرص كريمي (على الزر الأخضر).
class _CheckPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero), r = size.width / 2;
    canvas.drawCircle(c, r, Paint()..color = const Color(0xFFFFF4D6));
    canvas.drawCircle(
      c,
      r - .5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = const Color(0xFF143A0B),
    );
    final tick = Path()
      ..moveTo(c.dx - r * .42, c.dy + r * .02)
      ..lineTo(c.dx - r * .1, c.dy + r * .34)
      ..lineTo(c.dx + r * .46, c.dy - r * .3);
    canvas.drawPath(
      tick,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * .3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0xFF2E781D),
    );
  }

  @override
  bool shouldRepaint(_CheckPainter old) => false;
}

/// باقة الكلام: فقاعتين كلام متداخلين على الشريط (بدال الملصقات).
class _PhraseBubbles extends StatelessWidget {
  const _PhraseBubbles({required this.texts, required this.width});

  final List<String> texts;
  final double width;

  @override
  Widget build(BuildContext context) {
    final fs = (width * .066).clamp(10.0, 15.0);
    final a = texts.isNotEmpty ? texts[0] : '…';
    final b = texts.length > 1 ? texts[1] : null;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        PositionedDirectional(
          top: 2,
          start: width * .02,
          child: Transform.rotate(
            angle: -.045,
            child: _Bubble(text: a, size: fs, fill: const [Color(0xFFFFFBF0), Color(0xFFF0DDB4)], tailEnd: true),
          ),
        ),
        if (b != null)
          PositionedDirectional(
            bottom: 2,
            end: width * .02,
            child: Transform.rotate(
              angle: .04,
              child: _Bubble(text: b, size: fs, fill: const [Color(0xFFFFE9A8), Color(0xFFF0B84A)], tailEnd: false),
            ),
          ),
      ],
    );
  }
}

/// فقاعة كلام كرتونية: حد بني غامق وذيل صغير، والنص بالنص.
class _Bubble extends StatelessWidget {
  const _Bubble({required this.text, required this.size, required this.fill, required this.tailEnd});

  final String text;
  final double size;
  final List<Color> fill;

  /// الذيل عند نهاية الفقاعة (اليسار بالعربي) أو بدايتها.
  final bool tailEnd;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _BubblePainter(fill: fill, tailEnd: tailEnd, rtl: Directionality.of(context) == TextDirection.rtl),
    child: Padding(
      padding: EdgeInsets.fromLTRB(size * .8, size * .38, size * .8, size * .38 + size * .5),
      child: Text(
        text,
        maxLines: 1,
        style: TextStyle(
          fontFamily: kufi,
          fontSize: size,
          fontWeight: FontWeight.w800,
          height: 1.15,
          color: AppColors.ink,
        ),
      ),
    ),
  );
}

class _BubblePainter extends CustomPainter {
  const _BubblePainter({required this.fill, required this.tailEnd, required this.rtl});

  final List<Color> fill;
  final bool tailEnd;
  final bool rtl;

  @override
  void paint(Canvas canvas, Size size) {
    final tailH = size.height * .26;
    final body = Rect.fromLTWH(0, 0, size.width, size.height - tailH);
    final r = RRect.fromRectAndRadius(body, Radius.circular(body.height * .42));
    // الذيل: يقع على الطرف الأيمن لو tailEnd وكان يسار-يمين، والعكس بالعربي
    final onRight = tailEnd != rtl;
    final x = onRight ? size.width * .74 : size.width * .26;
    final dir = onRight ? 1.0 : -1.0;
    final tail = Path()
      ..moveTo(x - dir * size.width * .07, body.bottom - 2)
      ..lineTo(x + dir * size.width * .05, size.height)
      ..lineTo(x + dir * size.width * .12, body.bottom - 2)
      ..close();
    final shape = Path.combine(PathOperation.union, Path()..addRRect(r), tail);
    canvas.drawShadow(shape, const Color(0xFF000000), 2.5, true);
    canvas.drawPath(
      shape,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: fill,
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      shape,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0xFF3A2312),
    );
    // لمعة خفيفة فوق
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(body.width * .08, body.height * .1, body.width * .84, body.height * .22),
        Radius.circular(body.height * .12),
      ),
      Paint()..color = Colors.white.withValues(alpha: .35),
    );
  }

  @override
  bool shouldRepaint(_BubblePainter old) => old.fill != fill || old.tailEnd != tailEnd || old.rtl != rtl;
}

/// لمعات صغيرة على شريط الملحمي والأسطوري.
class _SparklePainter extends CustomPainter {
  const _SparklePainter(this.color);

  final Color color;

  void _star(Canvas canvas, Offset p, double r, Paint paint) {
    final path = Path()
      ..moveTo(p.dx, p.dy - r)
      ..quadraticBezierTo(p.dx, p.dy, p.dx + r, p.dy)
      ..quadraticBezierTo(p.dx, p.dy, p.dx, p.dy + r)
      ..quadraticBezierTo(p.dx, p.dy, p.dx - r, p.dy)
      ..quadraticBezierTo(p.dx, p.dy, p.dx, p.dy - r)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final glow = Paint()..color = color.withValues(alpha: .9);
    final white = Paint()..color = Colors.white.withValues(alpha: .95);
    _star(canvas, Offset(size.width * .3, size.height * .3), 5.5, glow);
    _star(canvas, Offset(size.width * .52, size.height * .22), 3.2, white);
    _star(canvas, Offset(size.width * .72, size.height * .78), 4.6, glow);
    _star(canvas, Offset(size.width * .09, size.height * .74), 3.4, white);
  }

  @override
  bool shouldRepaint(_SparklePainter old) => old.color != color;
}
