import 'package:flutter/material.dart';

import '../models/game_view.dart';
import '../models/profile.dart';
import '../models/shop.dart';
import 'bubble.dart';
import 'common.dart';
import 'death_fx.dart';
import 'game/policy_card.dart';

/// معاينة الغرض حسب نوعه.
class ItemPreview extends StatelessWidget {
  const ItemPreview({super.key, required this.item, required this.profile, this.big = false, this.scale = 1});

  final ShopItem item;
  final Profile profile;
  final bool big;

  /// تكبير أو تصغير المعاينة (بدون [big]): الكروت بالشبكة تصغرها شوي، ونافذة الغرض الجديد تكبرها.
  final double scale;

  @override
  Widget build(BuildContext context) {
    final k = big ? 1.7 : scale;
    return switch (item.slot) {
      // «بدون إطار»: حلقة بنية سادة مثل التصميم
      ShopSlot.frame when item.frame == null => PlayerAvatar(
        avatar: profile.avatar,
        frame: const Color(0xFF4A2E1B),
        size: 70 * k,
      ),
      ShopSlot.frame => PlayerAvatar(avatar: profile.avatar, style: item.frame, size: 70 * k),
      ShopSlot.avatar => PlayerAvatar(avatar: item.avatar!, style: frameStyle(profile.frame), size: 74 * k),
      ShopSlot.bubble => ChatBubble(
        style: item.bubble!,
        text: big ? 'أشك في سلمان!' : 'أشك فيه',
        fontSize: 13 * k,
        maxWidth: 260,
      ),
      ShopSlot.table => TablePreview(skin: item.table!, width: big ? 420 : null),
      ShopSlot.death => DeathPreview(fx: item.death!, avatar: profile.avatar, frame: profile.frame, size: 52 * k),
      ShopSlot.cards => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PolicyCard(policy: Policy.loyal, skin: item.cards, width: 50 * k),
          SizedBox(width: 6 * k),
          PolicyCard(policy: Policy.traitor, skin: item.cards, width: 50 * k),
        ],
      ),
      ShopSlot.reactions =>
        item.stickers != null
            ? Wrap(
                alignment: WrapAlignment.center,
                spacing: 2,
                runSpacing: 2,
                children: [
                  for (final id in item.stickers!.take(big ? 6 : 4))
                    StickerView(sticker: stickerById(id)!, size: big ? 96 : 56, pop: false),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final r in textReactions.where((r) => r.pack == item.id).take(big ? 7 : 2))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: ChatBubble(
                        style: bubbleStyle(profile.bubble),
                        text: r.text('سلمان'),
                        fontSize: big ? 15 : 12,
                      ),
                    ),
                ],
              ),
    };
  }
}

/// السجادة والصينية مصغرة، مثل ما تطلع في اللعبة.
class TablePreview extends StatelessWidget {
  const TablePreview({super.key, required this.skin, this.width});

  final TableSkin skin;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final w = width ?? 210;
    final h = w / 2.1;
    return SizedBox(
      width: w,
      height: h,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset(skin.carpet, width: w, height: h, fit: BoxFit.fill),
          Image.asset(skin.tray, width: w * .46, height: h * .56, fit: BoxFit.fill),
        ],
      ),
    );
  }
}
