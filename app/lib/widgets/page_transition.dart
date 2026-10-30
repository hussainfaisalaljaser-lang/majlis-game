import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// حركة التنقل بين الصفحات (theme.dart): نفس حركة أندرويد الافتراضية بالضبط (FadeForwardsPageTransitionsBuilder:
/// الصفحة الجديدة تدخل من اليمين وتبان، واللي قبلها تروح لليسار وتختفي، بنفس الوقت والمنحنى). الفرق إن كل صفحة
/// تنرسم مرة وحدة كصورة أول الحركة (SnapshotWidget)، والحركة تحرّك الصورة. قبل كانت الصفحتين تنرسم من جديد
/// كل فريم وهي تتلاشى (وكل وحدة كاملة ورا الشاشة عشان الشفافية)، وهذا اللي يقطّع التنقل.
/// الحركات اللي داخل الصفحة توقف خلال التنقل (أقل من نص ثانية) وترجع تمشي بعده.
class SmoothPageTransitionsBuilder extends PageTransitionsBuilder {
  const SmoothPageTransitionsBuilder();

  /// false: الحركة الأصلية (بدون صور). بس لمقارنة الاثنين في «قياس الرسم والتنقل» (أدوات المطور).
  static bool snapshots = true;

  @override
  Duration get transitionDuration =>
      const Duration(milliseconds: FadeForwardsPageTransitionsBuilder.kTransitionMilliseconds);

  @override
  Widget buildTransitions<T>(
    PageRoute<T>? route,
    BuildContext? context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => !snapshots
      ? const FadeForwardsPageTransitionsBuilder().buildTransitions(route, context, animation, secondaryAnimation, child)
      : _SmoothTransition(
    animation: animation,
    secondaryAnimation: secondaryAnimation,
    opaque: route?.opaque ?? true,
    child: child,
  );
}

class _SmoothTransition extends StatefulWidget {
  const _SmoothTransition({
    required this.animation,
    required this.secondaryAnimation,
    required this.opaque,
    required this.child,
  });

  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final bool opaque;
  final Widget child;

  @override
  State<_SmoothTransition> createState() => _SmoothTransitionState();
}

class _SmoothTransitionState extends State<_SmoothTransition> {
  final _snapshot = SnapshotController();
  late _SmoothPainter _painter = _SmoothPainter(widget.animation, widget.secondaryAnimation);

  @override
  void initState() {
    super.initState();
    _listen(widget);
  }

  @override
  void didUpdateWidget(_SmoothTransition old) {
    super.didUpdateWidget(old);
    if (old.animation != widget.animation || old.secondaryAnimation != widget.secondaryAnimation) {
      _unlisten(old);
      _painter.dispose();
      _painter = _SmoothPainter(widget.animation, widget.secondaryAnimation);
      _listen(widget);
    }
  }

  @override
  void dispose() {
    _unlisten(widget);
    _painter.dispose();
    _snapshot.dispose();
    super.dispose();
  }

  void _listen(_SmoothTransition w) {
    w.animation.addStatusListener(_status);
    w.secondaryAnimation.addStatusListener(_status);
    _status(w.animation.status);
  }

  void _unlisten(_SmoothTransition w) {
    w.animation.removeStatusListener(_status);
    w.secondaryAnimation.removeStatusListener(_status);
  }

  /// صورة بس وقت الحركة. لما توقف، الصفحة ترجع ترسم نفسها (وحركاتها تمشي).
  void _status(AnimationStatus _) =>
      _snapshot.allowSnapshotting = widget.animation.isAnimating || widget.secondaryAnimation.isAnimating;

  @override
  Widget build(BuildContext context) {
    _painter
      ..background = ColorScheme.of(context).surface
      ..opaque = widget.opaque;
    return IgnorePointer(
      // مثل FadeForwards: الصفحة اللي تتسكّر ما تنلمس.
      ignoring: widget.animation.status == AnimationStatus.reverse,
      child: SnapshotWidget(
        controller: _snapshot,
        painter: _painter,
        mode: SnapshotMode.permissive,
        autoresize: true,
        child: widget.child,
      ),
    );
  }
}

/// يرسم الصفحة (أو صورتها) بنفس حساب FadeForwards: حركة الصفحة نفسها ([animation]: تدخل أو تتسكّر)، وفوقها
/// حركة الصفحة اللي فوقها ([secondaryAnimation]: وحدة جديدة تغطيها أو ترجع عنها، ووراها لون الخلفية).
class _SmoothPainter extends SnapshotPainter {
  _SmoothPainter(this.animation, this.secondaryAnimation)
    : _ownStatus = animation.status,
      _secondaryStatus = _reversed(secondaryAnimation.status) {
    animation
      ..addListener(notifyListeners)
      ..addStatusListener(_onOwnStatus);
    secondaryAnimation
      ..addListener(notifyListeners)
      ..addStatusListener(_onSecondaryStatus);
  }

  final Animation<double> animation;
  final Animation<double> secondaryAnimation;

  Color _background = Colors.black;
  set background(Color value) {
    if (value == _background) return;
    _background = value;
    notifyListeners();
  }

  bool _opaque = true;
  set opaque(bool value) {
    if (value == _opaque) return;
    _opaque = value;
    notifyListeners();
  }

  // نفس قيم FadeForwardsPageTransitionsBuilder.
  static const _curve = Curves.easeInOutCubicEmphasized;
  static const _fadeIn = Interval(0, .75);
  static const _fadeOut = Interval(0, .25);
  static const _shift = .25;

