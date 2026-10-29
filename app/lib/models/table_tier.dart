/// مستوى الطاولة: كل ما ارتفع زادت رسوم الدخول والجائزة. نفس functions/src/economy.ts.
class TableTier {
  const TableTier({
    required this.id,
    required this.icon,
    required this.name,
    required this.entryFee,
    this.requiredLevel = 1,
    this.vipOnly = false,
  });

  final String id;

  /// أيقونة الطاولة (assets/icons/gfx_tier_*.png).
  final String icon;
  final String name;
  final int entryFee;
  final int requiredLevel;
  final bool vipOnly;

  /// كل اللاعبين يدفعون، والفريق الفايز يتقاسم المجموع.
  int pot(int players) => entryFee * players;
}

const tableTiers = [
  TableTier(id: 'starter', icon: 'tier_starter', name: 'مبتدئ', entryFee: 100),
  TableTier(id: 'city', icon: 'tier_city', name: 'المدينة', entryFee: 1000),
  TableTier(id: 'palace', icon: 'tier_palace', name: 'القصر', entryFee: 5000, requiredLevel: 10),
  TableTier(id: 'kings', icon: 'tier_kings', name: 'الملوك', entryFee: 25000, requiredLevel: 30),
  TableTier(id: 'vip', icon: 'tier_vip', name: 'النخبة', entryFee: 100000, vipOnly: true),
];

TableTier? tierById(String? id) => tableTiers.where((t) => t.id == id).firstOrNull;

const playerCounts = [5, 7, 10];
