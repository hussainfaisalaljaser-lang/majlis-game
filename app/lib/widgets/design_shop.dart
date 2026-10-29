import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/profile.dart';
import '../models/shop.dart';
import '../theme.dart';
import 'common.dart';
import 'design.dart';
import 'fx.dart';
import 'item_preview.dart';

/// قطع المتجر وغرفة التبديل بالتصميم الجديد (كروت رق، لوحة مخمل، أزرار لامعة، شريط الأقسام).
/// كل شي هنا مرسوم بالكود بنفس أسلوب التصميم: حدود بنية غامقة، تدرجات دافية، ولمعة فوق الأزرار.

const _ink = AppColors.ink;
const _edge = Color(0xFF2B190E);
const _gold = Color(0xFFE8B54E);

/// مقاس تصميم الكرت (يتكبر ويصغر مع الشبكة بنفس النسبة).
const shopCardW = 140.0;
const shopCardWideW = 214.0;
const shopCardH = 167.0;

// ───────────────────────── الأزرار ─────────────────────────

enum ShopTone { green, red, orange, blue, dark }

typedef _Look = ({List<Color> colors, Color outline, Color depth, Color text});

const Map<ShopTone, _Look> _looks = {
  ShopTone.green: (
    colors: [Color(0xFF86DB58), Color(0xFF4FAB31), Color(0xFF2E781D)],
    outline: Color(0xFF143A0B),
    depth: Color(0xFF1F5513),
    text: Color(0xFF143A0B),
  ),
  ShopTone.red: (
    colors: [Color(0xFFF4714A), Color(0xFFD6411F), Color(0xFFA7281A)],
    outline: Color(0xFF4C0D04),
    depth: Color(0xFF7A1A0C),
    text: Color(0xFF4C0D04),
  ),
  ShopTone.orange: (
    colors: [Color(0xFFFFC04A), Color(0xFFF59A1A), Color(0xFFDA7008)],
    outline: Color(0xFF6A3004),
    depth: Color(0xFFA2500A),
    text: Color(0xFF6A3004),
  ),
  ShopTone.blue: (
    colors: [Color(0xFF66B9F8), Color(0xFF2F83D9), Color(0xFF1B59A3)],
    outline: Color(0xFF0B2953),
    depth: Color(0xFF123F7A),
    text: Color(0xFF0B2953),
  ),
  ShopTone.dark: (
    colors: [Color(0xFF4A2E1B), Color(0xFF331F11), Color(0xFF22130A)],
    outline: Color(0xFF130B06),
    depth: Color(0xFF130B06),
    text: Color(0xFF130B06),
  ),
};

/// زر لامع بحافة غامقة وظل تحت ولمعة فوق (أزرار الشراء والبس في التصميم).
/// [child] يحط فيه اللي تبي، أو استخدم [ShopButton.label] لنص بحد غامق.
class ShopButton extends StatefulWidget {
  const ShopButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.tone = ShopTone.green,
    this.height = 34,
    this.radius = 11,
    this.dimWhenOff = true,
    this.semantics,
  });

  ShopButton.label(
    String label, {
    Key? key,
    required VoidCallback? onPressed,
    ShopTone tone = ShopTone.green,
    double height = 34,
    double radius = 11,
    double fontSize = 16,
    bool dimWhenOff = true,
  }) : this(
         key: key,
         onPressed: onPressed,
         tone: tone,
         height: height,
         radius: radius,
         dimWhenOff: dimWhenOff,
         semantics: label,
         child: OutlinedText(
           label,
           size: fontSize,
           maxLines: 1,
           stroke: _looks[tone]!.text,
           strokeWidth: fontSize * .2,
         ),
       );

  final Widget child;
  final VoidCallback? onPressed;
  final ShopTone tone;
  final double height;
  final double radius;

  /// الزر المطفي (ما له ضغط) يبهت، إلا زر «لابسه» يبقى كامل.
  final bool dimWhenOff;
  final String? semantics;

  @override
  State<ShopButton> createState() => _ShopButtonState();
}

class _ShopButtonState extends State<ShopButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final look = _looks[widget.tone]!;
    final enabled = widget.onPressed != null;
    final depth = _down ? 1.0 : 3.0;
    final r = BorderRadius.circular(widget.radius);
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semantics,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapUp: enabled ? (_) => setState(() => _down = false) : null,
        onTapCancel: () => setState(() => _down = false),
        onTap: widget.onPressed,
        child: Opacity(
          opacity: enabled || !widget.dimWhenOff ? 1 : .5,
          child: SizedBox(
            height: widget.height,
            child: Padding(
              padding: EdgeInsets.only(top: 3 - depth, bottom: depth),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: r,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: look.colors,
                    stops: const [0, .55, 1],
                  ),
                  border: Border.all(color: look.outline, width: 2),
                  boxShadow: [
                    BoxShadow(color: look.depth, offset: Offset(0, depth)),
                    BoxShadow(color: look.outline, offset: Offset(0, depth + 1.5)),
                    BoxShadow(color: Colors.black.withValues(alpha: .35), blurRadius: 6, offset: Offset(0, depth + 3)),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // لمعة الزر: شريط أبيض شفاف بالنص الفوقاني
                    Positioned(
                      left: 5,
                      right: 5,
                      top: 2,
                      height: (widget.height - 6) * .42,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(widget.radius * .7),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.white.withValues(alpha: .42), Colors.white.withValues(alpha: .1)],
                          ),
                        ),
                      ),
                    ),
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: widget.child),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// سعر: الرقم ومعه أيقونة العملة (ذهب أو جوهرة) على الجنب.
class ShopPrice extends StatelessWidget {
  const ShopPrice(this.icon, this.amount, {super.key, this.size = 17, this.tone = ShopTone.green});

  final String icon;
  final int amount;
  final double size;
  final ShopTone tone;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      // العملة على طرف الزر (اليمين) والرقم بنص الباقي، مثل أزرار التصميم
      Gfx(icon, size: size * 1.45),
      Expanded(
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: OutlinedText(
              arabicNumber(amount),
              size: size,
              maxLines: 1,
              stroke: _looks[tone]!.text,
              strokeWidth: size * .2,
            ),
          ),
        ),
      ),
    ],
  );
}

/// حالة الغرض عند اللاعب.
enum ShopItemState { equipped, owned, buy, locked }

/// منطقة الزر اللي تحت الكرت: يتغير حسب حالة الغرض (اشتر، البس، لابسه، أو من وين ينكسب).
class ShopActionButton extends StatelessWidget {
  const ShopActionButton({
    super.key,
    required this.state,
    this.icon,
    this.price,
    this.source,
    this.sourceIcon = 'trophy',
    this.onTap,
    this.busy = false,
    this.ownedLabel = 'البس',
    this.equippedLabel = 'لابسه',
    this.passive,
    this.buyLabel,
    this.height = 33,
    this.fontSize = 16,
  });

