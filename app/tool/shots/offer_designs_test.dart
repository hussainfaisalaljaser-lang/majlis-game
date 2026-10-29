// أمثلة تصاميم بديلة لكروت العروض (للاختيار قبل التنفيذ). نفس العرض (الأمير + إطار الشمس) بأربع تصاميم.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:majlis/models/shop.dart';
import 'package:majlis/theme.dart';
import 'package:majlis/widgets/common.dart';
import 'package:majlis/widgets/design.dart';
import 'package:majlis/widgets/design_shop.dart';

import 'shot_helper.dart';

const _cream = Color(0xFFFFF3DA);
const _gold = Color(0xFFF2C75A);

Widget _avatar(double size, {bool frame = true}) => PlayerAvatar(
  avatar: 'emir',
  style: frame ? shopItem('frame_sun')!.frame : null,
  size: size,
  animate: false,
);

Widget _chip(String label, String name, {String? icon}) => Container(
  padding: const EdgeInsets.fromLTRB(10, 4, 12, 5),
  decoration: BoxDecoration(
    color: Colors.black.withValues(alpha: .35),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: _gold.withValues(alpha: .6)),
  ),
  child: FittedBox(
    fit: BoxFit.scaleDown,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[Gfx(icon, size: 20), const SizedBox(width: 6)],
        Text(
          label,
          style: const TextStyle(
            color: _gold,
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          name,
          style: const TextStyle(
            fontFamily: kufi,
            color: _cream,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  ),
);

Widget _buy({double h = 40, String label = 'اشترِ العرض'}) => ShopButton(
  height: h,
  onPressed: () {},
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      OutlinedText(
        label,
        size: 17,
        maxLines: 1,
        stroke: const Color(0xFF143A0B),
        strokeWidth: 3.2,
      ),
      const SizedBox(width: 10),
      OutlinedText(
        '٦٥',
        size: 19,
        maxLines: 1,
        stroke: const Color(0xFF143A0B),
        strokeWidth: 3.2,
      ),
      const SizedBox(width: 5),
      const Gfx('gem', size: 24),
    ],
  ),
);

BoxDecoration _velvet({double r = 20}) => BoxDecoration(
  borderRadius: BorderRadius.circular(r),
  gradient: const LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF4A1830), Color(0xFF220A16)],
  ),
  border: Border.all(color: const Color(0xFFE8B54E), width: 2.4),
  boxShadow: [
    BoxShadow(
      color: Colors.black.withValues(alpha: .5),
      blurRadius: 10,
      offset: const Offset(0, 5),
    ),
  ],
);

/// ١) شريط عريض: الشخصية بالطرف، وفي النص الاسم والغرضين، وعلى الطرف الثاني السعر والزر.
class _Banner extends StatelessWidget {
  const _Banner();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
    decoration: _velvet(),
    child: Row(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            const SizedBox(
              width: 120,
              height: 120,
              child: ShopSunburst(
                color: Color(0x44FFD27A),
                rays: 14,
                center: Alignment.center,
                fade: .6,
              ),
            ),
            _avatar(76),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const GoldTitle('عرض الأمير', size: 24, align: TextAlign.start),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [_chip('شخصية', 'الأمير'), _chip('إطار', 'الشمس')],
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(width: 150, child: _buy(h: 44, label: 'اشتر')),
      ],
    ),
  );
}

