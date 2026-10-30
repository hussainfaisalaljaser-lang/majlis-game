import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'draw_flags.dart';

/// قائمة كروت متحركة (شبكة المتجر): وقت التمرير (الأصبع يسحب أو القائمة ماشية) كل كرت ([Freezable]) يصير
/// صورة ثابتة وحركاته توقف، ولما يوقف التمرير يرجع حي ويكمل حركته من نفس اللحظة. الجوال يعيد رسم كل شي بكل
/// فريم، فالكروت اللي كل وحدة فيها إطار وشخصية متحركين تثقّل التمرير، وصورها ما تكلف شي.
class ScrollFreeze extends StatefulWidget {
  const ScrollFreeze({super.key, required this.child});

  final Widget child;

  /// متجمد الحين؟ (null: مو داخل [ScrollFreeze]).
  static ValueListenable<bool>? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_FreezeScope>()?.frozen;

  @override
  State<ScrollFreeze> createState() => _ScrollFreezeState();
}

class _ScrollFreezeState extends State<ScrollFreeze> {
  final _frozen = ValueNotifier(false);

  @override
  void dispose() {
    _frozen.dispose();
    super.dispose();
  }

  bool _onScroll(ScrollNotification n) {
    // بس القائمة نفسها (مو قائمة صغيرة داخل كرت).
    if (n.depth == 0 && DrawFlags.scrollFreeze) {
      if (n is ScrollStartNotification) _frozen.value = true;
      if (n is ScrollEndNotification) _frozen.value = false;
    }
    return false;
  }

  // الإيقاف (TickerMode) داخل كل كرت بس: لو وقف القائمة نفسها توقف حركة التمرير معها وتعلق.
  @override
  Widget build(BuildContext context) => _FreezeScope(
    frozen: _frozen,
    child: NotificationListener<ScrollNotification>(onNotification: _onScroll, child: widget.child),
  );
}

class _FreezeScope extends InheritedWidget {
  const _FreezeScope({required this.frozen, required super.child});

  final ValueListenable<bool> frozen;

  @override
  bool updateShouldNotify(_FreezeScope old) => old.frozen != frozen;
}

/// كرت يصير صورة وقت تمرير [ScrollFreeze] اللي فوقه، وحركاته توقف (وتكمل من نفس اللحظة لما يوقف التمرير).
/// برا القائمة ما يسوي شي. [margin]: كم يرسم الكرت برا حدوده (ظله)، عشان الصورة تشمله.
class Freezable extends StatelessWidget {
  const Freezable({super.key, this.margin = 14, required this.child});

  final double margin;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final frozen = ScrollFreeze.of(context);
    if (frozen == null) return child;
    return ValueListenableBuilder(
      valueListenable: frozen,
      builder: (context, f, child) => TickerMode(enabled: !f, child: child!),
      child: _Freeze(frozen: frozen, margin: margin, child: child),
    );
  }
}

class _Freeze extends SingleChildRenderObjectWidget {
  const _Freeze({required this.frozen, required this.margin, super.child});

  final ValueListenable<bool> frozen;
  final double margin;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderFreezable(frozen, margin, MediaQuery.devicePixelRatioOf(context));

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) => (renderObject as _RenderFreezable)
    ..frozen = frozen
    ..margin = margin
    ..ratio = MediaQuery.devicePixelRatioOf(context);
}

class _RenderFreezable extends RenderProxyBox {
  _RenderFreezable(this._frozen, this._margin, this._ratio);

  ValueListenable<bool>? _frozen;
  set frozen(ValueListenable<bool>? value) {
    if (value == _frozen) return;
    if (attached) _frozen?.removeListener(_changed);
    _frozen = value;
    if (attached) _frozen?.addListener(_changed);
    _changed();
  }

  double _margin;
  set margin(double value) {
    if (value == _margin) return;
    _margin = value;
    _drop();
  }

  double _ratio;
  set ratio(double value) {
    if (value == _ratio) return;
    _ratio = value;
    _drop();
  }

  ui.Image? _image;
  Size? _imageSize;
  double? _imageRatio;

  void _drop() {
    _image?.dispose();
    _image = null;
    markNeedsPaint();
  }