  final ShopItemState state;
  final String? icon;
  final int? price;
  final String? source;
  final String sourceIcon;
  final VoidCallback? onTap;
  final bool busy;
  final String ownedLabel;
  final String equippedLabel;

  /// غرض ما ينلبس (الملصقات): بدال البس يطلع هالنص بلوح أخضر.
  final String? passive;

  /// نص زر الشراء بدال السعر (عرض اليوم: «اشتر الحين»).
  final String? buyLabel;
  final double height;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    if (busy) {
      return ShopButton(
        onPressed: null,
        tone: ShopTone.dark,
        height: height,
        dimWhenOff: false,
        child: const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.gold),
        ),
      );
    }
    return switch (state) {
      ShopItemState.equipped => ShopButton.label(
        equippedLabel,
        onPressed: null,
        tone: ShopTone.orange,
        height: height,
        fontSize: fontSize,
        dimWhenOff: false,
      ),
      ShopItemState.owned when passive != null => ShopButton(
        onPressed: null,
        tone: ShopTone.dark,
        height: height,
        dimWhenOff: false,
        semantics: passive,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Gfx('check', size: 20),
            const SizedBox(width: 6),
            OutlinedText(passive!, size: fontSize - 1, maxLines: 1, stroke: const Color(0xFF130B06)),
          ],
        ),
      ),
      ShopItemState.owned => ShopButton.label(
        ownedLabel,
        onPressed: onTap,
        tone: ShopTone.red,
        height: height,
        fontSize: fontSize,
      ),
      ShopItemState.buy when buyLabel != null => ShopButton.label(
        buyLabel!,
        onPressed: onTap,
        height: height,
        fontSize: fontSize,
        radius: 14,
      ),
      ShopItemState.buy => ShopButton(
        onPressed: onTap,
        height: height,
        semantics: 'اشتر',
        child: ShopPrice(icon ?? 'coin', price ?? 0, size: fontSize + 1),
      ),
      ShopItemState.locked => ShopButton(
        onPressed: null,
        tone: ShopTone.dark,
        height: height,
        dimWhenOff: false,
        semantics: source,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Gfx(sourceIcon, size: 20),
            const SizedBox(width: 5),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  source ?? '',
                  maxLines: 1,
                  style: const TextStyle(
                    fontFamily: kufi,
                    color: Color(0xFFF3C766),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    };
  }
}

// ───────────────────────── الشارات والعدادات ─────────────────────────

/// شارة الدرجة (عادي، نادر، ملحمي، أسطوري) على زاوية الكرت.
class ShopRarityTag extends StatelessWidget {
  const ShopRarityTag(this.rarity, {super.key, this.size = 11.5});

  final Rarity rarity;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = rarity.color;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: size * .75, vertical: size * .1),
      decoration: BoxDecoration(
        color: Color.lerp(const Color(0xFF2A2133), c, .3)!.withValues(alpha: .92),
        borderRadius: BorderRadius.circular(size * .75),
        border: Border.all(color: c.withValues(alpha: .4)),
      ),
      child: Text(
        rarity.label,
        style: TextStyle(
          fontFamily: kufi,
          color: Color.lerp(c, Colors.white, .15),
          fontSize: size,
          fontWeight: FontWeight.w700,
          height: 1.3,
        ),
      ),
    );
  }
}

/// قرص بني غامق بحلقة ذهب وفيه عين (زر المعاينة على الكرت).
class ShopEyeButton extends StatelessWidget {
  const ShopEyeButton({super.key, required this.onTap, this.size = 22});

  final VoidCallback? onTap;
  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'معاينة',
    excludeSemantics: true,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(colors: [Color(0xFF5A3720), Color(0xFF301B0D)]),
          border: Border.all(color: const Color(0xFF86613B), width: 1.6),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: .35), blurRadius: 3, offset: const Offset(0, 1.5)),
          ],
        ),
        child: CustomPaint(painter: _EyePainter()),
      ),
    ),
  );
}

class _EyePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, c = size.center(Offset.zero);
    final eye = Path()
      ..moveTo(w * .18, c.dy)
      ..quadraticBezierTo(c.dx, c.dy - w * .34, w * .82, c.dy)
      ..quadraticBezierTo(c.dx, c.dy + w * .34, w * .18, c.dy)
      ..close();
    canvas.drawPath(eye, Paint()..color = const Color(0xFFFFF1CF));
    canvas.drawPath(
      eye,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * .06
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0xFF1A0E07),
    );
    canvas.drawCircle(c, w * .15, Paint()..color = const Color(0xFFB8741F));
    canvas.drawCircle(c, w * .075, Paint()..color = const Color(0xFF1A0E07));
    canvas.drawCircle(c + Offset(-w * .04, -w * .05), w * .03, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_EyePainter old) => false;
}

/// قرص ذهب شفاف (فاصلة الأرقام): عداد عملة غامق كبير مثل شريط التصميم.
class ShopChip extends StatelessWidget {
  const ShopChip({super.key, required this.child, this.onTap, this.semantics});

  final Widget child;
  final VoidCallback? onTap;
  final String? semantics;

  @override
  Widget build(BuildContext context) => Semantics(
    button: onTap != null,
    label: semantics,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A0F09).withValues(alpha: .94),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .35), blurRadius: 5, offset: const Offset(0, 2))],
        ),
        child: Center(child: child),
      ),
    ),
  );
}

/// رقم عملة بشريط التصميم: الرقم والأيقونة على الجنب.
class ShopCurrency extends StatelessWidget {
  const ShopCurrency({super.key, required this.icon, required this.amount, this.infinite = false});

  final String icon;
  final int amount;
  final bool infinite;

  @override
  Widget build(BuildContext context) => ShopChip(
    semantics: icon == 'coin' ? 'الذهب' : 'الجواهر',
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        OutlinedText(
          infinite ? '∞' : arabicNumber(amount),
          size: infinite ? 22 : 17,
          strokeWidth: 3,
          stroke: const Color(0xFF0C0603),
          shadow: false,
        ),
        const SizedBox(width: 8),
        Gfx(icon, size: 23),
      ],
    ),
  );
}

/// شريط العنوان: سهم الرجوع واسم الشاشة بأيقونتها على اليمين، والعدادات والأزرار على اليسار.
class ShopTopBar extends StatelessWidget {
  const ShopTopBar({super.key, required this.title, this.icon, this.center, this.trailing = const []});

  final String title;
  final Widget? icon;

  /// عنوان بالنص (غرفة التبديل).
  final Widget? center;

