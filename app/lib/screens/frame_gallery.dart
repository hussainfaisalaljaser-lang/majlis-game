import 'package:flutter/material.dart';

import '../models/shop.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/ui.dart';

/// معرض الإطارات (نسخة المحاكي على الويب بس، ‎?gallery=frames‎): كل الإطارات بحجم المتجر وحجم الطاولة
/// عشان نصورها ونراجعها. ‎&only=fire,sun‎ يعرض بعضها (وواحد بس يعرضه كبير بالنص للفيديو)، و‎&size=‎ يغير
/// الحجم، و‎&cols=‎ عدد الأعمدة.
class FrameGalleryApp extends StatelessWidget {
  const FrameGalleryApp({super.key});

  @override
  Widget build(BuildContext context) {
    final q = Uri.base.queryParameters;
    final only = q['only']?.split(',').toSet();
    final items = [
      for (final item in catalog)
        if (item.frame != null && (only == null || only.contains(item.frame!.sig))) item,
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

class _Cell extends StatelessWidget {
  const _Cell({required this.item, required this.size, required this.avatar});

  final ShopItem item;
  final double size;
  final String avatar;

  @override
  Widget build(BuildContext context) {
    final style = item.frame!;
    return Column(
      children: [
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PlayerAvatar(avatar: avatar, style: style, size: size, momentKey: style.sig),
              const SizedBox(width: 18),
              // حجم الكرسي على الطاولة
              PlayerAvatar(avatar: avatar, style: style, size: 62, momentKey: style.sig),
            ],
          ),
        ),
        Text(
          '${item.name} · ${style.sig}',
          style: TextStyle(color: item.rarity.color, fontWeight: FontWeight.w800, fontSize: 13),
        ),
      ],
    );
  }
}

/// إطار واحد كبير بالنص (للفيديو): بحجم المعاينة، وجنبه بحجم الطاولة، وتحته اسمه ووصفه.
class _Solo extends StatelessWidget {
  const _Solo({required this.item, required this.size, required this.avatar});

  final ShopItem item;
  final double size;
  final String avatar;

  @override
  Widget build(BuildContext context) {
    final style = item.frame!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PlayerAvatar(avatar: avatar, style: style, size: size, momentKey: style.sig),
              const SizedBox(width: 90),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PlayerAvatar(avatar: avatar, style: style, size: 62, momentKey: style.sig),
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
