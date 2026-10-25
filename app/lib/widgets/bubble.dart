import 'package:flutter/material.dart';

import '../models/shop.dart';
import 'fx.dart';

/// فقاعة كلام بشكل من المتجر (بحركاتها). يشوفها كل اللي بالطاولة.
class ChatBubble extends StatelessWidget {
  const ChatBubble({super.key, required this.style, required this.text, this.fontSize = 12, this.maxWidth = 170});

  final BubbleStyle style;
  final String text;
  final double fontSize;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    const tail = 7.0;
    return FxClock(
      builder: (context, t) => CustomPaint(
        painter: BubblePainter(style, t, tail: tail),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(11, 4, 11, 5 + tail),
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(color: style.text, fontSize: fontSize, fontWeight: FontWeight.w800, height: 1.25),
            ),
          ),
        ),
      ),
    );
  }
}

/// ملصق (ميم) يطلع بحركة نطّة.
class StickerView extends StatelessWidget {
  const StickerView({super.key, required this.sticker, this.size = 72, this.pop = true});

  final Sticker sticker;
  final double size;
  final bool pop;

  @override
  Widget build(BuildContext context) {
    final img = Image.asset(sticker.asset, width: size, height: size, filterQuality: FilterQuality.medium);
    if (!pop) return Semantics(label: sticker.caption, child: img);
    return Semantics(
      label: sticker.caption,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 520),
        curve: Curves.elasticOut,
        builder: (context, v, child) => Transform.rotate(
          angle: (1 - v) * -.35,
          child: Transform.scale(scale: .3 + v * .7, child: child),
        ),
        child: img,
      ),
    );
  }
}
