// أمثلة لشكل سجادات الطاولات بالمتجر (للاختيار): ٣ تصاميم، كلها تنرسم بنفس رسّامي السجادة والبيضاوي اللي باللعبة.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:majlis/models/shop.dart';
import 'package:majlis/widgets/common.dart';
import 'package:majlis/widgets/design.dart';
import 'package:majlis/widgets/design_game.dart';
import 'package:majlis/widgets/design_shop.dart';
import 'package:majlis/widgets/game/table_art.dart';

import 'shot_helper.dart';

const _cream = Color(0xFFFFF3DA);
const _gold = Color(0xFFF2C75A);

/// يرسم جزء من الطاولة بإحداثيات التصميم (١٩٢٠×١٠٨٠) داخل المساحة، بنفس رسّامي اللعبة.
class _TablePainter extends CustomPainter {
  const _TablePainter(this.palette, this.crop);

  final CarpetPalette palette;
  final Rect crop;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / crop.width;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.scale(k);
    canvas.translate(-crop.left, -crop.top);
    const full = Size(1920, 1080);
    CarpetPainter(palette).paint(canvas, full);
    OvalPainter(palette).paint(canvas, full);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_TablePainter old) => old.palette != palette || old.crop != crop;
}

const _artW = 200.0, _artH = 92.0;

/// ١) نفس اللعبة: السجادة بمنظورها وزخرفتها وحبالها، والبيضاوي الذهبي، بدون شي ثاني.
Widget _exact(CarpetPalette p) => SizedBox(
  width: _artW,
  height: _artH,
  child: CustomPaint(painter: _TablePainter(p, const Rect.fromLTRB(290, 250, 1650, 900))),
);

/// ٢) مشهد مصغّر: الطاولة بمكانها (ليل الخيمة وأرضها)، ولاعبين على جنبها، وكومتا الأوراق.
Widget _scene(CarpetPalette p) => ClipRRect(
  borderRadius: BorderRadius.circular(10),
  child: SizedBox(
    width: _artW,
    height: _artH,
    child: Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0D1030), Color(0xFF241B3A), Color(0xFF6A4A2C), Color(0xFF8A6238)],
              stops: [0, .38, .39, 1],
            ),
          ),
        ),
        const Positioned(top: 7, left: 22, child: _Dot()),
        const Positioned(top: 14, left: 120, child: _Dot()),
        const Positioned(top: 5, right: 40, child: _Dot()),
        Positioned.fill(child: CustomPaint(painter: _TablePainter(p, const Rect.fromLTRB(40, 140, 1880, 1000)))),
        Positioned(top: 3, left: 0, right: 0, child: Center(child: PlayerAvatar(avatar: 'emir', size: 22, animate: false))),
        Positioned(bottom: 1, left: 0, right: 0, child: Center(child: PlayerAvatar(avatar: 'jasmine', size: 22, animate: false))),
        const Positioned(top: 30, left: 28, child: GameCardBack(width: 14)),
        const Positioned(top: 30, right: 28, child: GameCardBack(width: 14)),
      ],
    ),
  ),
);

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) => Container(
    width: 2,
    height: 2,
    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: .8)),
  );
}

/// ٣) قريب: زاوية السجادة وزخرفتها وطرف البيضاوي، عشان تبان تفاصيل النقش.
Widget _close(CarpetPalette p) => SizedBox(
  width: _artW,
  height: _artH,
  child: CustomPaint(painter: _TablePainter(p, const Rect.fromLTRB(330, 290, 1030, 610))),
);

Widget _card(String id, Widget Function(CarpetPalette) art) {
  final item = shopItem(id)!;
  final palette = CarpetPalette.of(item.table!.carpet);
  return SizedBox(
    width: 214,
    height: 167,
    child: ShopItemCard(
      art: art(palette),
      rarity: item.rarity,
      name: item.name,
      wide: true,
      onTap: () {},
      onPreview: () {},
      action: ShopButton.label('البس', height: 33, fontSize: 16, onPressed: () {}),
    ),
  );
}

Widget _label(String n, String text) => Padding(
  padding: const EdgeInsets.only(bottom: 4, top: 6),
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 24,
        height: 24,
        alignment: Alignment.center,
        decoration: const BoxDecoration(shape: BoxShape.circle, color: _gold),
        child: Text(n, style: const TextStyle(color: Color(0xFF3A1A05), fontSize: 15, fontWeight: FontWeight.w900, height: 1)),
      ),
      const SizedBox(width: 8),
      Text(text, style: const TextStyle(color: _cream, fontSize: 14.5, fontWeight: FontWeight.w800)),
    ],
  ),
);

class _Board extends StatelessWidget {
  const _Board();

  static const _ids = ['table_majlis', 'table_oasis', 'table_night', 'table_gold'];

  Widget _row(Widget Function(CarpetPalette) art) => Row(
    children: [
      for (final id in _ids) ...[Expanded(child: FittedBox(child: _card(id, art))), const SizedBox(width: 8)],
    ],
  );

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: WoodWall(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 6, 14, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label('١', 'نفس اللعبة بالضبط (السجادة والبيضاوي بنفس رسم الطاولة)'),
            _row(_exact),
            _label('٢', 'مشهد مصغّر (الطاولة بمكانها ومعها لاعبين وكومتا الأوراق)'),
            _row(_scene),
            _label('٣', 'قريب (زاوية السجادة ونقشها وطرف البيضاوي)'),
            _row(_close),
          ],
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(loadFonts);

  testWidgets('table designs', (tester) async {
    await shot(tester, 'table_designs', const _Board(), size: const Size(960, 700));
  });
}
