import 'package:flutter/material.dart';

import '../../models/profile.dart';
import '../../models/shop.dart';
import '../../theme.dart';
import '../bubble.dart';
import '../common.dart';

/// لوحة الردود في اللعبة: الكلام بفقاعتك، وباقات الملصقات (المقفلة تطلع باهتة مع وين تنكسب).
/// بدون [onText] (الدردشة): الملصقات بس.
class ReactionsSheet extends StatefulWidget {
  const ReactionsSheet({
    super.key,
    required this.profile,
    this.onText,
    required this.onSticker,
    this.onClearOpinion,
    this.over = false,
    this.onFavorites,
  });

  final Profile profile;
  final ValueChanged<TextReaction>? onText;
  final ValueChanged<Sticker> onSticker;

  /// المفضلة تغيّرت (ضغطة مطوّلة على ملصق تضيفه أو تشيله).
  final ValueChanged<List<String>>? onFavorites;

  /// يطلع زر "أشيل رأيي" لو عنده رأي في أحد.
  final VoidCallback? onClearOpinion;

  /// اللعبة خلصت: سوالف بس، ما فيه "أشك" و"أثق".
  final bool over;

  @override
  State<ReactionsSheet> createState() => _ReactionsSheetState();
}

class _ReactionsSheetState extends State<ReactionsSheet> {
  // ٠ = الكلام، والباقي باقات الملصقات بالترتيب (المملوكة أول).
  int _tab = 1;

  /// المفضلة هنا تتغير على طول (والسيرفر يحفظها ورا).
  late final List<String> _favorites = [...widget.profile.favorites];

  /// آخر شي صار في المفضلة (انضاف، انشال، مليانة).
  String? _favNote;

  void _toggleFavorite(String id) {
    setState(() {
      if (_favorites.remove(id)) {
        _favNote = 'شلته من المفضلة';
      } else if (_favorites.length >= Profile.maxFavorites) {
        _favNote = 'المفضلة مليانة (${arabicNumber(Profile.maxFavorites)})، شيل واحد أول';
        return;
      } else {
        _favorites.add(id);
        _favNote = 'انضاف للمفضلة (${arabicNumber(_favorites.length)} من ${arabicNumber(Profile.maxFavorites)})';
      }
      widget.onFavorites?.call([..._favorites]);
    });
  }

  late final List<ShopItem> _packs = () {
    final packs = [
      for (final i in catalog)
        if (i.stickers != null) i,
    ];
    final owned = [
      for (final p in packs)
        if (widget.profile.owns(p.id)) p,
    ];
    final locked = [
      for (final p in packs)
        if (!widget.profile.owns(p.id)) p,
    ];
    return [...owned, ...locked];
  }();

  @override
  Widget build(BuildContext context) {
    final p = widget.profile;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // التبويبات: الكلام ثم الباقات
            SizedBox(
              width: 74,
              child: ListView(
                children: [
                  if (widget.onText != null)
                    _TabButton(
                      selected: _tab == 0,
                      label: 'كلام',
                      onTap: () => setState(() => _tab = 0),
                      child: ChatBubble(style: bubbleStyle(p.bubble), text: 'هلا', fontSize: 11, maxWidth: 60),
                    ),
                  for (final (i, pack) in _packs.indexed)
                    _TabButton(
                      selected: _tab == i + 1,
                      label: pack.name,
                      locked: !p.owns(pack.id),
                      onTap: () => setState(() => _tab = i + 1),
                      child: Image.asset(stickerById(pack.stickers!.first)!.asset, width: 40, height: 40),
                    ),
                ],
              ),
            ),
            const VerticalDivider(color: AppColors.line, width: 14),
            Expanded(child: _tab == 0 ? _texts(p) : _stickers(p, _packs[_tab - 1])),
          ],
        ),
      ),
    );
  }

  Widget _texts(Profile p) {
    final style = bubbleStyle(p.bubble);
    return ListView(
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 10,
          children: [
            for (final r in textReactions)
              if ((r.pack == null || p.owns(r.pack!)) && !(widget.over && (r.id == 'suspect' || r.id == 'trust')))
                Semantics(
                  button: true,
                  label: 'رد ${r.id}',
                  excludeSemantics: true,
                  child: GestureDetector(
                    onTap: () => widget.onText?.call(r),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (r.icon != null) ...[Gfx(r.icon!, size: 26), const SizedBox(width: 2)],
                        ChatBubble(style: style, text: r.label, fontSize: 14, maxWidth: 200),
                      ],
                    ),
                  ),
                ),
          ],
        ),
        if (!p.owns('pack_phrases')) ...[
          const SizedBox(height: 14),
          const _LockedNote('فيه ٧ جمل زيادة في باقة "سوالف المجلس" بالمتجر'),
        ],
        if (widget.onClearOpinion != null) ...[
          const SizedBox(height: 10),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(onPressed: widget.onClearOpinion, child: const Text('أشيل رأيي في لاعب')),
          ),
        ],
      ],
    );
  }

  Widget _stickers(Profile p, ShopItem pack) {
    final owned = p.owns(pack.id);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              pack.name,
              style: const TextStyle(fontFamily: kufi, fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 8),
            if (!owned) Expanded(child: _LockedNote(pack.buyable ? 'من المتجر (تبويب الملصقات)' : pack.source)),
            if (owned && widget.onFavorites != null)
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Row(
                    key: ValueKey(_favNote),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded, color: AppColors.gold, size: 18),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          _favNote ?? 'اضغط مطوّل على ملصق وتحطه بالمفضلة',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _favNote == null ? AppColors.muted : AppColors.goldLight,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Expanded(
          child: GridView.count(
            crossAxisCount: 6,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            children: [
              for (final id in pack.stickers!)
                Semantics(
                  button: owned,
                  label: 'ملصق $id',
                  excludeSemantics: true,
                  child: GestureDetector(
                    onTap: owned ? () => widget.onSticker(stickerById(id)!) : null,
                    onLongPress: owned && widget.onFavorites != null ? () => _toggleFavorite(id) : null,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned.fill(
                          child: Opacity(
                            opacity: owned ? 1 : .38,
                            child: StickerView(sticker: stickerById(id)!, pop: false),
                          ),
                        ),
                        if (_favorites.contains(id))
                          const PositionedDirectional(
                            top: -4,
                            end: -2,
                            child: Icon(
                              Icons.star_rounded,
                              color: AppColors.gold,
                              size: 22,
                              shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.selected,
    required this.label,
    required this.onTap,
    required this.child,
    this.locked = false,
  });

  final bool selected;
  final String label;
  final VoidCallback onTap;
  final Widget child;
  final bool locked;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: 'باقة $label',
    excludeSemantics: true,
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(
          color: selected ? AppColors.gold.withValues(alpha: .16) : AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? AppColors.gold : AppColors.line, width: selected ? 1.6 : 1),
        ),
        child: Column(
          children: [
            Opacity(
              opacity: locked ? .45 : 1,
              child: SizedBox(height: 40, child: Center(child: child)),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (locked) const Padding(padding: EdgeInsetsDirectional.only(end: 2), child: Gfx('lock', size: 11)),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: selected ? AppColors.gold : AppColors.muted,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _LockedNote extends StatelessWidget {
  const _LockedNote(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Gfx('lock', size: 16),
      const SizedBox(width: 5),
      Flexible(
        child: Text(text, style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
      ),
    ],
  );
}
