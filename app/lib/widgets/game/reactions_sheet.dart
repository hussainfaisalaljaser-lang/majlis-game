import 'package:flutter/material.dart';

import '../../models/profile.dart';
import '../../models/shop.dart';
import '../../theme.dart';
import '../bubble.dart';
import '../common.dart';
import '../design.dart';
import '../design_dialogs.dart';
import '../design_game.dart';
import '../ui.dart';

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
    // اللوحة (خشب بحافة ذهبية) ترسمها هالنافذة نفسها، والشيت اللي فوقها شفاف.
    return SheetPanel(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 13, 14, 8),
          child: Column(
            children: [
              const SheetHandle(),
              const SizedBox(height: 8),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // التبويبات: الكلام ثم الباقات (شريط غامق على الجنب مثل أقسام المتجر)
                    SizedBox(
                      width: 84,
                      child: _Inset(
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(5, 6, 5, 0),
                          children: [
                            if (widget.onText != null)
                              _TabButton(
                                selected: _tab == 0,
                                label: 'كلام',
                                onTap: () => setState(() => _tab = 0),
                                child: ChatBubble(
                                  style: bubbleStyle(p.bubble),
                                  text: 'هلا',
                                  fontSize: 11,
                                  maxWidth: 60,
                                ),
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
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _Inset(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                          child: _tab == 0 ? _texts(p) : _stickers(p, _packs[_tab - 1]),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
          const Align(
            alignment: AlignmentDirectional.centerStart,
            child: _LockedNote('فيه ٧ جمل زيادة في باقة "سوالف المجلس" بالمتجر'),
          ),
        ],
        if (widget.onClearOpinion != null) ...[
          const SizedBox(height: 12),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: SizedBox(
              width: 200,
              child: GameButton(
                label: 'أشيل رأيي في لاعب',
                tone: ButtonTone.red,
                height: 40,
                fontSize: 14.5,
                onPressed: widget.onClearOpinion,
              ),
            ),
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
            GoldTitle(pack.name, size: 19),
            const SizedBox(width: 10),
            if (!owned)
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: _LockedNote(pack.buyable ? 'من المتجر (تبويب الملصقات)' : pack.source),
                ),
              ),
            if (owned && widget.onFavorites != null)
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: NotePill(
                      _favNote ?? 'اضغط مطوّل على ملصق وتحطه بالمفضلة',
                      key: ValueKey(_favNote),
                      icon: const Icon(Icons.star_rounded, color: AppColors.gold, size: 18),
                      color: _favNote == null ? const Color(0xFFE7CFA6) : AppColors.goldLight,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: GridView.count(
            crossAxisCount: 6,
            mainAxisSpacing: 7,
            crossAxisSpacing: 7,
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
                        // خانة الملصق: رق خفيف تحت الصورة، وحدها ذهبي لو بالمفضلة
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              color: const Color(0xFFE9D3A4).withValues(alpha: owned ? .9 : .35),
                              border: Border.all(
                                color: _favorites.contains(id) ? AppColors.gold : const Color(0xFF4E331F),
                                width: _favorites.contains(id) ? 2.4 : 1.8,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(5),
                              child: Opacity(
                                opacity: owned ? 1 : .42,
                                child: StickerView(sticker: stickerById(id)!, pop: false),
                              ),
                            ),
                          ),
                        ),
                        if (_favorites.contains(id))
                          const PositionedDirectional(
                            top: -5,
                            end: -3,
                            child: Icon(
                              Icons.star_rounded,
                              color: AppColors.gold,
                              size: 24,
                              shadows: [
                                Shadow(color: gameInk, blurRadius: 3),
                                Shadow(color: gameInk, blurRadius: 1),
                              ],
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

/// حفرة غامقة بحد بني (خلف التبويبات والمحتوى).
class _Inset extends StatelessWidget {
  const _Inset({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: const Color(0xFF140B06).withValues(alpha: .55),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFF0F0805), width: 2),
    ),
    child: ClipRRect(borderRadius: BorderRadius.circular(14), child: child),
  );
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
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 7),
        // لوح خشب، والمختار بحافة ذهبية (مثل أقسام المتجر)
        child: GameHudPlank(
          gold: selected,
          radius: 13,
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 1),
          child: Column(
            children: [
              Opacity(
                opacity: locked ? .5 : 1,
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
                        fontWeight: FontWeight.w800,
                        color: selected ? AppColors.goldLight : const Color(0xFFE7CFA6),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _LockedNote extends StatelessWidget {
  const _LockedNote(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => NotePill(text, icon: const Gfx('lock', size: 16));
}
