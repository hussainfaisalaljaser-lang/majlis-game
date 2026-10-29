import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/profile.dart';
import '../services/backend.dart';
import '../services/sounds.dart';
import '../theme.dart';
import 'common.dart';
import 'fx.dart';

/// مكافأة آخر لعبة (ذهب وخبرة) لين تطير لرصيدك في الرئيسية.
/// من لحظة النتيجة نخلي الرقم بالرئيسية على قيمته القديمة، ولما ترجع الرئيسية العملات تطير من صورتك للرصيد
/// وكل عملة توصل تزيد الرقم، وبعدها يتعبى شريط الخبرة (ولو ترقيت يلمع المستوى).
abstract final class RewardFx {
  /// الذهب والخبرة اللي لسا ما وصلت للرقم اللي يبان.
  static final heldCoins = ValueNotifier<int>(0);
  static final heldXp = ValueNotifier<int>(0);

  static int _entryCoins = 0, _entryXp = 0;
  static final _granted = <String>{};

  static bool get pending => heldCoins.value > 0 || heldXp.value > 0;

  /// أول ما تبدأ اللعبة: نتذكر ذهبك وخبرتك قبلها (الرقم القديم اللي يبان لين تطير المكافأة).
  static void begin(Profile p) {
    if (pending) return;
    _entryCoins = p.coins;
    _entryXp = p.xp;
  }

  /// النتيجة طلعت: [coins] و[xp] اللي كسبتهم. مرة وحدة لكل طاولة.
  static void grant(String code, {required int coins, required int xp}) {
    if (!_granted.add(code) || (coins <= 0 && xp <= 0)) return;
    heldCoins.value += math.max(0, coins);
    heldXp.value += math.max(0, xp);
  }

  static void release() {
    heldCoins.value = 0;
    heldXp.value = 0;
  }

  /// الذهب اللي يبان في الرئيسية. لو السيرفر ما حسب المكافأة بعد، يبان الرقم القديم، وما ينزل تحته.
  static int coinsShown(Profile p) {
    final held = heldCoins.value;
    return held <= 0 ? p.coins : math.max(p.coins - held, math.min(p.coins, _entryCoins));
  }

  /// المستوى وتعبئة شريطه اللي يبانون في الرئيسية.
  static ({int level, double progress}) xpShown(Profile p) {
    final held = heldXp.value;
    if (held <= 0) return (level: p.level, progress: p.levelProgress);
    return levelAt(math.max(p.xp - held, math.min(p.xp, _entryXp)));
  }

  /// المستوى وتعبئته من الخبرة الكلية (نفس معادلة Profile.xpForLevel).
  static ({int level, double progress}) levelAt(int xp) {
    var level = 1;
    while (Profile.xpForLevel(level + 1) <= xp) {
      level++;
    }
    final into = xp - Profile.xpForLevel(level);
    return (level: level, progress: (into / (100 + 50 * (level - 1))).clamp(0.0, 1.0));
  }
}

const _gold = Color(0xFFF6C84C);
const _cream = Color(0xFFFFF0D2);

double _c01(double x) => x.clamp(0.0, 1.0);
double _ease(double x) {
  final t = _c01(x);
  return t * t * (3 - 2 * t);
}

double _outBack(double x) {
  final t = _c01(x) - 1;
  return 1 + 2.2 * t * t * t + 1.2 * t * t;
}

Offset _quad(Offset a, Offset b, Offset c, double t) {
  final u = 1 - t;
  return a * (u * u) + b * (2 * u * t) + c * (t * t);
}

double _h(int i, int salt) => rnd(i, salt);

/// طبقة فوق الرئيسية: تشغّل الحركة لما ترجع للرئيسية وفيه مكافأة معلّقة في [RewardFx].
/// المفاتيح تدل على مكان رصيد الذهب (وجهة العملات)، وصورتك (منها تطلع)، ولوح اسمك ومستواك.
class RewardFlyLayer extends StatefulWidget {
  const RewardFlyLayer({super.key, required this.pillKey, required this.originKey, required this.plankKey});

  final GlobalKey pillKey, originKey, plankKey;

  @override
  State<RewardFlyLayer> createState() => _RewardFlyLayerState();
}

class _RewardFlyLayerState extends State<RewardFlyLayer> with SingleTickerProviderStateMixin {
  static const _tCoins = 1.0, _step = .07, _flight = 1.3, _xpFill = 1.5;

  late final _c = AnimationController(vsync: this)
    ..addListener(_onTick)
    ..addStatusListener(_onStatus);

  Animation<double>? _secondary;
  Timer? _poll;
  bool _running = false;