  /// بداية التمرير: صورة جديدة (باللحظة الحالية). نهايته: يرجع حي.
  void _changed() => _drop();

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _frozen?.addListener(_changed);
  }

  @override
  void detach() {
    _frozen?.removeListener(_changed);
    _image?.dispose();
    _image = null;
    super.detach();
  }

  @override
  void dispose() {
    _image?.dispose();
    _image = null;
    super.dispose();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final child = this.child;
    if (child == null || !(_frozen?.value ?? false) || size.isEmpty) return super.paint(context, offset);
    // بدقة الشاشة × أي تصغير فوق الكرت، والهامش ببكسلات كاملة.
    final m = getTransformTo(null).storage;
    final ratio = _ratio * math.sqrt(m[0] * m[0] + m[1] * m[1]);
    if (ratio <= 0) return super.paint(context, offset);
    final margin = (_margin * ratio).ceil() / ratio;
    if (_image == null || _imageSize != size || _imageRatio != ratio) {
      _image?.dispose();
      final layer = OffsetLayer();
      final c = PaintingContext(layer, Offset.zero & size);
      c.paintChild(child, Offset.zero);
      // ignore: invalid_use_of_protected_member
      c.stopRecordingIfNeeded();
      _image = layer.toImageSync(
        Rect.fromLTWH(-margin, -margin, size.width + 2 * margin, size.height + 2 * margin),
        pixelRatio: ratio,
      );
      layer.dispose();
      _imageSize = size;
      _imageRatio = ratio;
    }
    final image = _image!;
    context.canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(offset.dx - margin, offset.dy - margin, image.width / ratio, image.height / ratio),
      Paint()..filterQuality = FilterQuality.low,
    );
  }
}

/// تبديل محتوى بتلاشي (مثل الافتراضي في AnimatedSwitcher بالضبط)، بس خلال التلاشي (ربع ثانية تقريباً) المحتوى
/// صورة ثابتة وحركاته واقفة: الجوال يرسم صورتين بدل شبكتين كاملتين متحركتين فوق بعض.
Widget frozenFade(Widget child, Animation<double> animation) => _FrozenFade(animation: animation, child: child);

class _FrozenFade extends StatefulWidget {
  const _FrozenFade({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  State<_FrozenFade> createState() => _FrozenFadeState();
}

class _FrozenFadeState extends State<_FrozenFade> {
  final _snapshot = SnapshotController();
  late _FadePainter _painter = _FadePainter(widget.animation);

  @override
  void initState() {
    super.initState();
    widget.animation.addStatusListener(_status);
    _snapshot.allowSnapshotting = widget.animation.isAnimating;
  }

  @override
  void didUpdateWidget(_FrozenFade old) {
    super.didUpdateWidget(old);
    if (old.animation != widget.animation) {
      old.animation.removeStatusListener(_status);
      widget.animation.addStatusListener(_status);
      _painter.dispose();
      _painter = _FadePainter(widget.animation);
      _status(widget.animation.status);
    }
  }

  @override
  void dispose() {
    widget.animation.removeStatusListener(_status);
    _painter.dispose();
    _snapshot.dispose();
    super.dispose();
  }

  void _status(AnimationStatus _) {
    if (!mounted) return;
    setState(() => _snapshot.allowSnapshotting = widget.animation.isAnimating);
  }

  @override
  Widget build(BuildContext context) => SnapshotWidget(
    controller: _snapshot,
    painter: _painter,
    mode: SnapshotMode.permissive,
    autoresize: true,
    child: TickerMode(enabled: !widget.animation.isAnimating, child: widget.child),
  );
}

/// نفس FadeTransition: الظهور = قيمة الحركة.
class _FadePainter extends SnapshotPainter {
  _FadePainter(this.animation) {
    animation.addListener(notifyListeners);
  }

  final Animation<double> animation;
  final _layer = LayerHandle<OpacityLayer>();

  @override
  void paint(PaintingContext context, Offset offset, Size size, PaintingContextCallback painter) {
    final opacity = animation.value.clamp(0.0, 1.0);
    if (opacity >= 1) {
      _layer.layer = null;
      return painter(context, offset);
    }
    if (opacity <= 0) {
      _layer.layer = null;
      return;
    }
    _layer.layer = context.pushOpacity(offset, (opacity * 255).round(), painter, oldLayer: _layer.layer);
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
    final opacity = animation.value.clamp(0.0, 1.0);
    if (opacity <= 0) return;
    context.canvas.drawImageRect(
      image,
      Offset.zero & sourceSize,
      offset & size,
      Paint()
        ..color = Color.fromRGBO(0, 0, 0, opacity)
        ..filterQuality = FilterQuality.low,
    );
  }

  @override
  void dispose() {
    animation.removeListener(notifyListeners);
    _layer.layer = null;
    super.dispose();
  }

  @override
  bool shouldRepaint(_FadePainter oldPainter) => oldPainter.animation != animation;
}
