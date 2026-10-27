import 'package:flutter/material.dart';

import '../models/shop.dart';
import '../theme.dart';
import '../widgets/bubble.dart';
import '../widgets/common.dart';
import '../widgets/sticker_motion.dart';
import '../widgets/ui.dart';
import 'concepts/ideas.dart';

/// معرض المتجر (نسخة المحاكي على الويب بس): ‎?gallery=frames‎ كل الإطارات، و‎?gallery=avatars‎ الشخصيات اللي
/// تتحرك، و‎?gallery=stickers‎ الملصقات اللي تتحرك، بحجم المتجر وحجم الطاولة عشان نصورها ونراجعها. ‎&only=fire,sun‎ يعرض بعضها (وواحد بس يعرضه كبير بالنص
/// للفيديو)، و‎&size=‎ يغير الحجم، و‎&cols=‎ عدد الأعمدة. و‎?gallery=ideas‎ نماذج الأفكار الجديدة (concepts/ideas.dart).
class FrameGalleryApp extends StatelessWidget {
  const FrameGalleryApp({super.key});

  @override
  Widget build(BuildContext context) {
    final q = Uri.base.queryParameters;
    if (q['gallery'] == 'stickers') return _StickerGallery(q);
    if (q['gallery'] == 'ideas') return IdeasGalleryApp(q);
    final avatars = q['gallery'] == 'avatars';
    final only = q['only']?.split(',').toSet();
    final items = [
      for (final item in catalog)
        if (avatars ? item.avatarArt?.anim != null : item.frame != null)
          if (only == null || only.contains(avatars ? item.avatar : item.frame!.sig)) item,
    ];
    final size = double.tryParse(q['size'] ?? '') ?? 104;
    final cols = int.tryParse(q['cols'] ?? '') ?? 6;
    final avatar = q['avatar'] ?? 'cool';
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      locale: const Locale('ar'),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: NightScaffold(
          body: items.length == 1
              ? _Solo(item: items.single, size: double.tryParse(q['size'] ?? '') ?? 190, avatar: avatar)
              : GridView.count(
                  crossAxisCount: cols,
                  padding: const EdgeInsets.all(8),
                  childAspectRatio: 1.25,
                  children: [for (final item in items) _Cell(item: item, size: size, avatar: avatar)],
                ),
        ),
      ),
    );
  }
}

/// الغرض على صورة: إطار على الشخصية المختارة، أو الشخصية نفسها.
Widget _preview(ShopItem item, String avatar, double size) => switch (item.frame) {
  final style? => PlayerAvatar(avatar: avatar, style: style, size: size, momentKey: style.sig),
  null => PlayerAvatar(avatar: item.avatar!, size: size),
};

class _Cell extends StatelessWidget {
  const _Cell({required this.item, required this.size, required this.avatar});

  final ShopItem item;
  final double size;
  final String avatar;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _preview(item, avatar, size),
              const SizedBox(width: 18),
              // حجم الكرسي على الطاولة
              _preview(item, avatar, 62),
            ],
          ),
        ),
        Text(
          '${item.name} · ${item.frame?.sig ?? item.avatar}',
          style: TextStyle(color: item.rarity.color, fontWeight: FontWeight.w800, fontSize: 13),
        ),
      ],
    );
  }
}

/// غرض واحد كبير بالنص (للفيديو): بحجم المعاينة، وجنبه بحجم الطاولة، وتحته اسمه ووصفه.
class _Solo extends StatelessWidget {
  const _Solo({required this.item, required this.size, required this.avatar});

  final ShopItem item;
  final double size;
  final String avatar;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _preview(item, avatar, size),
              const SizedBox(width: 90),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _preview(item, avatar, 62),
                  const SizedBox(height: 10),
                  const Text('على الطاولة', style: TextStyle(color: AppColors.muted, fontSize: 12)),
                ],
              ),
            ],
          ),
          SizedBox(height: size * .32),
          Text(
            '${item.name} · ${item.rarity.label}',
            style: TextStyle(color: item.rarity.color, fontWeight: FontWeight.w900, fontSize: 24),
          ),
          if (item.desc != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(item.desc!, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }
}

/// الملصقات اللي تتحرك (‎&only=par_dance‎ لملصق واحد كبير).
class _StickerGallery extends StatelessWidget {
  const _StickerGallery(this.q);

  final Map<String, String> q;

  @override
  Widget build(BuildContext context) {
    final only = q['only']?.split(',').toSet();
    final list = [
      for (final s in stickers)
        if (StickerMotion.has(s) && (only == null || only.contains(s.id))) s,
    ];
    final size = double.tryParse(q['size'] ?? '') ?? 110;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      locale: const Locale('ar'),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: NightScaffold(
          body: list.length == 1
              ? Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      StickerView(sticker: list.single, size: size, pop: false),
                      const SizedBox(width: 60),
                      // حجم الملصق على الطاولة
                      StickerView(sticker: list.single, size: 70, pop: false),
                    ],
                  ),
                )
              : GridView.count(
                  crossAxisCount: int.tryParse(q['cols'] ?? '') ?? 9,
                  padding: const EdgeInsets.all(12),
                  children: [
                    for (final s in list)
                      Center(
                        child: StickerView(sticker: s, size: size, pop: false),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}
