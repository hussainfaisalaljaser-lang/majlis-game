import 'package:flutter/material.dart';

import '../services/backend.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/daily_reward.dart';
import 'profile_screen.dart';
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
            _DailyBanner(onTap: () => showDailyReward(context)),
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
        onDestinationSelected: (i) => switch (i) {
          0 => null,
          3 => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileScreen())),
          _ => _soon(context),
        },
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
    return ValueListenableBuilder(
      valueListenable: Backend.instance.profile,
      builder: (context, p, _) => Row(
        children: [
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(30),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileScreen())),
              child: Row(
                children: [
                  PlayerAvatar(emoji: p.avatar, frame: AppColors.gold, size: 48),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                        Text('⭐ مستوى ${arabicNumber(p.level)}', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          CurrencyPill(icon: '🪙', amount: p.coins),
          const SizedBox(width: 6),
          CurrencyPill(icon: '💎', amount: p.diamonds),
        ],
      ),
    );
  }
}

class _DailyBanner extends StatelessWidget {
  const _DailyBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Backend.instance.profile,
      builder: (context, p, _) {
        final available = p.dailyAvailable && Backend.instance.isReady;
        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(colors: [Color(0xFF5B21B6), Color(0xFFC026D3)]),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        available ? '🎁 هديتك اليومية جاهزة!' : '🎁 الهدية اليومية',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                      Text(
                        available
                            ? 'اليوم ${arabicNumber(p.nextDailyDay)} من ٧ · اضغط واستلم'
                            : 'استلمت هدية اليوم، تعال بكرة 😉',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Text('📅', style: TextStyle(fontSize: 32)),
                    if (available)
                      const Positioned(
                        top: -2,
                        left: -2,
                        child: CircleAvatar(radius: 6, backgroundColor: AppColors.traitor),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
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
