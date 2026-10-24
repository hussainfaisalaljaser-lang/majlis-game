import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/common.dart';
import 'tables_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _soon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('قريباً إن شاء الله 🚧')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const _ProfileHeader(),
            const SizedBox(height: 14),
            _DailyBanner(onTap: () => _soon(context)),
            const SizedBox(height: 14),
            _ModeCard(
              emoji: '🕵️',
              title: 'مجلس الخونة',
              subtitle: '٥ إلى ١٠ لاعبين · أدوار مخفية',
              colors: const [Color(0xFFEF4444), Color(0xFF991B1B)],
              badge: '🔥 الأكثر لعباً',
              wide: true,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const TablesScreen()),
              ),
            ),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.25,
              children: [
                _ModeCard(
                  emoji: '⚡',
                  title: 'جولة سريعة',
                  subtitle: '٥ لاعبين · ٨ دقائق',
                  colors: const [Color(0xFF3B82F6), Color(0xFF1E3A8A)],
                  onTap: () => _soon(context),
                ),
                _ModeCard(
                  emoji: '👥',
                  title: 'العب مع أصحابك',
                  subtitle: 'روم خاص بكود',
                  colors: const [Color(0xFF22C55E), Color(0xFF14532D)],
                  onTap: () => _soon(context),
                ),
                _ModeCard(
                  emoji: '🏆',
                  title: 'الدوري',
                  subtitle: 'ترتيب أسبوعي',
                  colors: const [Color(0xFFF59E0B), Color(0xFF92400E)],
                  onTap: () => _soon(context),
                ),
                _ModeCard(
                  emoji: '🤖',
                  title: 'تدريب',
                  subtitle: 'ضد البوت',
                  colors: const [Color(0xFF6B7280), Color(0xFF1F2937)],
                  onTap: () => _soon(context),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppColors.panel,
        indicatorColor: AppColors.gold.withValues(alpha: .2),
        selectedIndex: 0,
        onDestinationSelected: (i) => i == 0 ? null : _soon(context),
        destinations: const [
          NavigationDestination(icon: Text('🏠', style: TextStyle(fontSize: 22)), label: 'الرئيسية'),
          NavigationDestination(icon: Text('🛒', style: TextStyle(fontSize: 22)), label: 'المتجر'),
          NavigationDestination(icon: Text('🏆', style: TextStyle(fontSize: 22)), label: 'الترتيب'),
          NavigationDestination(icon: Text('👤', style: TextStyle(fontSize: 22)), label: 'ملفي'),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const PlayerAvatar(emoji: '😎', frame: AppColors.gold, size: 48),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ضيف', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              Text('مستوى ١', style: TextStyle(color: AppColors.muted, fontSize: 12)),
            ],
          ),
        ),
        const CurrencyPill(icon: '🪙', amount: 12500),
        const SizedBox(width: 6),
        CurrencyPill(icon: '💎', amount: 80, onAdd: () {}),
      ],
    );
  }
}

class _DailyBanner extends StatelessWidget {
  const _DailyBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(colors: [Color(0xFF5B21B6), Color(0xFFC026D3)]),
        ),
        child: const Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('🎁 هدية يومية', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  Text('ادخل ٧ أيام واربح إطار نادر', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
            Text('📅', style: TextStyle(fontSize: 32)),
          ],
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.colors,
    required this.onTap,
    this.badge,
    this.wide = false,
  });

  final String emoji;
  final String title;
  final String subtitle;
  final List<Color> colors;
  final VoidCallback onTap;
  final String? badge;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final texts = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        Text(subtitle, style: const TextStyle(fontSize: 12.5)),
      ],
    );
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: colors),
        ),
        child: Stack(
          children: [
            if (wide)
              Row(
                children: [
                  Expanded(child: Padding(padding: const EdgeInsets.only(top: 18), child: texts)),
                  Text(emoji, style: const TextStyle(fontSize: 44)),
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [Text(emoji, style: const TextStyle(fontSize: 32)), texts],
              ),
            if (badge != null)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    badge!,
                    style: const TextStyle(color: Color(0xFFCC0000), fontSize: 11, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