  /// الأزرار والعدادات، تترتب من اليمين لليسار.
  final List<Widget> trailing;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 46,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          const BackArrow(height: 30),
          if (icon != null) ...[icon!, const SizedBox(width: 6)],
          OutlinedText(
            title,
            size: 27,
            maxLines: 1,
            color: const Color(0xFFFFF1D0),
            stroke: const Color(0xFF5A1A10),
            strokeWidth: 5,
          ),
          // العنوان الثاني بوسط المساحة اللي بين العنوان والعدادات (ويصغر لو ضاقت)
          Expanded(
            child: center == null
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: FittedBox(fit: BoxFit.scaleDown, child: center),
                  ),
          ),
          for (final (i, w) in trailing.indexed) ...[if (i > 0) const SizedBox(width: 8), w],
        ],
      ),
    ),
  );
}

/// زر «غرفة التبديل» بالشريط: الاسم بالذهبي وبلورة زرقا.
class ShopTitleChip extends StatelessWidget {
  const ShopTitleChip({super.key, required this.label, required this.onTap, this.crystal = true});

  final String label;
  final VoidCallback onTap;
  final bool crystal;

  @override
  Widget build(BuildContext context) => ShopChip(
    onTap: onTap,
    semantics: label,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        OutlinedText(
          label,
          size: 16.5,
          gradient: goldTitleColors,
          stroke: const Color(0xFF0C0603),
          strokeWidth: 3,
          shadow: false,
        ),
        if (crystal) ...[const SizedBox(width: 7), const CustomPaint(size: Size(22, 22), painter: _CrystalPainter())],
      ],
    ),
  );
}

/// بلورة زرقا (أيقونة زر غرفة التبديل).
class _CrystalPainter extends CustomPainter {
  const _CrystalPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final body = Path()
      ..moveTo(w * .5, w * .02)
      ..lineTo(w * .86, w * .3)
      ..lineTo(w * .74, w * .86)
      ..lineTo(w * .5, w * .98)
      ..lineTo(w * .24, w * .84)
      ..lineTo(w * .12, w * .3)
      ..close();
    canvas.drawPath(
      body,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF9FD8FF), Color(0xFF3F8BE0), Color(0xFF1C4FA8)],
        ).createShader(Offset.zero & size),
    );
    final facet = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * .05
      ..color = const Color(0xFFDCF1FF).withValues(alpha: .8);
    canvas.drawLine(Offset(w * .12, w * .3), Offset(w * .5, w * .42), facet);
    canvas.drawLine(Offset(w * .86, w * .3), Offset(w * .5, w * .42), facet);
    canvas.drawLine(Offset(w * .5, w * .42), Offset(w * .5, w * .98), facet);
    canvas.drawPath(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * .07
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0xFF0C2A63),
    );
  }

  @override
  bool shouldRepaint(_CrystalPainter old) => false;
}

// ───────────────────────── شريط الأقسام ─────────────────────────

/// قسم بالشريط الجانبي: مفتاح الأيقونة والاسم.
class ShopCategory {
  const ShopCategory(this.icon, this.label);

  final String icon;
  final String label;
}

/// شريط الأقسام العمودي (على اليمين): أيقونة واسم، والمختار بإطار ذهبي.
class ShopRail extends StatelessWidget {
  const ShopRail({super.key, required this.items, required this.selected, required this.onSelect});

  final List<ShopCategory> items;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) => Container(
    width: 86,
    decoration: BoxDecoration(
      color: const Color(0xFF3A2313),
      image: DecorationImage(
        image: const AssetImage(DesignAssets.woodPanel),
        fit: BoxFit.cover,
        colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: .12), BlendMode.darken),
      ),
      borderRadius: const BorderRadiusDirectional.only(topEnd: Radius.circular(26)),
      border: const BorderDirectional(end: BorderSide(color: Color(0xFF1A0E07), width: 3)),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .5), blurRadius: 10)],
    ),
    child: LayoutBuilder(
      builder: (context, box) {
        // الأقسام تصغر على الشاشات القصيرة وتتمرر لو زادت
        final h = ((box.maxHeight - 12) / 7.4).clamp(50.0, 68.0);
        return ListView(
          padding: const EdgeInsets.fromLTRB(5, 8, 5, 8),
          children: [
            for (final (i, c) in items.indexed)
              _RailItem(cat: c, height: h, selected: i == selected, onTap: () => onSelect(i)),
          ],
        );
      },
    ),
  );
}

class _RailItem extends StatelessWidget {
  const _RailItem({required this.cat, required this.height, required this.selected, required this.onTap});