/// ٢) بوستر عمودي: شريط العنوان فوق، والشخصية كبيرة على أشعة، والغرضين تحتها، وزر الشراء.
class _Poster extends StatelessWidget {
  const _Poster();

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 210,
    height: 262,
    child: ShopCardFrame(
      rarity: Rarity.legendary,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
        child: Column(
          children: [
            const Align(
              alignment: Alignment.topRight,
              child: ShopRarityTag(Rarity.legendary),
            ),
            const SizedBox(height: 2),
            SizedBox(height: 96, child: Center(child: _avatar(78))),
            const Text(
              'عرض الأمير',
              style: TextStyle(
                fontFamily: kufi,
                color: AppColors.ink,
                fontSize: 21,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF241209).withValues(alpha: .86),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'الأمير',
                    style: TextStyle(
                      fontFamily: kufi,
                      color: _cream,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      '+',
                      style: TextStyle(
                        color: _gold,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    'إطار الشمس',
                    style: TextStyle(
                      fontFamily: kufi,
                      color: _cream,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _buy(h: 38, label: 'اشتر'),
          ],
        ),
      ),
    ),
  );
}

class _Arrow extends StatelessWidget {
  const _Arrow();

  @override
  Widget build(BuildContext context) => Transform.flip(flipX: true, child: const BackArrow(height: 30));
}

/// ٣) قبل وبعد: شخصيتك بدون إطار، وسهم، وبعدها بالإطار، عشان تشوف الفرق قبل ما تشتري.
class _BeforeAfter extends StatelessWidget {
  const _BeforeAfter();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
    decoration: _velvet(),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const GoldTitle('عرض الأمير', size: 22),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              children: [
                Opacity(opacity: .6, child: _avatar(66, frame: false)),
                const SizedBox(height: 4),
                const Text(
                  'الحين',
                  style: TextStyle(
                    color: Color(0xFFD9C29A),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 18),
              child: _Arrow(),
            ),
            Column(
              children: [
                _avatar(78),
                const SizedBox(height: 2),
                const Text(
                  'بعد العرض',
                  style: TextStyle(
                    color: _gold,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          alignment: WrapAlignment.center,
          children: [_chip('شخصية', 'الأمير'), _chip('إطار', 'الشمس')],
        ),
        const SizedBox(height: 8),
        SizedBox(width: 230, child: _buy(h: 40)),
      ],
    ),
  );
}

/// ٤) تذكرة بقسمين: الرسمة والكلام على اليمين، وفاصل منقط، وقسيمة السعر والشراء على اليسار.
class _Ticket extends StatelessWidget {
  const _Ticket();

  @override
  Widget build(BuildContext context) => ClipPath(
    clipper: _TicketClipper(),
    child: Container(
      height: 150,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFE9A8), Color(0xFFF1BD45)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Row(
                children: [
                  _avatar(70),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Gfx('gift', size: 24),
                            SizedBox(width: 6),
                            Text(
                              'عرض الأمير',
                              style: TextStyle(
                                fontFamily: kufi,
                                color: AppColors.ink,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'الأمير + إطار الشمس',
                          style: TextStyle(
                            color: Color(0xFF5A3A18),
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'شخصية وإطار أسطوريين بصفقة وحدة',
                          style: TextStyle(
                            color: Color(0xFF7A5A30),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            width: 2,
            child: CustomPaint(
              painter: _DashPainter(),
              size: const Size(2, double.infinity),
            ),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'السعر',
                    style: TextStyle(
                      color: Color(0xFF7A5A30),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '٦٥',
                        style: TextStyle(
                          fontFamily: kufi,
                          color: AppColors.ink,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(width: 5),
                      Gfx('gem', size: 28),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ShopButton.label(
                    'اشتر',
                    height: 36,
                    fontSize: 18,
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _TicketClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final p = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(18)),
      );
    // نتوءين دايريين عند الفاصل (فوق وتحت)
    final x = size.width * 5 / 8;
    for (final y in [0.0, size.height]) {
      p.addOval(Rect.fromCircle(center: Offset(x, y), radius: 9));
    }
    return p..fillType = PathFillType.evenOdd;
  }

  @override
  bool shouldReclip(_TicketClipper old) => false;
}

class _DashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xFF8A5E2E)
      ..strokeWidth = 2;
    for (var y = 10.0; y < size.height - 8; y += 9) {
      canvas.drawLine(Offset(1, y), Offset(1, y + 4), p);
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) => false;
}

Widget _label(String n, String text) => Padding(
  padding: const EdgeInsets.only(bottom: 6),
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 26,
        height: 26,
        alignment: Alignment.center,
        decoration: const BoxDecoration(shape: BoxShape.circle, color: _gold),
        child: Text(
          n,
          style: const TextStyle(
            color: Color(0xFF3A1A05),
            fontSize: 16,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
      ),
      const SizedBox(width: 8),
      Text(
        text,
        style: const TextStyle(
          color: _cream,
          fontSize: 15,
          fontWeight: FontWeight.w800,
        ),
      ),
    ],
  ),
);

class _Board extends StatelessWidget {
  const _Board();

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: WoodWall(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('١', 'شريط عريض'),
                  const _Banner(),
                  const SizedBox(height: 18),
                  _label('٣', 'قبل وبعد'),
                  const _BeforeAfter(),
                ],
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('٢', 'بوستر عمودي'),
                  const Center(child: _Poster()),
                  const SizedBox(height: 18),
                  _label('٤', 'تذكرة'),
                  const _Ticket(),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(loadFonts);

  testWidgets('offer designs', (tester) async {
    await shot(
      tester,
      'offer_designs',
      const _Board(),
      size: const Size(960, 600),
    );
  });
}
