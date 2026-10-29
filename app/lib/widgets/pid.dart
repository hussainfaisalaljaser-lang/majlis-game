import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/backend.dart';
import '../theme.dart';
import 'common.dart';
import 'design.dart';
import 'design_game.dart';
import 'ui.dart';

/// درجات الرموز (functions/src/ids.ts): ٠ عادي، ١ مميز، ٢ نادر، ٣ ملحمي، ٤ أسطوري.
const pidTierNames = ['عادي', 'مميز', 'نادر', 'ملحمي', 'أسطوري'];
const _tierColors = <List<Color>>[
  [Color(0xFF8A5E3B), Color(0xFF55341D)],
  [Color(0xFF2DD4BF), Color(0xFF0F766E)],
  [Color(0xFFA78BFA), Color(0xFF5B2FC9)],
  [Color(0xFFFFCF5C), Color(0xFFD97706)],
  [Color(0xFFFF5FA2), Color(0xFF7C3AED)],
];

Color pidTierColor(int tier) => _tierColors[tier.clamp(0, 4)].first;

/// الأرقام بالعربي للعرض (الرمز نفسه يبقى أرقام إنجليزية للبحث والنسخ).
String arabicDigits(String s) => s.replaceAllMapped(RegExp('[0-9]'), (m) => '٠١٢٣٤٥٦٧٨٩'[int.parse(m[0]!)]);

/// اللي يكتبه اللاعب (أرقام عربية أو فارسية أو إنجليزية) → أرقام إنجليزية بس.
String cleanPidInput(String s) => s
    .replaceAllMapped(RegExp('[٠-٩]'), (m) => '${m[0]!.codeUnitAt(0) - 0x0660}')
    .replaceAllMapped(RegExp('[۰-۹]'), (m) => '${m[0]!.codeUnitAt(0) - 0x06F0}')
    .replaceAll(RegExp('[^0-9]'), '');

/// رمز اللاعب في شريط: المميز ملوّن، والملحمي والأسطوري يلمعون. الضغط ينسخه.
class PidBadge extends StatefulWidget {
  const PidBadge({super.key, required this.pid, this.tier = 0, this.size = 14, this.copy = true});

  final String pid;
  final int tier;
  final double size;
  final bool copy;

  @override
  State<PidBadge> createState() => _PidBadgeState();
}

class _PidBadgeState extends State<PidBadge> with SingleTickerProviderStateMixin {
  late final AnimationController? _shine = widget.tier >= 3
      ? (AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))..repeat())
      : null;

  @override
  void dispose() {
    _shine?.dispose();
    super.dispose();
  }

  void _copy() {
    Clipboard.setData(ClipboardData(text: widget.pid));
    HapticFeedback.selectionClick();
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(const SnackBar(content: Text('نسخت الرمز')));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.pid.isEmpty) return const SizedBox.shrink();
    final s = widget.size;
    final colors = _tierColors[widget.tier.clamp(0, 4)];
    final special = widget.tier > 0;
    Widget badge = Container(
      padding: EdgeInsets.fromLTRB(s * .7, s * .22, s * .7, s * .22),
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: colors),
        borderRadius: BorderRadius.circular(s),
        // حد بني غامق مثل أزرار التصميم، والمميز يلمع حواليه
        border: Border.all(color: gameInk, width: 1.7),
        boxShadow: special ? [BoxShadow(color: colors.first.withValues(alpha: .5), blurRadius: s * .8)] : null,
      ),
      // لمعة فوق الشارة
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(s),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white.withValues(alpha: .3), Colors.white.withValues(alpha: .05), Colors.transparent],
          stops: const [0, .42, .43],
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'ID',
            style: TextStyle(
              fontSize: s * .72,
              fontWeight: FontWeight.w900,
              color: const Color(0xFFFFF3DA).withValues(alpha: .7),
            ),
          ),
          SizedBox(width: s * .35),
          Text(
            arabicDigits(widget.pid),
            style: TextStyle(
              fontSize: s,
              fontWeight: FontWeight.w900,
              letterSpacing: s * .08,
              color: const Color(0xFFFFF8E8),
              shadows: [Shadow(color: gameInk.withValues(alpha: .7), offset: Offset(0, s * .08), blurRadius: 1)],
            ),
          ),
          if (widget.copy) ...[
            SizedBox(width: s * .35),
            Icon(Icons.copy_rounded, size: s * .95, color: const Color(0xFFFFF3DA).withValues(alpha: .75)),
          ],
        ],
      ),
    );
    final shine = _shine;
    if (shine != null) {
      badge = AnimatedBuilder(
        animation: shine,
        child: badge,
        builder: (context, child) {
          final x = -3 + 6 * shine.value;
          return ShaderMask(
            blendMode: BlendMode.srcATop,
            shaderCallback: (r) => LinearGradient(
              begin: Alignment(x - .6, -.4),
              end: Alignment(x + .6, .4),
              colors: [Colors.transparent, Colors.white.withValues(alpha: .5), Colors.transparent],
            ).createShader(r),
            child: child,
          );
        },
      );
    }
    return Semantics(
      button: widget.copy,
      label: 'الرمز ${widget.pid}${special ? '، رمز ${pidTierNames[widget.tier.clamp(0, 4)]}' : ''}',
      excludeSemantics: true,
      child: GestureDetector(onTap: widget.copy ? _copy : null, child: badge),
    );
  }
}