  final ShopCategory cat;
  final double height;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: 'قسم ${cat.label}',
    excludeSemantics: true,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: height,
        margin: const EdgeInsets.symmetric(vertical: 2.5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: selected
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF4A2F1B), Color(0xFF2A170B)],
                )
              : null,
          border: Border.all(color: selected ? _gold : Colors.transparent, width: 2.4),
          boxShadow: selected ? [BoxShadow(color: _gold.withValues(alpha: .25), blurRadius: 8)] : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: selected ? 1.06 : 1,
              duration: const Duration(milliseconds: 180),
              child: ShopCatIcon(cat.icon, size: height * .52),
            ),
            SizedBox(height: height * .04),
            Text(
              cat.label,
              maxLines: 1,
              style: TextStyle(
                fontFamily: kufi,
                fontSize: (height * .2).clamp(10.5, 13.0),
                fontWeight: FontWeight.w700,
                height: 1.2,
                color: selected ? const Color(0xFFFFF1D0) : const Color(0xFFEBD3A8),
                shadows: const [Shadow(color: Color(0xFF140A05), offset: Offset(0, 1.5), blurRadius: 2)],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// أيقونة قسم: مرسومة بالكود (إطار، فقاعات، ملصقات، طاولات، كروت)، والباقي من أيقونات اللعبة.
class ShopCatIcon extends StatelessWidget {
  const ShopCatIcon(this.id, {super.key, this.size = 36});

  final String id;
  final double size;

  @override
  Widget build(BuildContext context) => switch (id) {
    'avatar' => Image.asset('assets/avatars/emir.webp', width: size, height: size, fit: BoxFit.contain),
    'offers' => Gfx('gift', size: size),
    'death' => Gfx('skull', size: size),
    'ids' => Gfx('idcard', size: size),
    'gems' => Gfx('gem', size: size),
    _ => CustomPaint(size: Size.square(size), painter: _CatIconPainter(id)),
  };
}

class _CatIconPainter extends CustomPainter {
  const _CatIconPainter(this.id);

  final String id;

  static const _dark = Color(0xFF2E1A0C);

  @override
  void paint(Canvas canvas, Size size) {
    switch (id) {
      case 'frame':
        _frame(canvas, size.width);
      case 'bubble':
        _scroll(canvas, size.width);
      case 'sticker':
        _stamp(canvas, size.width);
      case 'table':
        _divan(canvas, size.width);
      case 'cards':
        _cards(canvas, size.width);
    }
  }

  Paint _line(double w, [Color c = _dark]) => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round
    ..color = c;

  Shader _grad(Rect r, List<Color> colors, {bool diagonal = false}) => LinearGradient(
    begin: diagonal ? Alignment.topLeft : Alignment.topCenter,
    end: diagonal ? Alignment.bottomRight : Alignment.bottomCenter,
    colors: colors,
  ).createShader(r);

  /// إطار صورة برونزي منقوش.
  void _frame(Canvas c, double w) {
    final outer = RRect.fromRectAndRadius(Rect.fromLTWH(w * .1, w * .07, w * .8, w * .86), Radius.circular(w * .08));
    c.drawRRect(
      outer,
      Paint()
        ..shader = _grad(outer.outerRect, const [
          Color(0xFFEDBE6A),
          Color(0xFFB27A32),
          Color(0xFF7A4A1C),
        ], diagonal: true),
    );
    final inner = RRect.fromRectAndRadius(outer.outerRect.deflate(w * .17), Radius.circular(w * .03));
    c.drawRRect(inner, Paint()..color = const Color(0xFF2A190D));
    c.drawRRect(inner, _line(w * .035, const Color(0xFF6A431F)));
    c.drawRRect(outer.deflate(w * .045), _line(w * .02, const Color(0xFFFFE19A).withValues(alpha: .7)));
    c.drawRRect(outer, _line(w * .05));
    for (final o in [
      outer.outerRect.topLeft,
      outer.outerRect.topRight,
      outer.outerRect.bottomLeft,
      outer.outerRect.bottomRight,
    ]) {
      final d = Offset(
        (outer.outerRect.center.dx - o.dx).sign * w * .075,
        (outer.outerRect.center.dy - o.dy).sign * w * .075,
      );
      c.drawCircle(o + d, w * .04, Paint()..color = const Color(0xFFFFE19A));
    }
  }

  /// لفافة رق وخطاب فوقها بختم أحمر.
  void _scroll(Canvas c, double w) {
    final paper = RRect.fromRectAndRadius(Rect.fromLTWH(w * .1, w * .14, w * .58, w * .6), Radius.circular(w * .04));
    c.drawRRect(paper, Paint()..shader = _grad(paper.outerRect, const [Color(0xFFF7E8C6), Color(0xFFDDBC82)]));
    c.drawRRect(paper, _line(w * .045));
    final roll = RRect.fromRectAndRadius(Rect.fromLTWH(w * .06, w * .07, w * .66, w * .13), Radius.circular(w * .065));
    c.drawRRect(roll, Paint()..shader = _grad(roll.outerRect, const [Color(0xFFFFF2D2), Color(0xFFC99A58)]));
    c.drawRRect(roll, _line(w * .045));
    for (var i = 0; i < 3; i++) {
      final y = w * (.3 + i * .1);
      c.drawLine(Offset(w * .2, y), Offset(w * (.55 - i * .05), y), _line(w * .03, const Color(0xFF8A5E2E)));
    }
    final env = RRect.fromRectAndRadius(Rect.fromLTWH(w * .36, w * .48, w * .56, w * .4), Radius.circular(w * .04));
    c.drawRRect(env, Paint()..shader = _grad(env.outerRect, const [Color(0xFFFFF4DA), Color(0xFFE3C58C)]));
    final flap = Path()
      ..moveTo(w * .37, w * .5)
      ..lineTo(w * .64, w * .7)
      ..lineTo(w * .91, w * .5);
    c.drawPath(flap, _line(w * .035));
    c.drawRRect(env, _line(w * .045));
    c.drawCircle(Offset(w * .64, w * .7), w * .06, Paint()..color = const Color(0xFFC62E22));
    c.drawCircle(Offset(w * .64, w * .7), w * .06, _line(w * .025, const Color(0xFF5A0E08)));
  }

  /// طابع بريد بختم شمع أحمر.
  void _stamp(Canvas c, double w) {
    final r = Rect.fromLTWH(w * .1, w * .1, w * .8, w * .8);
    c.saveLayer(r.inflate(2), Paint());
    c.drawRect(r, Paint()..shader = _grad(r, const [Color(0xFFF9EBCB), Color(0xFFE0BE82)], diagonal: true));
    final hole = Paint()..blendMode = BlendMode.clear;
    const n = 6;
    for (var i = 0; i <= n; i++) {
      final t = i / n;
      for (final o in [
        Offset(r.left + r.width * t, r.top),
        Offset(r.left + r.width * t, r.bottom),
        Offset(r.left, r.top + r.height * t),
        Offset(r.right, r.top + r.height * t),
      ]) {
        c.drawCircle(o, w * .035, hole);
      }
    }
    c.restore();
    c.drawRect(r.deflate(w * .06), _line(w * .02, const Color(0xFFB98C4A)));
    final ctr = r.center;
    c.drawCircle(ctr + Offset(0, w * .02), w * .27, Paint()..color = const Color(0xFF3A0E08).withValues(alpha: .35));
    c.drawCircle(
      ctr,
      w * .27,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-.3, -.35),
          colors: [Color(0xFFEA5A48), Color(0xFFB02418), Color(0xFF7A140D)],
        ).createShader(Rect.fromCircle(center: ctr, radius: w * .27)),
    );
    c.drawCircle(ctr, w * .27, _line(w * .035, const Color(0xFF4A0C07)));
    c.drawCircle(ctr, w * .17, _line(w * .03, const Color(0xFFF08A78).withValues(alpha: .55)));
  }

  /// كنبة مجلس: ظهر منقوش ومخدة ورجول.
  void _divan(Canvas c, double w) {
    final back = RRect.fromRectAndRadius(Rect.fromLTWH(w * .1, w * .26, w * .8, w * .3), Radius.circular(w * .04));
    final crown = Path()
      ..moveTo(w * .12, w * .27)
      ..quadraticBezierTo(w * .24, w * .1, w * .36, w * .24)
      ..quadraticBezierTo(w * .5, w * .02, w * .64, w * .24)
      ..quadraticBezierTo(w * .76, w * .1, w * .88, w * .27)
      ..close();
    c.drawPath(
      crown,
      Paint()..shader = _grad(Rect.fromLTWH(0, w * .02, w, w * .3), const [Color(0xFFF0C77A), Color(0xFFC2893B)]),
    );
    c.drawPath(crown, _line(w * .04));
    c.drawRRect(back, Paint()..shader = _grad(back.outerRect, const [Color(0xFFE3AF5E), Color(0xFFA9692A)]));
    c.drawRRect(back.deflate(w * .045), _line(w * .02, const Color(0xFF6A3E16)));
    c.drawRRect(back, _line(w * .045));
    final seat = RRect.fromRectAndRadius(Rect.fromLTWH(w * .06, w * .52, w * .88, w * .2), Radius.circular(w * .06));
    c.drawRRect(seat, Paint()..shader = _grad(seat.outerRect, const [Color(0xFFF6DFA8), Color(0xFFD7A95E)]));
    c.drawRRect(seat, _line(w * .045));
    for (final x in [.12, .8]) {
      final leg = RRect.fromRectAndRadius(Rect.fromLTWH(w * x, w * .7, w * .08, w * .2), Radius.circular(w * .02));
      c.drawRRect(leg, Paint()..color = const Color(0xFF8A5528));
      c.drawRRect(leg, _line(w * .04));
    }
  }

  /// ورقتين لعب: واحدة بقلب والثانية ببستوني.
  void _cards(Canvas c, double w) {
    void card(Offset at, double angle, bool spade) {
      c.save();
      c.translate(at.dx, at.dy);
      c.rotate(angle);
      final r = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: w * .44, height: w * .62),
        Radius.circular(w * .05),
      );
      c.drawRRect(r, Paint()..shader = _grad(r.outerRect, const [Color(0xFFFFFAEB), Color(0xFFE8D3A6)]));
      c.drawRRect(r, _line(w * .045));
      final sym = Rect.fromCenter(center: Offset(0, w * .02), width: w * .24, height: w * .26);
      c.drawPath(
        spade ? _spade(sym) : _heart(sym),
        Paint()..color = spade ? const Color(0xFF2A1A12) : const Color(0xFFD2362B),
      );
      c.restore();
    }

    card(Offset(w * .36, w * .52), -.28, false);
    card(Offset(w * .62, w * .5), .2, true);
  }

  static Path _heart(Rect r) {
    final cx = r.center.dx;
    return Path()
      ..moveTo(cx, r.bottom)
      ..cubicTo(
        r.left - r.width * .15,
        r.center.dy + r.height * .05,
        r.left + r.width * .0,
        r.top - r.height * .12,
        cx,
        r.top + r.height * .28,
      )
      ..cubicTo(
        r.right - r.width * .0,
        r.top - r.height * .12,
        r.right + r.width * .15,
        r.center.dy + r.height * .05,
        cx,
        r.bottom,
      )
      ..close();
  }

  static Path _spade(Rect r) {
    final cx = r.center.dx;
    final body = Path()
      ..moveTo(cx, r.top)
      ..cubicTo(
        r.left - r.width * .2,
        r.top + r.height * .55,
        r.left + r.width * .0,
        r.bottom - r.height * .1,
        cx,
        r.bottom - r.height * .3,
      )
      ..cubicTo(
        r.right - r.width * .0,
        r.bottom - r.height * .1,
        r.right + r.width * .2,
        r.top + r.height * .55,
        cx,
        r.top,
      )
      ..close();
    final stem = Path()
      ..moveTo(cx, r.bottom - r.height * .35)
      ..lineTo(cx - r.width * .16, r.bottom + r.height * .08)
      ..lineTo(cx + r.width * .16, r.bottom + r.height * .08)
      ..close();
    return Path.combine(PathOperation.union, body, stem);
  }

  @override
  bool shouldRepaint(_CatIconPainter old) => old.id != id;
}

