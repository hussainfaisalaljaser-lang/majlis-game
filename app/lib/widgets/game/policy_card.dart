import 'package:flutter/material.dart';

import '../../models/game_view.dart';
import '../../models/shop.dart';
import '../../theme.dart';
import '../ui.dart';

/// كرت قرار: ورق قديم عليه ختم شمعي. أزرق للأوفياء وأحمر للخونة في كل الأشكال.
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
  });

  final Policy policy;
  final VoidCallback? onTap;
  final bool dimmed;
  final String? label;

  /// شكل الكروت من المتجر (يغيّر الختم والإطار).
  final CardSkin? skin;
  final double width;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final loyal = policy == Policy.loyal;
    final skin = this.skin;
    final classic = skin == null || skin.border == null;
    final edge = loyal ? AppColors.loyalDark : AppColors.traitorDark;
    final h = width * 1.45;

    Widget seal;
    if (classic) {
      seal = Seal(loyal: loyal, size: width * .58);
    } else {
      seal = Container(
        width: width * .56,
        height: width * .56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: loyal ? skin.loyal : skin.traitor),
          border: Border.all(color: skin.border!, width: 2.5),
          boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 2))],
        ),
        child: Padding(
          padding: EdgeInsets.all(width * .07),
          child: Image.asset('assets/icons/gfx_card_${loyal ? skin.loyalIcon : skin.traitorIcon}.png'),
        ),
      );
    }

    return Semantics(
      button: onTap != null,
      label: label ?? (loyal ? 'كرت أوفياء' : 'كرت خونة'),
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: dimmed ? .35 : 1,
          child: Container(
            width: width,
            height: h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFF8EBD0), AppColors.parchmentDark],
              ),
              border: Border.all(color: skin?.border ?? edge, width: 3),
              boxShadow: [
                const BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 6)),
                if (highlight) BoxShadow(color: AppColors.gold.withValues(alpha: .8), blurRadius: 18),
              ],
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    margin: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFB88A4A), width: 1.2),
                    ),
                  ),
                ),
                Align(alignment: const Alignment(0, -.25), child: seal),
                Align(
                  alignment: const Alignment(0, .78),
                  child: Text(
                    loyal ? 'أوفياء' : 'خونة',
                    style: TextStyle(fontFamily: kufi, fontWeight: FontWeight.w700, fontSize: width * .17, color: edge),
                  ),
                ),
              ],
            ),
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
