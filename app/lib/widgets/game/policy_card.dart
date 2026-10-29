import 'package:flutter/material.dart';

import '../../models/game_view.dart';
import '../../models/shop.dart';
import '../design_game.dart';
import '../ui.dart';

/// كرت قرار: ورق قديم ممزق الأطراف، أزرق بنجمة ذهبية للأوفياء، وأحمر بخنجر للخونة (مثل التصميم).
/// أشكال الكروت من المتجر تغيّر ألوانه ورمزه.
class PolicyCard extends StatelessWidget {
  const PolicyCard({
    super.key,
    required this.policy,
    this.onTap,
    this.dimmed = false,
    this.label,
    this.skin,
    this.width = 92,
    this.highlight = false,
    this.stamp,
  });

  final Policy policy;
  final VoidCallback? onTap;
  final bool dimmed;
  final String? label;

  /// شكل الكروت من المتجر (يغيّر الألوان والرمز).
  final CardSkin? skin;
  final double width;
  final bool highlight;

  /// مشهد الختم: الرمز ينزل على الورقة من فوق (٠ قبل، ١ انختم). بدونه الورقة مختومة.
  final double? stamp;

  @override
  Widget build(BuildContext context) {
    final loyal = policy == Policy.loyal;
    final skin = this.skin;
    final classic = skin == null || skin.border == null;
    return Semantics(
      button: onTap != null,
      label: label ?? (loyal ? 'كرت أوفياء' : 'كرت خونة'),
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: dimmed ? .35 : 1,
          child: GameCardFace(
            kind: loyal ? GameCardKind.loyal : GameCardKind.traitor,
            width: width,
            stamp: stamp,
            glow: highlight,
            colors: classic ? null : (skin.border!, (loyal ? skin.loyal : skin.traitor).first, (loyal ? skin.loyal : skin.traitor).last),
            emblem: classic ? null : (loyal ? skin.loyalIcon : skin.traitorIcon),
          ),
        ),
      ),
    );
  }
}

/// أختام صغيرة (للادعاءات والسجل).
class MiniPolicies extends StatelessWidget {
  const MiniPolicies(this.policies, {super.key, this.size = 16});

  final List<Policy> policies;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final p in policies)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: Seal(loyal: p == Policy.loyal, size: size * 1.25),
          ),
      ],
    );
  }
}