/// نافذة الرمز المميز: اكتب الرمز اللي تبيه أو اختار من الاقتراحات، واشتره بالجواهر.
/// [sampleIdeas] و[sampleQuote] للتصوير والاختبار بس (بدل ما نسأل السيرفر).
Future<void> showPremiumIds(BuildContext context, {List<PidQuote>? sampleIdeas, PidQuote? sampleQuote}) =>
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        child: _PremiumIds(sampleIdeas: sampleIdeas, sampleQuote: sampleQuote),
      ),
    );

/// لون الحبر على الرق لكل درجة (أغمق من ألوان الشارة، عشان يبان على الورق).
const _tierInk = [Color(0xFF6B4A2C), Color(0xFF0F766E), Color(0xFF5B2FC9), Color(0xFFB45309), Color(0xFFBE185D)];

/// كلام فاتح على المخمل.
const _cream = Color(0xFFFFF3DA);
const _creamSoft = Color(0xFFE7CFA6);

class _PremiumIds extends StatefulWidget {
  const _PremiumIds({this.sampleIdeas, this.sampleQuote});

  final List<PidQuote>? sampleIdeas;
  final PidQuote? sampleQuote;

  @override
  State<_PremiumIds> createState() => _PremiumIdsState();
}

class _PremiumIdsState extends State<_PremiumIds> {
  final _backend = Backend.instance;
  final _input = TextEditingController();
  late Future<List<PidQuote>> _ideas = widget.sampleIdeas != null
      ? Future.value(widget.sampleIdeas)
      : _backend.suggestIds();
  late PidQuote? _quote = widget.sampleQuote;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _toast(String text) => ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(text)));

  Future<void> _check() async {
    final pid = cleanPidInput(_input.text);
    if (pid.length < 3) return setState(() => _error = 'اكتب من ٣ إلى ٨ أرقام');
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final q = await _backend.quotePid(pid);
      if (mounted) setState(() => _quote = q);
    } on BackendException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _buy(PidQuote q, String current) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: VelvetPanel(
            padding: const EdgeInsets.fromLTRB(28, 20, 28, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GoldTitle('تشتري الرمز ${arabicDigits(q.pid)}؟', size: 22),
                const SizedBox(height: 10),
                Text(
                  'بـ ${arabicNumber(q.price)} جوهرة. رمزك الآن (${arabicDigits(current)}) ينفك وممكن ياخذه غيرك، '
                  'وأصدقاؤك يبقون معك.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(height: 1.6, color: _cream, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: GameButton(
                        label: 'لا',
                        tone: ButtonTone.ghost,
                        height: 44,
                        fontSize: 15,
                        onPressed: () => Navigator.pop(context, false),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GameButton(
                        label: 'اشتره',
                        tone: ButtonTone.green,
                        height: 44,
                        fontSize: 15,
                        onPressed: () => Navigator.pop(context, true),
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
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await _backend.buyPid(q.pid);
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      _toast('مبروك! صار رمزك ${arabicDigits(q.pid)}');
      Navigator.pop(context);
    } on BackendException catch (e) {
      if (mounted) {
        setState(() => _error = e.message);
        _toast(e.message);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // لوحة مخمل بحد ذهبي وزخرفة بالزوايا (مثل نوافذ الشراء بالتصميم)
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 680, maxHeight: MediaQuery.sizeOf(context).height * .94),
      child: VelvetPanel(
        padding: EdgeInsets.zero,
        child: ValueListenableBuilder(
          valueListenable: _backend.profile,
          builder: (context, p, _) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(26, 16, 26, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Gfx('idcard', size: 36),
                    const SizedBox(width: 8),
                    const GoldTitle('رمز مميز', size: 23),
                    const Spacer(),
                    const Text(
                      'رمزك: ',
                      style: TextStyle(color: _creamSoft, fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    PidBadge(pid: p.pid, tier: p.pidTier, size: 13),
                    const SizedBox(width: 10),
                    CurrencyPill(icon: 'gem', amount: p.diamonds),
                    const SizedBox(width: 8),
                    GameRoundButton(
                      size: 38,
                      semantics: 'إغلاق',
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.close_rounded, color: _cream, size: 24),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'رمزك يطلع في ملفك وبطاقتك، والناس يضيفونك فيه. الرموز القصيرة والمكررة أندر وأغلى، وتلمع للكل.',
                  style: TextStyle(color: _creamSoft, fontSize: 12.5, height: 1.5, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _input,
                        keyboardType: TextInputType.number,
                        textDirection: TextDirection.ltr,
                        textAlign: TextAlign.center,
                        maxLength: 8,
                        onSubmitted: (_) => _check(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                          color: _cream,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          hintText: 'اكتب الرمز اللي تبيه',
                          hintStyle: const TextStyle(color: Color(0xFF9C8466), fontSize: 14, letterSpacing: 0),
                          filled: true,
                          fillColor: const Color(0xFF1B0E07).withValues(alpha: .9),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: Color(0xFF8A6038), width: 2),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: Color(0xFF8A6038), width: 2),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: AppColors.gold, width: 2.2),
                          ),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 120,
                      child: GameButton(
                        label: 'شيّك',
                        icon: const Gfx('search', size: 22),
                        height: 46,
                        fontSize: 15,
                        onPressed: _busy ? null : _check,
                      ),
                    ),
                  ],
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: AppColors.traitorLight, fontWeight: FontWeight.w800),
                    ),
                  ),
                if (_quote case final q?) ...[
                  const SizedBox(height: 10),
                  _QuoteRow(quote: q, diamonds: p.diamonds, busy: _busy, onBuy: () => _buy(q, p.pid)),
                ],
                const SizedBox(height: 12),
                const Align(alignment: AlignmentDirectional.centerStart, child: GoldTitle('اقتراحات متاحة', size: 16)),
                const SizedBox(height: 6),
                FutureBuilder(
                  future: _ideas,
                  builder: (context, snap) {
                    if (snap.hasError) {
                      return TextButton(
                        onPressed: () => setState(() => _ideas = _backend.suggestIds()),
                        child: const Text('ما قدرنا نجيب الاقتراحات، جرّب مرة ثانية'),
                      );
                    }
                    if (!snap.hasData) {
                      return const Padding(
                        padding: EdgeInsets.all(12),
                        child: Center(child: CircularProgressIndicator(color: AppColors.gold)),
                      );
                    }
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final q in snap.data!)
                          _IdeaChip(
                            quote: q,
                            selected: _quote?.pid == q.pid,
                            onTap: () => setState(() {
                              _quote = q;
                              _error = null;
                              _input.text = q.pid;
                            }),
                          ),
                        _RefreshChip(onTap: () => setState(() => _ideas = _backend.suggestIds())),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuoteRow extends StatelessWidget {
  const _QuoteRow({required this.quote, required this.diamonds, required this.busy, required this.onBuy});

  final PidQuote quote;
  final int diamonds;
  final bool busy;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final q = quote;
    final enough = diamonds >= q.price;
    // ألوان الحبر على الرق
    final (status, color) = q.mine
        ? ('هذا رمزك', const Color(0xFF8A5A0A))
        : q.available
        ? ('متاح', const Color(0xFF1F6B2A))
        : ('مأخوذ', const Color(0xFFA3261C));
    return ParchmentCard(
      padding: const EdgeInsets.all(10),
      radius: 16,
      child: Row(
        children: [
          PidBadge(pid: q.pid, tier: q.tier, size: 18, copy: false),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'رمز ${pidTierNames[q.tier.clamp(0, 4)]}',
                style: TextStyle(color: _tierInk[q.tier.clamp(0, 4)], fontWeight: FontWeight.w800, fontSize: 14),
              ),
              Text(
                status,
                style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 13),
              ),
            ],
          ),
          const Spacer(),
          if (q.available && !q.mine)
            SizedBox(
              width: 210,
              child: GameButton(
                label: enough ? 'اشتره بـ ${arabicNumber(q.price)}' : 'جواهرك ما تكفي (${arabicNumber(q.price)})',
                tone: ButtonTone.green,
                icon: const Gfx('gem', size: 22),
                height: 46,
                fontSize: enough ? 15 : 12.5,
                onPressed: busy || !enough ? null : onBuy,
              ),
            ),
        ],
      ),
    );
  }
}

class _IdeaChip extends StatelessWidget {
  const _IdeaChip({required this.quote, required this.selected, required this.onTap});

  final PidQuote quote;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'الرمز ${quote.pid} بـ ${quote.price} جوهرة',
    excludeSemantics: true,
    child: GestureDetector(
      onTap: onTap,
      // لوح خشب، والمختار بحافة ذهبية
      child: PlankBar(
        gold: selected,
        radius: 13,
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PidBadge(pid: quote.pid, tier: quote.tier, size: 13, copy: false),
            const SizedBox(height: 3),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Gfx('gem', size: 15),
                const SizedBox(width: 3),
                Text(
                  arabicNumber(quote.price),
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: _cream),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

/// «غيرها»: لوح خشب صغير بأيقونة التحديث.
class _RefreshChip extends StatelessWidget {
  const _RefreshChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'غيرها',
    excludeSemantics: true,
    child: GestureDetector(
      onTap: onTap,
      child: const PlankBar(
        radius: 13,
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.refresh_rounded, size: 18, color: _cream),
            SizedBox(width: 4),
            Text(
              'غيرها',
              style: TextStyle(color: _cream, fontWeight: FontWeight.w800, fontSize: 13),
            ),
          ],
        ),
      ),
    ),
  );
}
