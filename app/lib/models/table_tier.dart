/// مستوى الطاولة: كل ما ارتفع زادت رسوم الدخول والجائزة. نفس functions/src/economy.ts.
class TableTier {
  const TableTier({
    required this.id,
    required this.emoji,
    required this.name,
    required this.entryFee,
    this.requiredLevel = 1,
    this.vipOnly = false,
  });

  final String id;
  final String emoji;
  final String name;
  final int entryFee;
  final int requiredLevel;
  final bool vipOnly;

  /// كل اللاعبين يدفعون، والفريق الفايز يتقاسم المجموع.
  int pot(int players) => entryFee * players;
}

const tableTiers = [
  TableTier(id: 'starter', emoji: '🌱', name: 'مبتدئ', entryFee: 100),
  TableTier(id: 'city', emoji: '🏙️', name: 'المدينة', entryFee: 1000),
  TableTier(id: 'palace', emoji: '🏛️', name: 'القصر', entryFee: 5000, requiredLevel: 10),
  TableTier(id: 'kings', emoji: '👑', name: 'الملوك', entryFee: 25000, requiredLevel: 30),
  TableTier(id: 'vip', emoji: '💎', name: 'نخبة VIP', entryFee: 100000, vipOnly: true),
];

TableTier? tierById(String? id) => tableTiers.where((t) => t.id == id).firstOrNull;

const playerCounts = [5, 7, 10];