// ───────────────────────── الكروت ─────────────────────────

/// إطار الكرت: حد بني غامق، وداخله رق (أو مخمل للغامق)، والمختار بحلقة ذهب حوله.
class ShopCardFrame extends StatelessWidget {
  const ShopCardFrame({
    super.key,
    required this.child,
    this.dark = false,
    this.selected = false,
    this.radius = 14,
    this.wide = false,
    this.rarity,
  });

  final Widget child;

  /// رق عريض (للكروت الطويلة مثل باقات الملصقات).
  final bool wide;

  /// ندرة الغرض: لكل ندرة خلفية (النادر جليد، الملحمي بنفسجي بأشعة، الأسطوري ذهب يلمع). العادي رق. null = رق.
  final Rarity? rarity;

  /// خلفية غامقة (للإطارات الغامقة اللي ما تبان على الرق): مخمل، أو بدرجة ندرتها الغامقة لو نادر وفوق.
  final bool dark;

  /// الكرت اللي لابسه: حلقة ذهب حوله.
  final bool selected;
  final double radius;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(radius + 8),
      color: selected ? _gold : Colors.transparent,
      boxShadow: [
        if (selected) BoxShadow(color: _gold.withValues(alpha: .45), blurRadius: 10),
        BoxShadow(color: Colors.black.withValues(alpha: .4), blurRadius: 7, offset: const Offset(0, 4)),
      ],
    ),
    child: Padding(
      padding: EdgeInsets.all(selected ? 2.2 : 0),
      child: DecoratedBox(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(radius + 5.5), color: _edge),
        child: Padding(
          padding: const EdgeInsets.all(3.5),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              color: dark ? const Color(0xFF45131E) : AppColors.parchmentDark,
              image: _plain
                  ? DecorationImage(
                      image: AssetImage(
                        dark ? DesignAssets.velvet : (wide ? DesignAssets.parchmentWide : DesignAssets.parchment),
                      ),
                      fit: dark ? BoxFit.cover : BoxFit.fill,
                    )
                  : null,
              border: Border.all(
                color: _plain ? (dark ? const Color(0xFF2A0B12) : const Color(0xFF4E331F)) : rarity!.color.withValues(alpha: .75),
                width: 1.5,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              // أطراف الورق أغمق من النص (حروق الرق)
              child: DecoratedBox(
                position: DecorationPosition.foreground,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    radius: .95,
                    colors: [
                      Colors.transparent,
                      Colors.transparent,
                      (dark ? const Color(0xFF0F0305) : const Color(0xFF5A3418)).withValues(alpha: dark ? .35 : .3),
                    ],
                    stops: const [0, .62, 1],
                  ),
                ),
                child: _plain ? child : Stack(fit: StackFit.expand, children: [RarityBackdrop(rarity!, dark: dark), child]),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  /// رق عادي (أو مخمل للغامق) بدون خلفية ندرة؟ للعادي وبدون ندرة بس.
  bool get _plain => rarity == null || rarity == Rarity.common;
}

/// خلفية الكرت حسب ندرته: نادر جليد أزرق بلمعات، ملحمي بنفسجي بأشعة، أسطوري ذهب بأشعة ولمعة تمر.
/// ألوانها فاتحة عشان رسمات الأغراض (المصممة على الرق) تبقى واضحة.
class RarityBackdrop extends StatelessWidget {
  const RarityBackdrop(this.rarity, {super.key, this.dark = false});

  final Rarity rarity;

  /// درجة غامقة (للإطارات الغامقة): نفس الألوان بس بالليل، والأشعة أخف.
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final (top, bottom) = dark
        ? switch (rarity) {
            Rarity.rare => (const Color(0xFF1F4A74), const Color(0xFF0B1B35)),
            Rarity.epic => (const Color(0xFF4A2478), const Color(0xFF170A33)),
            _ => (const Color(0xFF7A5212), const Color(0xFF2A1705)),
          }
        : switch (rarity) {
            Rarity.rare => (const Color(0xFFE4F4FF), const Color(0xFF9CCBF0)),
            Rarity.epic => (const Color(0xFFF0E2FF), const Color(0xFFB690EA)),
            _ => (const Color(0xFFFFF6C8), const Color(0xFFF1BD45)),
          };
    final art = CustomPaint(painter: _RarityArtPainter(rarity, null, dark: dark), size: Size.infinite);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [top, bottom]),
      ),
      // الأسطوري: لمعة تمر ببطء. الباقي ثابت (كروت كثيرة بالشاشة، فنوفّر).
      child: rarity == Rarity.legendary
          ? RepaintBoundary(
              child: FxClock(builder: (context, time) => CustomPaint(painter: _RarityArtPainter(rarity, time, dark: dark))),
            )
          : art,
    );
  }
}