  // الخطة (تنحسب لما تبدأ الحركة)
  int _coins = 0, _xp = 0, _n = 0;
  List<int> _worth = const [];
  double _total = 0, _tXp = 0;
  double? _tLevel;
  int _levelFrom = 1, _levelTo = 1;
  int _xpFrom = 0, _xpTo = 0;
  Offset _origin = Offset.zero, _pill = Offset.zero;
  Rect _pillRect = Rect.zero, _plankRect = Rect.zero;
  double _u = 1;
  int _arrived = 0;
  bool _levelSounded = false;

  double _arrive(int i) => _tCoins + i * _step + _flight;

  @override
  void initState() {
    super.initState();
    RewardFx.heldCoins.addListener(_maybeStart);
    RewardFx.heldXp.addListener(_maybeStart);
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeStart());
    // نافذة كانت فوق الرئيسية وانقفلت ما تعطينا إشارة، فنتأكد كل شوي لو فيه مكافأة تنتظر
    _poll = Timer.periodic(const Duration(milliseconds: 700), (_) => _maybeStart());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = ModalRoute.of(context)?.secondaryAnimation;
    if (next != _secondary) {
      _secondary?.removeStatusListener(_onSecondary);
      _secondary = next?..addStatusListener(_onSecondary);
    }
  }

  @override
  void dispose() {
    _poll?.cancel();
    RewardFx.heldCoins.removeListener(_maybeStart);
    RewardFx.heldXp.removeListener(_maybeStart);
    _secondary?.removeStatusListener(_onSecondary);
    _c.dispose();
    // ما نخلي الرقم معلّق لو انقفلت الرئيسية
    if (_running) RewardFx.release();
    super.dispose();
  }

  void _onSecondary(AnimationStatus s) {
    if (s == AnimationStatus.dismissed) WidgetsBinding.instance.addPostFrameCallback((_) => _maybeStart());
  }

  void _onStatus(AnimationStatus s) {
    if (s != AnimationStatus.completed) return;
    RewardFx.release();
    setState(() => _running = false);
  }

  /// الرئيسية قدامك بالكامل (ما فوقها شاشة ولا نافذة)؟
  bool get _visible {
    final route = ModalRoute.of(context);
    return route != null && route.isCurrent && (_secondary == null || _secondary!.status == AnimationStatus.dismissed);
  }

  void _maybeStart() {
    if (_running || !mounted || !RewardFx.pending || !_visible) return;
    if (FxClock.lite.value) return RewardFx.release();
    final mine = context.findRenderObject();
    Rect? rectOf(GlobalKey k) {
      final o = k.currentContext?.findRenderObject();
      if (o is! RenderBox || !o.attached || !o.hasSize || mine is! RenderBox || !mine.attached) return null;
      return mine.globalToLocal(o.localToGlobal(Offset.zero)) & o.size;
    }

    final pill = rectOf(widget.pillKey), origin = rectOf(widget.originKey), plank = rectOf(widget.plankKey);
    if (pill == null || origin == null || plank == null || mine is! RenderBox) return RewardFx.release();
    _pillRect = pill;
    _plankRect = plank;
    _pill = pill.center;
    _origin = origin.center;
    _u = (mine.size.height / 540).clamp(.6, 1.25);

    _coins = RewardFx.heldCoins.value;
    _xp = RewardFx.heldXp.value;
    _n = _coins > 0 ? (_coins ~/ 40).clamp(5, 12) : 0;
    _worth = [for (var i = 0; i < _n; i++) i == _n - 1 ? _coins - (_coins ~/ _n) * (_n - 1) : _coins ~/ _n];

    final p = Backend.instance.profile.value;
    final from = RewardFx.xpShown(p);
    _levelFrom = from.level;
    _xpTo = p.xp;
    _xpFrom = math.max(0, p.xp - _xp);
    _levelTo = RewardFx.levelAt(_xpTo).level;
    _tXp = _n > 0 ? _arrive(_n - 1) - .3 : .9;
    final xpEnd = _xp > 0 ? _tXp + _xpFill : _tXp;
    _tLevel = null;
    if (_levelTo > _levelFrom) {
      for (var t = _tXp; t < _tXp + _xpFill; t += .01) {
        if (RewardFx.levelAt(_xpAtTime(t)).level > _levelFrom) {
          _tLevel = t;
          break;
        }
      }
      _tLevel ??= _tXp + _xpFill;
    }
    final coinsEnd = _n > 0 ? _arrive(_n - 1) : 0.0;
    _total = math.max(coinsEnd, xpEnd) + (_tLevel != null ? 2.0 : .6);
    _arrived = 0;
    _levelSounded = false;
    _running = true;
    _c.duration = Duration(milliseconds: (_total * 1000).round());
    _c.forward(from: 0);
    Sounds.play('sparkle', volume: .6);
    setState(() {});
  }

  int _xpAtTime(double t) => _xpFrom + ((_xpTo - _xpFrom) * _ease((t - _tXp) / _xpFill)).round();

  void _onTick() {
    if (!_running) return;
    final t = _c.value * _total;
    var arrived = 0;
    var sum = 0;
    for (var i = 0; i < _n; i++) {
      if (_arrive(i) <= t) {
        arrived++;
        sum += _worth[i];
      }
    }
    for (var i = _arrived; i < arrived; i++) {
      Sounds.play('coin', volume: .7);
    }
    _arrived = arrived;
    RewardFx.heldCoins.value = math.max(0, _coins - sum);
    RewardFx.heldXp.value = _xp > 0 ? math.max(0, _xpTo - _xpAtTime(t)) : 0;
    if (_tLevel != null && !_levelSounded && t >= _tLevel!) {
      _levelSounded = true;
      Sounds.play('level', volume: 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_running) return const SizedBox.shrink();
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = _c.value * _total;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(child: CustomPaint(painter: _RewardPainter(this, t))),
              ..._widgets(t),
            ],
          );
        },
      ),
    );
  }

  Widget _chip(String icon, String text, Color border, double scale, double opacity, Offset c) {
    final w = 190 * _u, h = 46 * _u;
    return Positioned(
      left: c.dx - w / 2,
      top: c.dy - h / 2,
      width: w,
      height: h,
      child: Opacity(
        opacity: _c01(opacity),
        child: Transform.scale(
          scale: scale,
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF2A1810),
              borderRadius: BorderRadius.circular(24 * _u),
              border: Border.all(color: border, width: 3 * _u),
              boxShadow: [BoxShadow(color: border.withValues(alpha: .5), blurRadius: 14)],
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Gfx(icon, size: 28 * _u),
                  SizedBox(width: 8 * _u),
                  Text(
                    text,
                    style: TextStyle(
                      fontFamily: kufi,
                      fontWeight: FontWeight.w800,
                      fontSize: 25 * _u,
                      color: _cream,
                      height: 1.15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _widgets(double t) {
    final out = <Widget>[];
    final coinsStart = _tCoins;
    // فقاعتا «+٦٠٠» و«+١٢٠»
    final fadeAt = _n > 0 ? coinsStart + .15 : _tXp - .3;
    if (t < fadeAt + .6) {
      final fade = 1 - _c01((t - fadeAt) / .4);
      final rise = _ease((t - fadeAt) / .5) * 18 * _u;
      var row = 0;
      if (_coins > 0) {
        out.add(
          _chip(
            'coin',
            '+${arabicNumber(_coins)}',
            _gold,
            _outBack(t / .5),
            fade,
            _origin + Offset(0, -30 * _u - rise),
          ),
        );
        row++;
      }
      if (_xp > 0) {
        out.add(
          _chip(
            'xp',
            '+${arabicNumber(_xp)} خبرة',
            const Color(0xFF6BD6FF),
            _outBack((t - .25) / .5),
            fade,
            _origin + Offset(0, (row == 0 ? -30 : 24) * _u - rise),
          ),
        );
      }
    }
    // العملات
    final d = 34 * _u;
    for (var i = 0; i < _n; i++) {
      final s0 = _tCoins + i * _step;
      final u = t - s0;
      if (u < 0 || u >= _flight) continue;
      final ang = i / _n * math.pi * 2 + _h(i, 1) * .5;
      final rad = (55 + 75 * _h(i, 2)) * _u;
      final scatter = _origin + Offset(math.cos(ang) * rad, math.sin(ang) * rad * .8 - 20 * _u);
      Offset pos;
      var sc = 1.0;
      if (u < .38) {
        final e = 1 - math.pow(1 - u / .38, 3);
        pos = Offset.lerp(_origin, scatter, e.toDouble())!;
        sc = _ease(u / .18);
      } else if (u < .5) {
        pos = scatter + Offset(0, math.sin((u - .38) / .12 * math.pi) * -5);
      } else {
        final p = (u - .5) / .8;
        final e = math.pow(p, 1.7).toDouble();
        final ctrl = Offset((scatter.dx + _pill.dx) / 2, math.min(scatter.dy, _pill.dy) - (70 + 60 * _h(i, 3)) * _u);
        pos = _quad(scatter, ctrl, _pill, e);
        sc = 1 - .38 * e;
        for (var k = 1; k <= 3; k++) {
          final tp = _quad(scatter, ctrl, _pill, math.pow(math.max(0, p - k * .045), 1.7).toDouble());
          out.add(
            Positioned(
              left: tp.dx - 4 * _u,
              top: tp.dy - 4 * _u,
              child: Container(
                width: 8 * _u,
                height: 8 * _u,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _gold.withValues(alpha: .45 / k),
                ),
              ),
            ),
          );
        }
      }
      out.add(
        Positioned(
          left: pos.dx - d * sc / 2,
          top: pos.dy - d * sc / 2,
          child: Transform.rotate(
            angle: u * (4 + 3 * _h(i, 4)),
            child: Gfx('coin', size: d * sc),
          ),
        ),
      );
    }
    // «ترقيت!»
    if (_tLevel != null) {
      final lu = t - _tLevel!;
      if (lu >= 0 && lu < 2.0) {
        out.add(
          _chip(
            'xp',
            'مستوى ${arabicNumber(_levelTo)}!',
            _gold,
            _outBack(lu / .45),
            1 - _c01((lu - 1.5) / .5),
            Offset(_plankRect.center.dx, _plankRect.bottom + 34 * _u + 5 * math.sin(lu * 6)),
          ),
        );
      }
    }
    return out;
  }
}

void _star(Canvas c, Offset o, double r, Color color) {
  if (r <= .2) return;
  final path = Path()
    ..moveTo(o.dx, o.dy - r)
    ..quadraticBezierTo(o.dx, o.dy, o.dx + r, o.dy)
    ..quadraticBezierTo(o.dx, o.dy, o.dx, o.dy + r)
    ..quadraticBezierTo(o.dx, o.dy, o.dx - r, o.dy)
    ..quadraticBezierTo(o.dx, o.dy, o.dx, o.dy - r);
  c.drawPath(path, Paint()..color = color);
}

/// حلقات الوصول عند الرصيد، وإطار يلمع حول لوح المستوى وهو يتعبى، وانفجار الترقية.
class _RewardPainter extends CustomPainter {
  _RewardPainter(this.s, this.t);

  final _RewardFlyLayerState s;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final u = s._u;
    var pulse = 0.0;
    for (var i = 0; i < s._n; i++) {
      final dt = t - s._arrive(i);
      if (dt < 0 || dt > .4) continue;
      final k = dt / .4;
      pulse = math.max(pulse, 1 - k);
      canvas.drawCircle(
        s._pill,
        (10 + 34 * k) * u,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5 * u
          ..color = _gold.withValues(alpha: (1 - k) * .8),
      );
      for (var j = 0; j < 6; j++) {
        final ang = j / 6 * math.pi * 2 + i;
        _star(
          canvas,
          s._pill + Offset(math.cos(ang), math.sin(ang)) * (12 + 26 * k) * u,
          4 * u * (1 - k),
          Colors.white,
        );
      }
    }
    if (pulse > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(s._pillRect.inflate((3 + 4 * pulse) * u), Radius.circular(20 * u)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3 * u
          ..color = _gold.withValues(alpha: .8 * pulse)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }
    // لوح المستوى يلمع وهو يتعبى
    if (s._xp > 0) {
      final k = _c01((t - s._tXp + .2) / .4) * (1 - _c01((t - s._tXp - _RewardFlyLayerState._xpFill - .2) / .5));
      if (k > 0) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(s._plankRect.inflate(2 * u), Radius.circular(12 * u)),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5 * u
            ..color = const Color(0xFF8CE6FF).withValues(alpha: (.35 + .4 * (.5 + .5 * math.sin(t * 10))) * k)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
        );
      }
    }
    // ترقية المستوى
    final tl = s._tLevel;
    if (tl != null && t >= tl && t < tl + 1.4) {
      final k = (t - tl) / 1.4;
      final at = s._plankRect.center;
      canvas.drawCircle(
        at,
        (10 + 120 * _ease(k * 1.2)) * u,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5 * u * (1 - k)
          ..color = const Color(0xFFFFE9A0).withValues(alpha: (1 - k) * .9),
      );
      for (var j = 0; j < 16; j++) {
        final ang = j / 16 * math.pi * 2 + _h(j, 90);
        final dd = (20 + 110 * _h(j, 91)) * _ease(k * 1.3) * u;
        _star(
          canvas,
          at + Offset(math.cos(ang), math.sin(ang)) * dd,
          (7 * (1 - k) + 1) * u,
          Colors.white.withValues(alpha: 1 - k),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_RewardPainter old) => old.t != t;
}
