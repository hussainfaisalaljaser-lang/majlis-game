import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:majlis/theme.dart';
import 'package:majlis/widgets/design.dart';
import 'package:majlis/widgets/mode_theme.dart';

/// العنوان المحدد بالتدرج مثل ما كان (ShaderMask)، للمقارنة.
class _OldOutlined extends StatelessWidget {
  const _OldOutlined(this.text, {required this.size, this.align = TextAlign.center, this.maxLines});

  final String text;
  final double size;
  final TextAlign align;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final sw = (size * .16).clamp(2.0, 9.0);
    final base = TextStyle(fontFamily: kufi, fontWeight: FontWeight.w800, fontSize: size, height: 1.25);
    final overflow = maxLines == null ? null : TextOverflow.ellipsis;
    return Stack(
      alignment: Alignment.center,
      children: [
        Text(
          text,
          textAlign: align,
          maxLines: maxLines,
          overflow: overflow,
          style: base.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = sw
              ..strokeJoin = StrokeJoin.round
              ..color = const Color(0xFF3A1606),
            shadows: [Shadow(color: Colors.black.withValues(alpha: .5), offset: Offset(0, size * .08), blurRadius: 3)],
          ),
        ),
        ShaderMask(
          shaderCallback: (r) => const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: goldTitleColors,
          ).createShader(r),
          child: Text(
            text,
            textAlign: align,
            maxLines: maxLines,
            overflow: overflow,
            style: base.copyWith(color: Colors.white),
          ),
        ),
      ],
    );
  }
}

/// اسم الطور مثل ما كان (ShaderMask)، للمقارنة.
class _OldModeName extends StatelessWidget {
  const _OldModeName(this.mode, {this.size = 28});

  final ModeTheme mode;
  final double size;

  @override
  Widget build(BuildContext context) => ShaderMask(
    blendMode: BlendMode.srcIn,
    shaderCallback: (r) =>
        LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: mode.title).createShader(r),
    child: Text(
      mode.name,
      style: TextStyle(fontFamily: kufi, fontSize: size, fontWeight: FontWeight.w700, height: 1.25),
    ),
  );
}

/// كل الأماكن اللي فيها كلام بالتدرج: عناوين بأحجام ومحاذاة، سطرين، كلام مقصوص، داخل تصغير، واسم الطور.
Widget _scene({required bool old, double scale = 1}) {
  Widget gold(String text, double size, {TextAlign align = TextAlign.center, int? maxLines}) => old
      ? _OldOutlined(text, size: size, align: align, maxLines: maxLines)
      : maxLines == null
      ? GoldTitle(text, size: size, align: align)
      : OutlinedText(
          text,
          size: size,
          gradient: goldTitleColors,
          stroke: const Color(0xFF3A1606),
          align: align,
          maxLines: maxLines,
        );
  Widget mode(ModeTheme m, double size) => old ? _OldModeName(m, size: size) : ModeName(mode: m, size: size);
  const m = ModeTheme.advanced;
  return _frame(
    scale: scale,
    child: Wrap(
      spacing: 14,
      runSpacing: 10,
      children: [
        gold('المتجر', 27),
        gold('الديوان', 27),
        gold('الموسم', 27),
        SizedBox(width: 260, child: gold('خاص', 38, align: TextAlign.start)),
        gold('١٢٣٤٥', 30),
        SizedBox(width: 130, child: gold('مهمات الموسم كلها', 20)),
        SizedBox(width: 110, child: gold('عنوان طويل ينقص', 22, maxLines: 1)),
        SizedBox(width: 90, height: 30, child: FittedBox(child: gold('الهدية اليومية', 24))),
        gold('المتجر', 13.3),
        Container(
          padding: const EdgeInsetsDirectional.fromSTEB(6, 3, 10, 3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(colors: [m.top, m.bottom]),
          ),
          child: mode(m, 14),
        ),
        mode(m, 28),
      ],
    ),
  );
}

/// خلفية رق، ومثل الشاشات: يمين لشمال وخط الثيم.
Widget _frame({required Widget child, double scale = 1}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: buildTheme(),
  home: MediaQuery(
    data: MediaQueryData(size: const Size(800, 900), textScaler: TextScaler.linear(scale)),
    child: Directionality(
      textDirection: TextDirection.rtl,
      child: RepaintBoundary(
        child: Material(
          // نفس خط الشاشات (Scaffold) بدال خط الغلط الافتراضي.
          type: MaterialType.transparency,
          child: ColoredBox(color: const Color(0xFFD9BF8C), child: child),
        ),
      ),
    ),
  ),
);

Future<Uint8List> _pixels(WidgetTester tester) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byType(RepaintBoundary).first);
  final data = await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: tester.view.devicePixelRatio);
    final bytes = await image.toByteData();
    image.dispose();
    return bytes!;
  });
  return data!.buffer.asUint8List();
}