class _RarityArtPainter extends CustomPainter {
  _RarityArtPainter(this.rarity, this.time, {this.dark = false}) : super(repaint: time);

  final Rarity rarity;
  final ValueListenable<double>? time;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final t = time?.value ?? 0.0;
    final c = Offset(w / 2, h * .42);
    if (rarity == Rarity.rare) {
      // لمعات ثلج صغيرة
      final p = Paint();
      for (var i = 0; i < 16; i++) {
        final x = rnd(i, 1) * w, y = rnd(i, 2) * h;
        p.color = Colors.white.withValues(alpha: .55 + .35 * rnd(i, 3));
        canvas.drawCircle(Offset(x, y), .8 + rnd(i, 4) * 1.6, p);
        if (i % 5 == 0) {
          p
            ..strokeWidth = .9
            ..color = Colors.white.withValues(alpha: .8);
          canvas.drawLine(Offset(x - 4, y), Offset(x + 4, y), p);
          canvas.drawLine(Offset(x, y - 4), Offset(x, y + 4), p);
        }
      }
      return;
    }
    // أشعة من ورا الرسمة
    final rays = Path();
    const n = 14;
    final r = math.max(w, h);
    for (var i = 0; i < n; i++) {
      final a = (rarity == Rarity.legendary ? t * .08 : 0) + i * 2 * math.pi / n;
      rays
        ..moveTo(c.dx, c.dy)
        ..lineTo(c.dx + math.cos(a - .09) * r, c.dy + math.sin(a - .09) * r)
        ..lineTo(c.dx + math.cos(a + .09) * r, c.dy + math.sin(a + .09) * r)
        ..close();
    }
    canvas.drawPath(
      rays,
      Paint()..color = Colors.white.withValues(alpha: (rarity == Rarity.legendary ? .3 : .2) * (dark ? .55 : 1)),
    );
    canvas.drawCircle(
      c,
      w * .55,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: (rarity == Rarity.legendary ? .6 : .4) * (dark ? .45 : 1)),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: c, radius: w * .55)),
    );
    if (rarity == Rarity.legendary) {
      // لمعة مائلة تمر كل ٥ ثواني
      final sp = (t % 5) / 1.4;
      if (sp < 1) {
        final x = -w * .3 + (w * 1.6) * sp;
        canvas.drawPath(
          Path()
            ..moveTo(x, 0)
            ..lineTo(x + w * .18, 0)
            ..lineTo(x - w * .1, h)
            ..lineTo(x - w * .28, h)
            ..close(),
          Paint()..color = Colors.white.withValues(alpha: .35 * math.sin(math.pi * sp)),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_RarityArtPainter old) => old.rarity != rarity || old.dark != dark;
}

/// كرت غرض: درجته فوق اليمين، وعين المعاينة فوق اليسار، والرسمة بالنص، واسمه، وزره تحت.
class ShopItemCard extends StatelessWidget {
  const ShopItemCard({
    super.key,
    required this.art,
    required this.rarity,
    required this.action,
    this.name,
    this.dark = false,
    this.selected = false,
    this.dim = false,
    this.wide = false,
    this.onTap,
    this.onPreview,
    this.semantics,
  });

  final Widget art;
  final Rarity rarity;
  final Widget action;
  final String? name;
  final bool dark;
  final bool selected;

  /// الغرض مقفول: الرسمة تبهت.
  final bool dim;
  final bool wide;
  final VoidCallback? onTap;
  final VoidCallback? onPreview;
  final String? semantics;

  @override
  Widget build(BuildContext context) {
    final w = wide ? shopCardWideW : shopCardW;
    final nameColor = dark ? const Color(0xFFFFEFD0) : _ink;
    return Semantics(
      label: semantics,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: FittedBox(
          child: SizedBox(
            width: w,
            height: shopCardH,
            child: ShopCardFrame(
              dark: dark,
              selected: selected,
              rarity: rarity,
              child: Stack(
                children: [
                  Positioned(
                    left: 6,
                    right: 6,
                    top: name == null ? 18 : 16,
                    height: name == null ? 104 : 92,
                    child: Center(
                      child: Opacity(
                        opacity: dim ? .55 : 1,
                        child: FittedBox(fit: BoxFit.scaleDown, child: art),
                      ),
                    ),
                  ),
                  if (name != null)
                    Positioned(
                      left: 6,
                      right: 6,
                      top: 103,
                      height: 21,
                      child: Center(
                        child: Text(
                          name!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: kufi,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            height: 1.25,
                            color: nameColor,
                          ),
                        ),
                      ),
                    ),
                  Positioned(left: 7, right: 7, top: 122, height: 36, child: action),
                  PositionedDirectional(top: 4, start: 5, child: ShopRarityTag(rarity)),
                  if (onPreview != null) PositionedDirectional(top: 3, end: 3, child: ShopEyeButton(onTap: onPreview)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// كومة عملات أو جواهر (لكروت باقات الذهب والجواهر).
class ShopPile extends StatelessWidget {
  const ShopPile({super.key, required this.icon, this.count = 3, this.size = 60});

  final String icon;
  final int count;
  final double size;

  /// أماكن القطع (نسبة من المساحة الفاضية بعد حجم القطعة): الصف اللي تحت أول، وفوقه الأعلى.
  static const _spots = <int, List<(double, double)>>{
    1: [(.5, .5)],
    2: [(0, .6), (.9, .2)],
    3: [(0, .75), (.95, .75), (.45, .05)],
    4: [(0, .8), (.95, .8), (.12, .35), (.8, .3)],
    5: [(0, .85), (.95, .85), (.05, .45), (.95, .45), (.45, .0)],
    6: [(0, .85), (.95, .85), (.0, .45), (.95, .45), (.25, .05), (.7, .05)],
  };

  @override
  Widget build(BuildContext context) {
    final spots = _spots[count.clamp(1, 6)]!;
    final piece = size * .5;
    final free = size - piece;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (final (dx, dy) in spots)
            Positioned(
              left: dx * free,
              top: dy * free,
              child: Gfx(icon, size: piece * (icon == 'coin' ? 1 : 1.25)),
            ),
        ],
      ),
    );
  }
}

/// كرت باقة (ذهب أو جواهر): الكمية بخط كبير ومعها كومة، والسعر بزر أخضر.
class ShopPackCard extends StatelessWidget {
  const ShopPackCard({
    super.key,
    required this.pile,
    required this.amount,
    required this.unit,
    required this.price,
    this.badge,
    this.onTap,
  });

  final Widget pile;
  final String amount;
  final String unit;
  final String price;

  /// زيادة (+١٠٪) فوق الكرت.
  final String? badge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: FittedBox(
      child: SizedBox(
        width: shopCardW,
        height: 118,
        child: ShopCardFrame(
          child: Stack(
            children: [
              PositionedDirectional(
                top: 10,
                start: 12,
                end: 12,
                height: 54,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(
                              amount,
                              style: const TextStyle(
                                fontFamily: kufi,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: _ink,
                                height: 1.1,
                              ),
                            ),
                          ),
                          Text(
                            unit,
                            style: const TextStyle(
                              fontFamily: kufi,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF8A6A44),
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    pile,
                  ],
                ),
              ),
              if (badge != null)
                PositionedDirectional(
                  top: 5,
                  end: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E781D),
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: const Color(0xFF143A0B), width: 1.4),
                    ),
                    child: Text(
                      badge!,
                      style: const TextStyle(
                        fontFamily: kufi,
                        color: Color(0xFFFFF8E8),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        height: 1.3,
                      ),
                    ),
                  ),
                ),
              Positioned(
                left: 8,
                right: 8,
                bottom: 8,
                height: 36,
                child: ShopButton.label(price, onPressed: onTap, height: 36, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

// ───────────────────────── الأشعة والبطاقات الكبيرة ─────────────────────────

/// أشعة تدور ببطء (خلف عرض اليوم ونوافذ الغرض الجديد).
class ShopSunburst extends StatefulWidget {
  const ShopSunburst({super.key, required this.color, this.rays = 14, this.center = Alignment.center, this.fade = .4});

  final Color color;
  final int rays;
  final Alignment center;

  /// قوة آخر الشعاع بالنسبة لأوله.
  final double fade;

  @override
  State<ShopSunburst> createState() => _ShopSunburstState();
}

class _ShopSunburstState extends State<ShopSunburst> with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(vsync: this, duration: const Duration(seconds: 70));

  @override
  void initState() {
    super.initState();
    // بالتصوير والحركات الخفيفة الأشعة ثابتة
    if (FxClock.manual.value == null && !FxClock.lite.value) _spin.repeat();
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: RepaintBoundary(
      child: CustomPaint(
        size: Size.infinite,
        painter: _SunPainter(_spin, widget.color, widget.rays, widget.center, widget.fade),
      ),
    ),
  );
}

class _SunPainter extends CustomPainter {
  _SunPainter(this.spin, this.color, this.rays, this.center, this.fade) : super(repaint: spin);

  final Animation<double> spin;
  final Color color;
  final int rays;
  final Alignment center;
  final double fade;

  @override
  void paint(Canvas canvas, Size size) {
    final o = center.alongSize(size);
    final r = size.longestSide * .9;
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          color,
          color.withValues(alpha: color.a * fade),
        ],
      ).createShader(Rect.fromCircle(center: o, radius: r));
    final step = math.pi * 2 / rays;
    final rot = spin.value * math.pi * 2;
    final path = Path();
    for (var i = 0; i < rays; i++) {
      final a = rot + i * step;
      path
        ..moveTo(o.dx, o.dy)
        ..lineTo(o.dx + math.cos(a) * r, o.dy + math.sin(a) * r)
        ..lineTo(o.dx + math.cos(a + step * .46) * r, o.dy + math.sin(a + step * .46) * r)
        ..close();
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_SunPainter old) => old.color != color || old.rays != rays || old.center != center;
}

/// نافذة رق بإطار ذهبي داخلي وشريط أحمر بعنوانها فوق (معاينة الغرض، والغرض الجديد).
class ShopDialogCard extends StatelessWidget {
  const ShopDialogCard({super.key, required this.title, required this.child, this.width = 340, this.sun = true});

  final String title;
  final Widget child;
  final double width;

  /// أشعة كريمي خلف المحتوى.
  final bool sun;

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.sizeOf(context).height * .94;
    return SizedBox(
      width: width,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 22),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxH - 22),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: _edge,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: .55), blurRadius: 24, offset: const Offset(0, 10)),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: AppColors.parchmentDark,
                      image: const DecorationImage(image: AssetImage(DesignAssets.parchment), fit: BoxFit.fill),
                      border: Border.all(color: const Color(0xFF4E331F), width: 2),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Stack(
                        children: [
                          if (sun)
                            Positioned.fill(
                              child: ShopSunburst(
                                color: const Color(0xFFFFF4D6).withValues(alpha: .75),
                                rays: 16,
                                center: const Alignment(0, -.32),
                                fade: .5,
                              ),
                            ),
                          Positioned.fill(
                            child: Padding(
                              padding: const EdgeInsets.all(9),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(13),
                                  border: Border.all(color: _gold, width: 2.4),
                                ),
                              ),
                            ),
                          ),
                          SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(22, 34, 22, 18),
                            child: DefaultTextStyle.merge(
                              style: const TextStyle(color: _ink),
                              child: child,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          IntrinsicWidth(child: RibbonTitle(title, size: 21)),
        ],
      ),
    );
  }
}

