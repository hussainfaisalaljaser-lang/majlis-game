import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// رسمة ثابتة تنرسم مرة وحدة كصورة، وبعدها كل فريم تنعرض الصورة بس.
/// الجوال يرسم الشاشة كلها من جديد بكل فريم، فالرسمة المعقدة (الخيمة، السجادة) لو تنرسم خط خط تثقّل
/// كل حركة فوقها. تنعاد بس لو تغيّر المقاس أو الرسمة ([CustomPainter.shouldRepaint]).
class CachedPaint extends StatefulWidget {
  const CachedPaint({super.key, required this.painter});

  final CustomPainter painter;

  @override
  State<CachedPaint> createState() => _CachedPaintState();
}

class _CachedPaintState extends State<CachedPaint> {
  ui.Image? _image;
  Size? _size;
  double? _ratio;
  CustomPainter? _painted;

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }

  ui.Image _render(Size size, double ratio) {
    final recorder = ui.PictureRecorder();
    widget.painter.paint(Canvas(recorder)..scale(ratio), size);
    final picture = recorder.endRecording();
    final image = picture.toImageSync((size.width * ratio).ceil(), (size.height * ratio).ceil());
    picture.dispose();
    return image;
  }

  @override
  Widget build(BuildContext context) {
    final ratio = MediaQuery.devicePixelRatioOf(context);
    return LayoutBuilder(
      builder: (context, box) {
        final size = box.biggest;
        if (size.isEmpty || !size.isFinite) return const SizedBox.shrink();
        final old = _painted;
        if (_image == null ||
            size != _size ||
            ratio != _ratio ||
            (old != null && !identical(old, widget.painter) && widget.painter.shouldRepaint(old))) {
          _image?.dispose();
          _image = _render(size, ratio);
          _size = size;
          _ratio = ratio;
        }
        _painted = widget.painter;
        return RawImage(image: _image, width: size.width, height: size.height, fit: BoxFit.fill);
      },
    );
  }
}

/// صورة مموّهة تتموّه مرة وحدة بس (التمويه كل فريم من أثقل شي على الجوال). تغطي مكانها مثل [BoxFit.cover].
class BlurredImage extends StatefulWidget {
  const BlurredImage(this.image, {super.key, required this.sigma});

  final ImageProvider image;
  final double sigma;

  @override
  State<BlurredImage> createState() => _BlurredImageState();
}

class _BlurredImageState extends State<BlurredImage> {
  ImageStream? _stream;
  ImageInfo? _info;
  late final _listener = ImageStreamListener((info, _) {
    if (!mounted) return info.dispose();
    setState(() {
      _info?.dispose();
      _info = info;
    });
  });

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final stream = widget.image.resolve(createLocalImageConfiguration(context));
    if (stream.key == _stream?.key) return;
    _stream?.removeListener(_listener);
    _stream = stream..addListener(_listener);
  }

  @override
  void dispose() {
    _stream?.removeListener(_listener);
    _info?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final info = _info;
    if (info == null) return const SizedBox.shrink();
    return CachedPaint(painter: _BlurPainter(info.image, widget.sigma));
  }
}

class _BlurPainter extends CustomPainter {
  const _BlurPainter(this.image, this.sigma);

  final ui.Image image;
  final double sigma;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.saveLayer(rect, Paint()..imageFilter = ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma));
    paintImage(canvas: canvas, rect: rect, image: image, fit: BoxFit.cover);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_BlurPainter old) => !old.image.isCloneOf(image) || old.sigma != sigma;
}