  // مثل DualTransitionBuilder: لو انعكست الحركة بنصها تكمل بنفس الطريقة لين توصل آخرها (بدون قفزة).
  AnimationStatus _ownStatus;
  AnimationStatus _secondaryStatus; // حالة ReverseAnimation(secondaryAnimation)

  static AnimationStatus _reversed(AnimationStatus s) => switch (s) {
    AnimationStatus.forward => AnimationStatus.reverse,
    AnimationStatus.reverse => AnimationStatus.forward,
    AnimationStatus.completed => AnimationStatus.dismissed,
    AnimationStatus.dismissed => AnimationStatus.completed,
  };

  static AnimationStatus _effective(AnimationStatus last, AnimationStatus current) => switch (current) {
    AnimationStatus.forward when last == AnimationStatus.reverse => last,
    AnimationStatus.reverse when last == AnimationStatus.forward => last,
    _ => current,
  };

  void _onOwnStatus(AnimationStatus s) {
    _ownStatus = _effective(_ownStatus, s);
    notifyListeners();
  }

  void _onSecondaryStatus(AnimationStatus s) {
    _secondaryStatus = _effective(_secondaryStatus, _reversed(s));
    notifyListeners();
  }

  /// الصفحة نفسها: (الظهور، الإزاحة من عرضها).
  (double, double) get _own {
    final a = animation.value;
    return switch (_ownStatus) {
      AnimationStatus.dismissed ||
      AnimationStatus.forward => (_fadeIn.transform(a), _shift * (1 - _curve.transform(a))),
      _ => (1 - _fadeOut.transform(1 - a), _shift * _curve.transform(1 - a)),
    };
  }

  /// الصفحة اللي فوقها: (الظهور، الإزاحة من عرضها).
  (double, double) get _secondary {
    final b = secondaryAnimation.value;
    return switch (_secondaryStatus) {
      AnimationStatus.dismissed ||
      AnimationStatus.forward => (_fadeIn.transform(1 - b), -_shift * (1 - _curve.transform(1 - b))),
      _ => (1 - _fadeOut.transform(b), -_shift * _curve.transform(b)),
    };
  }

  bool get _back => _opaque && secondaryAnimation.isAnimating;

  final _ownLayer = LayerHandle<OpacityLayer>();
  final _secondaryLayer = LayerHandle<OpacityLayer>();

  @override
  void paint(PaintingContext context, Offset offset, Size size, PaintingContextCallback painter) {
    final (ownOpacity, ownShift) = _own;
    final (secondaryOpacity, secondaryShift) = _secondary;
    if (!_back && ownOpacity == 1 && secondaryOpacity == 1 && ownShift == 0 && secondaryShift == 0) {
      _ownLayer.layer = null;
      _secondaryLayer.layer = null;
      return painter(context, offset);
    }
    if (ownOpacity <= 0) return;
    // بدون صورة (ما صارت): نفس طبقات FadeTransition وSlideTransition.
    _ownLayer.layer = context.pushOpacity(offset + Offset(ownShift * size.width, 0), _alpha(ownOpacity), (
      context,
      offset,
    ) {
      if (_back) context.canvas.drawRect(offset & size, Paint()..color = _background);
      _secondaryLayer.layer = context.pushOpacity(
        offset + Offset(secondaryShift * size.width, 0),
        _alpha(secondaryOpacity),
        painter,
        oldLayer: _secondaryLayer.layer,
      );
    }, oldLayer: _ownLayer.layer);
  }

  @override
  void paintSnapshot(
    PaintingContext context,
    Offset offset,
    Size size,
    ui.Image image,
    Size sourceSize,
    double pixelRatio,
  ) {
    final (ownOpacity, ownShift) = _own;
    final (secondaryOpacity, secondaryShift) = _secondary;
    if (ownOpacity <= 0) return;
    // الإزاحة على بكسلات الشاشة بالضبط: الصورة تنرسم بحجمها بدون أي تمويه.
    double snap(double shift) => (shift * size.width * pixelRatio).roundToDouble() / pixelRatio;
    final canvas = context.canvas
      ..save()
      ..translate(offset.dx + snap(ownShift), offset.dy);
    final back = _back;
    final group = back && ownOpacity < 1;
    if (group) canvas.saveLayer(Offset.zero & size, Paint()..color = Color.fromRGBO(0, 0, 0, ownOpacity));
    if (back) canvas.drawRect(Offset.zero & size, Paint()..color = _background);
    final opacity = group ? secondaryOpacity : ownOpacity * secondaryOpacity;
    if (opacity > 0) {
      canvas.drawImageRect(
        image,
        Offset.zero & sourceSize,
        Rect.fromLTWH(snap(secondaryShift), 0, size.width, size.height),
        Paint()
          ..color = Color.fromRGBO(0, 0, 0, opacity)
          ..filterQuality = FilterQuality.low,
      );
    }
    if (group) canvas.restore();
    canvas.restore();
  }

  static int _alpha(double opacity) => (opacity.clamp(0.0, 1.0) * 255).round();

  @override
  void dispose() {
    animation
      ..removeListener(notifyListeners)
      ..removeStatusListener(_onOwnStatus);
    secondaryAnimation
      ..removeListener(notifyListeners)
      ..removeStatusListener(_onSecondaryStatus);
    _ownLayer.layer = null;
    _secondaryLayer.layer = null;
    super.dispose();
  }

  @override
  bool shouldRepaint(_SmoothPainter oldPainter) =>
      oldPainter.animation != animation || oldPainter.secondaryAnimation != secondaryAnimation;
}