/// نافذة «غرضك الجديد»: شريط عنوان، والغرض كبير على الأشعة، وجملة، وزر «حلو!».
class ShopRevealCard extends StatelessWidget {
  const ShopRevealCard({
    super.key,
    required this.title,
    required this.art,
    required this.message,
    this.button = 'حلو!',
    this.onClose,
  });

  final String title;
  final Widget art;
  final String message;
  final String button;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) => ShopDialogCard(
    title: title,
    width: 340,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          // على الشاشات القصيرة الرسمة تصغر عشان النافذة كلها تنحط بدون تمرير
          height: (MediaQuery.sizeOf(context).height * .36).clamp(86.0, 156.0),
          child: Center(
            child: FittedBox(fit: BoxFit.scaleDown, child: art),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: kufi,
            fontSize: 21,
            fontWeight: FontWeight.w800,
            color: Color(0xFF2A160A),
            height: 1.3,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: 150,
          child: ShopButton.label(
            button,
            onPressed: onClose ?? () => Navigator.of(context).maybePop(),
            height: 42,
            fontSize: 20,
            radius: 13,
          ),
        ),
      ],
    ),
  );
}

/// يطلع نافذة الغرض الجديد (بعد ما تلبس شي).
Future<void> showShopReveal(
  BuildContext context, {
  required String title,
  required Widget art,
  required String message,
  String button = 'حلو!',
}) => showGeneralDialog<void>(
  context: context,
  barrierDismissible: true,
  barrierLabel: title,
  barrierColor: Colors.black.withValues(alpha: .7),
  transitionDuration: const Duration(milliseconds: 280),
  transitionBuilder: (context, a, _, child) => ScaleTransition(
    scale: CurvedAnimation(parent: a, curve: Curves.easeOutBack),
    child: FadeTransition(opacity: a, child: child),
  ),
  pageBuilder: (context, _, _) => Center(
    child: Material(
      color: Colors.transparent,
      child: ShopRevealCard(title: title, art: art, message: message, button: button),
    ),
  ),
);

