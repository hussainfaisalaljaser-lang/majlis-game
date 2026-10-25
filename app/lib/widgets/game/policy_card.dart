import 'package:flutter/material.dart';

import '../../models/game_view.dart';
import '../../models/shop.dart';
import '../../theme.dart';

/// كرت قرار كبير (لما الرئيس أو المستشار يختار).
class PolicyCard extends StatelessWidget {
  const PolicyCard({super.key, required this.policy, this.onTap, this.dimmed = false, this.label, this.skin});

  final Policy policy;
  final VoidCallback? onTap;
  final bool dimmed;
  final String? label;

  /// شكل الكروت من المتجر. الألوان تبقى أزرق للأوفياء وأحمر للخونة عشان ما يصير لبس.
  final CardSkin? skin;

  @override
  Widget build(BuildContext context) {
    final loyal = policy == Policy.loyal;
    final skin = this.skin ?? cardSkin(null);
    return Semantics(
      button: onTap != null,
      label: label ?? (loyal ? 'كرت أوفياء' : 'كرت خونة'),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: dimmed ? .35 : 1,
          child: Container(
            width: 84,
            height: 118,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: loyal ? skin.loyal : skin.traitor,
              ),
              border: skin.border == null ? null : Border.all(color: skin.border!, width: 2.5),
              boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 4))],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(loyal ? skin.loyalIcon : skin.traitorIcon, style: const TextStyle(fontSize: 34)),
                const SizedBox(height: 6),
                Text(loyal ? 'أوفياء' : 'خونة', style: const TextStyle(fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// كروت صغيرة ملونة (للادعاءات والسجل).
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
          Container(
            width: size,
            height: size * 1.35,
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            decoration: BoxDecoration(
              color: p == Policy.loyal ? AppColors.loyal : AppColors.traitor,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
      ],
    );
  }
}