/// البكسلات اللي تختلف بوضوح (أكثر من ٢٤ من ٢٥٥) وكل اللي حولها يختلف بعد: يعني شكل مختلف، مو نعومة حافة
/// (طريقة رسم الحواف تختلف شوي بين الطريقتين، بخط رفيع بكسل واحد).
int _blobs(Uint8List a, Uint8List b, int width, {Rect? within}) {
  final height = a.length ~/ (4 * width);
  bool off(int x, int y) {
    final i = (y * width + x) * 4;
    for (var c = 0; c < 3; c++) {
      if ((a[i + c] - b[i + c]).abs() > 24) return true;
    }
    return false;
  }

  var count = 0;
  for (var y = 1; y < height - 1; y++) {
    for (var x = 1; x < width - 1; x++) {
      if (within != null && !within.contains(Offset(x + .5, y + .5))) continue;
      var all = true;
      for (var dy = -1; dy <= 1 && all; dy++) {
        for (var dx = -1; dx <= 1 && all; dx++) {
          all = off(x + dx, y + dy);
        }
      }
      if (all) count++;
    }
  }
  return count;
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final font = FontLoader(kufi)
      ..addFont(rootBundle.load('assets/fonts/ElMessiri-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/ElMessiri-Bold.ttf'));
    await font.load();
  });

  for (final scale in [1.0, 1.3]) {
    testWidgets('الكلام بالتدرج بدون طبقة جانبية نفس شكله مع ShaderMask (تكبير الخط $scale)', (tester) async {
      tester.view.devicePixelRatio = 2.75;
      tester.view.physicalSize = const Size(2200, 2475);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_scene(old: true, scale: scale));
      final before = await _pixels(tester);
      await tester.pumpWidget(_scene(old: false, scale: scale));
      final after = await _pixels(tester);

      expect(after.length, before.length);
      var sum = 0, ink = 0;
      for (var j = 0; j < before.length; j++) {
        sum += (before[j] - after[j]).abs();
      }
      // كم بكسل فيه كلام (يختلف عن لون الخلفية)، عشان نتأكد إن الكلام انرسم.
      for (var j = 0; j < before.length; j += 4) {
        if ((before[j] - 0xD9).abs() + (before[j + 1] - 0xBF).abs() + (before[j + 2] - 0x8C).abs() > 30) ink++;
      }
      final mean = sum / before.length;
      final blobs = _blobs(before, after, 2200);
      // ignore: avoid_print
      print('تكبير $scale: متوسط الفرق ${mean.toStringAsFixed(4)}، أشكال مختلفة $blobs بكسل، بكسلات الكلام $ink');
      expect(ink, greaterThan(20000), reason: 'المشهد ما انرسم فيه كلام');
      expect(mean, lessThan(.1), reason: 'متوسط الفرق $mean');
      expect(blobs, 0, reason: 'فيه أشكال مختلفة ($blobs بكسل)');
    });
  }

  testWidgets('اسم الطور: النقط اللي تطلع تحت مربع الكلام ذهبية مثل الباقي (ShaderMask كان يخليها بلون الخط)', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 2.75;
    tester.view.physicalSize = const Size(1100, 550);
    addTearDown(tester.view.reset);
    const m = ModeTheme.classic;
    final key = GlobalKey();
    Widget scene(bool old) => _frame(
      child: Center(
        child: KeyedSubtree(
          key: key,
          child: old ? const _OldModeName(m) : const ModeName(mode: m),
        ),
      ),
    );

    // الأصل (لون الخط) والذهبي اللي تحت التدرج، وكم بكسل قريب منهم تحت مربع الكلام.
    (int, int) below(Uint8List px, Rect box) {
      var cream = 0, gold = 0;
      for (var y = (box.bottom * 2.75).ceil(); y < ((box.bottom + 14) * 2.75).floor(); y++) {
        for (var x = (box.left * 2.75).floor(); x < (box.right * 2.75).ceil(); x++) {
          final i = (y * 1100 + x) * 4;
          int d(Color c) =>
              (px[i] - (c.r * 255).round()).abs() +
              (px[i + 1] - (c.g * 255).round()).abs() +
              (px[i + 2] - (c.b * 255).round()).abs();
          if (d(AppColors.text) < 40) cream++;
          if (d(m.title.last) < 40) gold++;
        }
      }
      return (cream, gold);
    }

    await tester.pumpWidget(scene(true));
    final box = tester.getRect(find.byKey(key));
    final before = await _pixels(tester);
    await tester.pumpWidget(scene(false));
    final after = await _pixels(tester);
    final (oldCream, _) = below(before, box);
    final (newCream, newGold) = below(after, box);
    // القديم فعلاً كان فيه نقط بلون الخط (يعني الاختبار يشوف المشكلة)، والجديد ما فيه، ونقطه ذهبية.
    expect(oldCream, greaterThan(20), reason: 'القديم ما طلع فيه شي تحت الكلام');
    expect(newCream, 0);
    expect(newGold, greaterThan(20));
    // وداخل مربع الكلام نفس الشكل.
    final inside = Rect.fromLTRB(box.left * 2.75, box.top * 2.75, box.right * 2.75, box.bottom * 2.75);
    expect(_blobs(before, after, 1100, within: inside), 0);
  });
}