/// عنوان نافذة الغرض الجديد حسب نوعه.
String shopRevealTitle(ShopSlot slot) => switch (slot) {
  ShopSlot.frame => 'إطارك الجديد',
  ShopSlot.avatar => 'شخصيتك الجديدة',
  ShopSlot.table => 'طاولتك الجديدة',
  ShopSlot.cards => 'كروتك الجديدة',
  ShopSlot.bubble => 'فقاعتك الجديدة',
  ShopSlot.death => 'تأثير طردك الجديد',
  ShopSlot.reactions => 'ملصقاتك الجديدة',
};

/// اسم الغرض بجملة: «إطار الجليد»، «طاولة رمال»، «شخصية المحقق».
String shopItemPhrase(ShopItem item) {
  final n = item.name;
  return switch (item.slot) {
    ShopSlot.frame => n.contains(' ') || n.startsWith('ال') ? 'إطار $n' : 'إطار ال$n',
    ShopSlot.avatar => 'شخصية $n',
    ShopSlot.table => 'طاولة $n',
    ShopSlot.cards => 'كروت $n',
    ShopSlot.bubble => 'فقاعة $n',
    ShopSlot.death => 'تأثير $n',
    ShopSlot.reactions => n,
  };
}

/// الغرض كبير داخل نافذة الغرض الجديد.
Widget shopRevealArt(ShopItem item, Profile p) => switch (item.slot) {
  ShopSlot.frame => PlayerAvatar(avatar: p.avatar, style: item.frame, size: 104),
  ShopSlot.avatar => PlayerAvatar(avatar: item.avatar!, style: frameStyle(p.frame), size: 104),
  _ => ItemPreview(item: item, profile: p, scale: 1.45),
};

// ───────────────────────── التنبيه ─────────────────────────

/// لوح خشب بحد ذهبي: رسالة المتجر السريعة («صار عندك إطار الجليد!»).
class ShopToastPlank extends StatelessWidget {
  const ShopToastPlank(this.message, {super.key, this.icon});

  final String message;
  final Widget? icon;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(14),
      color: const Color(0xFF2A190D),
      border: Border.all(color: const Color(0xFFE8B54E), width: 2.4),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .5), blurRadius: 10, offset: const Offset(0, 4))],
      image: const DecorationImage(image: AssetImage(DesignAssets.plank), fit: BoxFit.fill),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: OutlinedText(message, size: 18, maxLines: 2, stroke: const Color(0xFF140A05), strokeWidth: 3),
          ),
          if (icon != null) ...[const SizedBox(width: 12), icon!],
        ],
      ),
    ),
  );
}

/// يطلع رسالة المتجر السريعة تحت الشاشة.
void showShopToast(BuildContext context, String message, {Widget? icon}) {
  final m = ScaffoldMessenger.maybeOf(context);
  if (m == null) return;
  final w = math.min(MediaQuery.sizeOf(context).width - 40, 430.0);
  m
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        padding: EdgeInsets.zero,
        width: w,
        clipBehavior: Clip.none,
        shape: const RoundedRectangleBorder(),
        duration: const Duration(milliseconds: 2400),
        content: Align(
          alignment: Alignment.bottomCenter,
          child: ShopToastPlank(message, icon: icon),
        ),
      ),
    );
}

// ───────────────────────── حالة الغرض ─────────────────────────

ShopItemState shopStateOf(ShopItem item, Profile p) {
  final owned = p.owns(item.id);
  final equipped = switch (item.slot) {
    ShopSlot.frame => p.frame == item.id,
    ShopSlot.cards => p.cards == item.id,
    ShopSlot.table => p.table == item.id,
    ShopSlot.bubble => p.bubble == item.id,
    ShopSlot.death => p.death == item.id,
    ShopSlot.avatar => p.avatar == item.avatar,
    ShopSlot.reactions => false,
  };
  if (equipped) return ShopItemState.equipped;
  if (owned) return ShopItemState.owned;
  return item.buyable ? ShopItemState.buy : ShopItemState.locked;
}

/// الإطارات اللي تبان أحسن على خلفية مخمل غامقة (ليل، نجوم، نيون…).
const _darkFrames = {'comet', 'galaxy', 'blackgold', 'neon', 'storm', 'fireworks'};

bool shopDarkCard(ShopItem item) => item.slot == ShopSlot.frame && _darkFrames.contains(item.frame?.sig);

/// أيقونة مصدر الغرض لو ما ينشرى (مستوى، موسم، بطولة).
String shopSourceIcon(ShopItem item) => item.level != null ? 'xp' : (item.season != null ? 'pass' : 'trophy');

/// الرسمة بالكرت: حجمها يناسب نوع الغرض.
Widget shopCardArt(ShopItem item, Profile p) => ItemPreview(
  item: item,
  profile: p,
  scale: switch (item.slot) {
    ShopSlot.frame => .92,
    ShopSlot.avatar => .8,
    _ => .9,
  },
);

/// نجمة ذهب بحد بني (علامة المفضلة).
class ShopStar extends StatelessWidget {
  const ShopStar({super.key, this.size = 20});

  final double size;

  @override
  Widget build(BuildContext context) => CustomPaint(size: Size.square(size), painter: const _StarPainter());
}

class _StarPainter extends CustomPainter {
  const _StarPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 * .92;
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final a = -math.pi / 2 + i * math.pi / 5;
      final d = i.isEven ? r : r * .45;
      final p = c + Offset(math.cos(a), math.sin(a)) * d;
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();
    canvas.drawPath(
      path,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFF0B8), Color(0xFFF2B53A), Color(0xFFD98A1C)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * .1
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0xFF3A1A08),
    );
  }

  @override
  bool shouldRepaint(_StarPainter old) => false;
}
