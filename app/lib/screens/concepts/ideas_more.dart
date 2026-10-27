part of 'ideas.dart';

// ───────── ١١ أدوار جديدة

const _newRoles = [
  ('القاضي', 'مرة وحدة يلغي نتيجة تصويت', 'scales', [Color(0xFFFFE6A3), Color(0xFF7A4E00)]),
  ('الشيخ', 'صوته بصوتين بالتصويت', 'ballot', [Color(0xFFA7F3D0), Color(0xFF065F46)]),
  ('الجاسوس', 'مرة وحدة يشوف أول كرت بالكومة', 'eye', [Color(0xFFDDD6FE), Color(0xFF3B0764)]),
];

Widget _roles(double t) => Stack(
  clipBehavior: Clip.none,
  children: [
    const Positioned.fill(child: MajlisRoom()),
    dim(.62),
    for (final (i, (name, power, icon, colors)) in _newRoles.indexed) ...[
      at(
        Offset(160 + i * 240.0, 200),
        180,
        258,
        _Flip(
          angle: (1 - seg(t, .35 + i * 1.5, 1.05 + i * 1.5, Curves.easeInOutBack)) * math.pi,
          front: _NewRoleCard(name: name, power: power, icon: icon, colors: colors, double: i == 1),
          back: const _NewRoleBack(),
        ),
      ),
      at(Offset(160 + i * 240.0, 386), 230, 76, _roleDemo(i, t - (1.25 + i * 1.5))),
    ],
  ],
);

/// وش يسوي الدور (بعد ما تنقلب بطاقته).
Widget _roleDemo(int i, double t) {
  if (t < 0) return const SizedBox.shrink();
  switch (i) {
    case 0:
      final stamp = seg(t, .7, .95, Curves.easeInCubic);
      return Opacity(
        opacity: seg(t, 0, .3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Opacity(
              opacity: 1 - .5 * stamp,
              child: const _Chip(
                'الحكومة انتخبت',
                color: Color(0xFF6DE3A0),
                border: AppColors.green,
                size: 15,
                icon: 'check',
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 36,
              child: stamp > 0
                  ? Transform.rotate(
                      angle: -.2,
                      child: Transform.scale(
                        scale: 1 + (1 - stamp) * 1.8,
                        child: Opacity(
                          opacity: stamp,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: AppColors.traitor.withValues(alpha: .3),
                              border: Border.all(color: AppColors.traitorLight, width: 2.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'ملغية',
                              style: TextStyle(
                                fontFamily: kufi,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: AppColors.traitorLight,
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      );
    case 1:
      final badge = Curves.elasticOut.transform(seg(t, .5, 1.1));
      return Opacity(
        opacity: seg(t, 0, .3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 60,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF6DE3A0), Color(0xFF1E8E52)],
                ),
                border: Border.all(color: Colors.white70, width: 2),
              ),
              child: const Text(
                'نعم',
                style: TextStyle(fontFamily: kufi, fontWeight: FontWeight.w700, color: Color(0xFF062814)),
              ),
            ),
            const SizedBox(width: 8),
            Transform.scale(scale: badge, child: const GoldText('×٢', size: 34)),
          ],
        ),
      );
    default:
      final open = seg(t, .3, .6) * (1 - seg(t, 1.6, 1.9));
      return Opacity(
        opacity: seg(t, 0, .3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 44,
              height: 60,
              child: _Flip(
                angle: (1 - open) * math.pi,
                front: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: AppColors.parchment,
                    border: Border.all(color: AppColors.traitorDark, width: 2),
                  ),
                  child: const Center(child: Seal(loyal: false, size: 32)),
                ),
                back: const _MiniBack(),
              ),
            ),
            const SizedBox(width: 10),
            const Gfx('eye', size: 34),
          ],
        ),
      );
  }
}

class _NewRoleCard extends StatelessWidget {
  const _NewRoleCard({
    required this.name,
    required this.power,
    required this.icon,
    required this.colors,
    this.double = false,
  });

  final String name, power, icon;
  final List<Color> colors;
  final bool double;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFF8EBD0), AppColors.parchmentDark],
      ),
      border: Border.all(color: AppColors.goldDark, width: 3),
      boxShadow: [BoxShadow(color: colors[0].withValues(alpha: .45), blurRadius: 30, spreadRadius: 2)],
    ),
    child: Column(
      children: [
        Container(
          margin: const EdgeInsets.all(8),
          height: 140,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: RadialGradient(radius: .9, colors: colors),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Gfx(icon, size: 92),
              if (double) const Positioned(right: 18, bottom: 14, child: GoldText('×٢', size: 26)),
            ],
          ),
        ),
        Text(
          name,
          style: TextStyle(fontFamily: kufi, fontSize: 28, fontWeight: FontWeight.w700, color: colors[1]),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            power,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.ink, fontSize: 13, height: 1.4, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    ),
  );
}

class _NewRoleBack extends StatelessWidget {
  const _NewRoleBack();

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF4A2775), Color(0xFF140B29)],
      ),
      border: Border.all(color: AppColors.gold, width: 3),
    ),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.asset('assets/logo.png', width: 84, height: 84),
          ),
          const SizedBox(height: 10),
          const Text(
            'دور جديد',
            style: TextStyle(fontFamily: kufi, fontSize: 20, color: AppColors.goldLight),
          ),
        ],
      ),
    ),
  );
}

// ───────── ١٢ تتفرج على أصحابك

const _watched = [
  ('pilot', 'سلمان'),
  ('emir', 'عبدالله'),
  ('sultana', 'العنود'),
  ('wolf', 'تركي'),
  ('falconer', 'بدر'),
  ('lady_gold', 'مها'),
];

Widget _spectate(double t) {
  final b = seg(t, 2.3, 2.8);
  const watch = Offset(232, 166);
  return Stack(
    clipBehavior: Clip.none,
    children: [
      if (b < 1)
        Positioned.fill(
          child: Opacity(
            opacity: 1 - b,
            child: NightBackground(
              child: Center(
                child: SizedBox(
                  width: 560,
                  child: _Panel(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const _Title('أصحابك', size: 20),
                        const SizedBox(height: 6),
                        _FriendRow(
                          avatar: 'pilot',
                          name: 'سلمان',
                          status: 'يلعب الحين · الجولة ٤',
                          online: true,
                          action: _Btn(
                            'تفرّج',
                            colors: const [Color(0xFFA48BFF), Color(0xFF4B2DC2)],
                            fg: Colors.white,
                            height: 36,
                            size: 14,
                            icon: 'eye',
                            press: bump(t, 1.75, 1.97),
                          ),
                        ),
                        const _FriendRow(
                          avatar: 'lady_gold',
                          name: 'مها',
                          status: 'متصلة',
                          online: true,
                          action: _Btn('ادعُ', height: 36, size: 14, icon: 'invite'),
                        ),
                        const _FriendRow(avatar: 'falconer', name: 'بدر', status: 'آخر ظهور: أمس', online: false),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      if (b > 0)
        Positioned.fill(
          child: Opacity(
            opacity: b,
            child: _Table(
              venue: Venue.kings,
              people: _watched,
              over: (seats) => [
                for (final (i, c) in seats.indexed)
                  if (t > 3.9)
                    at(
                      c + Offset(c.dx <= 401 ? 52 : -52, -2),
                      40,
                      56,
                      Transform.scale(
                        scale: seg(t, 3.9, 4.2, Curves.easeOutBack),
                        child: _Flip(
                          angle: (1 - seg(t, 4.7, 5.1, Curves.easeInOut)) * math.pi,
                          front: _VoteMini(yes: i != 3),
                          back: const _MiniBack(),
                        ),
                      ),
                    ),
              ],
            ),
          ),
        ),
      if (b > 0) ...[
        Positioned(
          top: 42,
          right: 16,
          child: Opacity(
            opacity: b,
            child: const _Chip('تتفرج على لعبة سلمان', icon: 'eye', size: 14),
          ),
        ),
        Positioned(
          top: 44,
          left: 16,
          child: Opacity(
            opacity: b,
            child: const _Chip('٣ يتفرجون', color: AppColors.text, border: AppColors.muted, size: 12),
          ),
        ),
        Positioned(
          bottom: 4,
          left: 0,
          right: 0,
          child: Opacity(
            opacity: b,
            child: const Center(
              child: _Chip(
                'أنت متفرج: تشوف اللعب، بدون ما تشوف الأدوار',
                color: AppColors.text,
                border: AppColors.muted,
                size: 12,
              ),
            ),
          ),
        ),
      ],
      ?finger(t, [(1.0, const Offset(560, 470)), (1.7, watch)], [1.75]),
    ],
  );
}

class _VoteMini extends StatelessWidget {
  const _VoteMini({required this.yes});

  final bool yes;

  @override
  Widget build(BuildContext context) => Container(
    alignment: Alignment.center,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(8),
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: yes ? const [Color(0xFF6DE3A0), Color(0xFF1E8E52)] : const [Color(0xFFFF8C98), Color(0xFFA3172D)],
      ),
      border: Border.all(color: Colors.white70, width: 2),
    ),
    child: Text(
      yes ? 'نعم' : 'لا',
      style: TextStyle(
        fontFamily: kufi,
        fontWeight: FontWeight.w700,
        color: yes ? const Color(0xFF062814) : Colors.white,
      ),
    ),
  );
}

class _FriendRow extends StatelessWidget {
  const _FriendRow({required this.avatar, required this.name, required this.status, required this.online, this.action});

  final String avatar, name, status;
  final bool online;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(vertical: 4),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(color: Colors.white.withValues(alpha: .05), borderRadius: BorderRadius.circular(14)),
    child: Row(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            PlayerAvatar(avatar: avatar, size: 46),
            Positioned(
              bottom: 0,
              left: 0,
              child: Container(
                width: 13,
                height: 13,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: online ? AppColors.green : AppColors.muted,
                  border: Border.all(color: AppColors.panel, width: 2),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              Text(status, style: TextStyle(fontSize: 12, color: online ? AppColors.green : AppColors.muted)),
            ],
          ),
        ),
        ?action,
      ],
    ),
  );
}

// ───────── ١٣ بطولة الأسبوع

const _bracket = ['emir', 'cool', 'pearl', 'wolf', 'pilot', 'desert', 'sultana', 'falconer'];

Widget _tournament(double t) {
  // من اليمين لليسار: الدور الأول، نص النهائي، النهائي، البطل.
  const xs = [650.0, 470.0, 290.0, 105.0];
  double y1(int k) => 104 + k * 40.0;
  double y2(int k) => 124 + k * 80.0;
  double y3(int k) => 164 + k * 160.0;
  const y4 = 244.0;
  final r1 = seg(t, 1.2, 2.0, Curves.easeInOutCubic);
  final r2 = seg(t, 2.5, 3.3, Curves.easeInOutCubic);
  final r3 = seg(t, 3.8, 4.6, Curves.easeInOutCubic);
  // الفايزين: من كل اثنين واحد.
  const w1 = [0, 3, 4, 7], w2 = [0, 7], w3 = 0;
  final champ = seg(t, 4.7, 5.3, Curves.elasticOut);
  return NightBackground(
    glow: const Color(0xFF6B4A12),
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(child: CustomPaint(painter: _BracketLines(r1, r2, r3))),
        for (final (i, label) in const ['الدور الأول', 'نص النهائي', 'النهائي', 'البطل'].indexed)
          at(Offset(xs[i], 72), 120, 22, _Chip(label, size: 12)),
        for (var k = 0; k < 8; k++)
          at(
            Offset(xs[0], y1(k)),
            40,
            40,
            ColorFiltered(
              colorFilter: ColorFilter.matrix(greyMatrix(w1.contains(k) ? 0 : .8 * r1)),
              child: PlayerAvatar(avatar: _bracket[k], size: 36),
            ),
          ),
        for (final (j, k) in w1.indexed)
          if (r1 > 0)
            at(
              Offset.lerp(Offset(xs[0], y1(k)), Offset(xs[1], y2(j)), r1)!,
              48,
              48,
              ColorFiltered(
                colorFilter: ColorFilter.matrix(greyMatrix(w2.contains(k) ? 0 : .8 * r2)),
                child: PlayerAvatar(avatar: _bracket[k], size: 44, frame: AppColors.gold),
              ),
            ),
        for (final (j, k) in w2.indexed)
          if (r2 > 0)
            at(
              Offset.lerp(Offset(xs[1], y2(w1.indexOf(k))), Offset(xs[2], y3(j)), r2)!,
              56,
              56,
              ColorFiltered(
                colorFilter: ColorFilter.matrix(greyMatrix(k == w3 ? 0 : .8 * r3)),
                child: PlayerAvatar(avatar: _bracket[k], size: 52, frame: AppColors.gold),
              ),
            ),
        if (r3 > 0)
          at(
            Offset.lerp(Offset(xs[2], y3(0)), Offset(xs[3], y4), r3)!,
            92,
            92,
            Transform.scale(
              scale: 1 + .15 * champ,
              child: PlayerAvatar(avatar: _bracket[w3], size: 76, style: frameStyle('frame_champ1')),
            ),
          ),
        if (t > 4.7) ...[
          at(Offset(xs[3], y4 - 66), 56, 56, Transform.scale(scale: champ, child: const Gfx('trophy', size: 52))),
          at(
            Offset(xs[3], y4 + 66),
            160,
            30,
            Transform.scale(scale: champ, child: const GoldText('البطل: أنت!', size: 20)),
          ),
          Positioned.fill(
            child: IgnorePointer(child: CustomPaint(painter: _Confetti(t - 4.7))),
          ),
        ],
        Positioned(
          left: 16,
          bottom: 12,
          child: _Panel(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                const Gfx('coin', size: 26),
                const SizedBox(width: 4),
                const Text(
                  '٥٠٬٠٠٠',
                  style: TextStyle(fontFamily: kufi, fontSize: 18, color: AppColors.gold, fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 10),
                const Text('وإطار البطل', style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(width: 8),
                PlayerAvatar(avatar: 'cool', size: 34, style: frameStyle('frame_champ1')),
              ],
            ),
          ),
        ),
        const Positioned(
          right: 16,
          bottom: 14,
          child: _Chip(
            'تبدأ الجمعة ٩ مساءً · رسوم الدخول ٥٠٠',
            color: AppColors.text,
            border: AppColors.muted,
            size: 12,
          ),
        ),
      ],
    ),
  );
}

class _BracketLines extends CustomPainter {
  _BracketLines(this.r1, this.r2, this.r3);

  final double r1, r2, r3;

  @override
  void paint(Canvas canvas, Size size) {
    Paint line(double on) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 + on
      ..color = Color.lerp(AppColors.gold.withValues(alpha: .25), AppColors.goldLight, on)!;
    void elbow(Offset a, Offset b, double on) {
      final mid = (a.dx + b.dx) / 2;
      canvas.drawPath(
        Path()
          ..moveTo(a.dx, a.dy)
          ..lineTo(mid, a.dy)
          ..lineTo(mid, b.dy)
          ..lineTo(b.dx, b.dy),
        line(on),
      );
    }

    for (var k = 0; k < 8; k++) {
      elbow(Offset(630, 104 + k * 40.0), Offset(494, 124 + (k ~/ 2) * 80.0), [0, 3, 4, 7].contains(k) ? r1 : 0);
    }
    for (var k = 0; k < 4; k++) {
      elbow(Offset(446, 124 + k * 80.0), Offset(318, 164 + (k ~/ 2) * 160.0), k == 0 || k == 3 ? r2 : 0);
    }
    for (var k = 0; k < 2; k++) {
      elbow(Offset(262, 164 + k * 160.0), const Offset(151, 244), k == 0 ? r3 : 0);
    }
  }

  @override
  bool shouldRepaint(_BracketLines old) => old.r1 != r1 || old.r2 != r2 || old.r3 != r3;
}

// ───────── ١٤ نهاية الأسبوع: ذهب مضاعف

Widget _weekend(double t) {
  final coins = countTo(t, 4.3, 5.2, 12500, 12700);
  final secs = 10 - t.floor();
  final result = seg(t, 2.3, 2.7, Curves.easeOutBack);
  final stamp = seg(t, 3.0, 3.25, Curves.easeInCubic);
  final reward = t < 3.25 ? 100 : countTo(t, 3.25, 3.9, 100, 200);
  const pill = Offset(80, 56);
  return NightBackground(
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: 44,
          left: 20,
          child: Transform.scale(
            scale: 1 + .15 * bump(t, 4.3, 5.4),
            child: CurrencyPill(icon: 'coin', amount: coins),
          ),
        ),
        at(
          const Offset(400, 150),
          620,
          150,
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFFB45309), Color(0xFF7C2D12)]),
                      border: Border.all(color: AppColors.gold, width: 3),
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                ),
                for (var k = 0; k < 14; k++)
                  Positioned(
                    left: rnd(k, 1) * 600,
                    top: -20 + ((t * (40 + rnd(k, 2) * 50) + rnd(k, 3) * 170) % 190),
                    child: Opacity(opacity: .5, child: Gfx('coin', size: 14 + rnd(k, 4) * 10)),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: Row(
                    children: [
                      Transform.scale(
                        scale: 1 + .08 * math.sin(t * 5),
                        child: Container(
                          width: 104,
                          height: 104,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const RadialGradient(colors: [Color(0xFFFFE08A), Color(0xFFD48B12)]),
                            boxShadow: [BoxShadow(color: AppColors.goldLight.withValues(alpha: .6), blurRadius: 24)],
                          ),
                          child: const Text(
                            '×٢',
                            style: TextStyle(
                              fontFamily: kufi,
                              fontSize: 44,
                              fontWeight: FontWeight.w700,
                              color: AppColors.goldInk,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'نهاية الأسبوع: ذهب مضاعف',
                              style: TextStyle(fontFamily: kufi, fontSize: 24, fontWeight: FontWeight.w700),
                            ),
                            const Text(
                              'كل لعبة تفوز فيها جائزتها ×٢',
                              style: TextStyle(fontSize: 14, color: Color(0xFFFFE7C2)),
                            ),
                            const SizedBox(height: 6),
                            _Chip('ينتهي بعد: يوم و ٠٤:٢٣:${arabicNumber(secs).padLeft(2, '٠')}', size: 13),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (result > 0)
          at(
            const Offset(400, 330),
            360,
            150,
            Transform.scale(
              scale: result,
              child: _Panel(
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'جائزة اللعبة',
                          style: TextStyle(fontFamily: kufi, fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Gfx('coin', size: 40),
                            const SizedBox(width: 6),
                            GoldText('+${arabicNumber(reward)}', size: 40),
                          ],
                        ),
                      ],
                    ),
                    if (stamp > 0)
                      Positioned(
                        left: 24,
                        top: 4,
                        child: Transform.rotate(
                          angle: -.25,
                          child: Transform.scale(
                            scale: 1 + (1 - stamp) * 2,
                            child: Opacity(
                              opacity: stamp,
                              child: const Text(
                                '×٢',
                                style: TextStyle(
                                  fontFamily: kufi,
                                  fontSize: 40,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFFF8A3C),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ...flyingIcons(t, 4.2, const Offset(400, 330), pill, count: 12),
      ],
    ),
  );
}

// ───────── ١٥ الدواوين

const _clanRows = [
  ('ديوان الذيب', 15400, Color(0xFF64748B)),
  ('ديوان النخلة', 11800, Color(0xFF16A34A)),
  ('ديوان البحر', 9300, Color(0xFF0EA5E9)),
  ('ديوان الصقور', 8200, Color(0xFF7C3AED)),
  ('ديوان القمر', 7100, Color(0xFFF59E0B)),
];

Widget _clans(double t) {
  final climb = seg(t, 2.6, 3.6, Curves.easeInOutCubic);
  final goal = .4 + .45 * seg(t, 3.7, 5.0, Curves.easeOut);
  final chest = Curves.elasticOut.transform(seg(t, 5.1, 5.8));
  // الصقور يطلعون من الرابع للثاني، والنخلة والبحر ينزلون.
  double slot(int i) => switch (i) {
    1 || 2 => i + climb,
    3 => 3 - 2 * climb,
    _ => i.toDouble(),
  };
  return NightBackground(
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        // الديوان (يمين)
        Positioned(
          right: 16,
          top: 42,
          width: 372,
          height: 396,
          child: _Panel(
            child: Column(
              children: [
                Row(
                  children: [
                    CustomPaint(
                      size: const Size(96, 112),
                      painter: _Crest(const Color(0xFF7C3AED)),
                      child: const SizedBox(
                        width: 96,
                        height: 112,
                        child: Center(child: PlayerAvatar(avatar: 'falcon_bird', size: 58)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GoldText('ديوان الصقور', size: 24, align: TextAlign.start),
                          SizedBox(height: 4),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              _Chip('المستوى ٧', size: 12),
                              _Chip('٢٤ من ٣٠ عضو', color: AppColors.text, border: AppColors.muted, size: 12),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 4,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: .9,
                    children: [
                      for (final (i, (a, n)) in const [
                        ('emir', 'أنت'),
                        ('falconer', 'بدر'),
                        ('pilot', 'فيصل'),
                        ('sultana', 'العنود'),
                        ('wolf', 'تركي'),
                        ('lady_gold', 'مها'),
                        ('cool', 'سعود'),
                        ('pearl', 'نورة'),
                      ].indexed)
                        Column(
                          children: [
                            PlayerAvatar(avatar: a, size: 44, frame: i == 0 ? AppColors.gold : null),
                            Text(n, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
                            if (i < 2)
                              Text(
                                i == 0 ? 'شيخ الديوان' : 'نائب',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.gold,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // الترتيب (يسار)
        Positioned(
          left: 16,
          top: 42,
          width: 384,
          height: 396,
          child: _Panel(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Text(
                    'ترتيب الدواوين هالأسبوع',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: kufi, fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
                for (final (i, (name, points, color)) in _clanRows.indexed)
                  Positioned(
                    top: 34 + slot(i) * 48,
                    left: 0,
                    right: 0,
                    height: 42,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: i == 3 ? AppColors.gold.withValues(alpha: .2) : Colors.white.withValues(alpha: .05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: i == 3 ? AppColors.gold : Colors.transparent, width: 1.5),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 24,
                            child: Text(
                              arabicNumber(slot(i).round() + 1),
                              style: const TextStyle(
                                fontFamily: kufi,
                                fontWeight: FontWeight.w700,
                                color: AppColors.gold,
                              ),
                            ),
                          ),
                          CustomPaint(size: const Size(24, 28), painter: _Crest(color)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(name, style: const TextStyle(fontWeight: FontWeight.w800)),
                          ),
                          Text(
                            arabicNumber(i == 3 ? countTo(t, 2.6, 3.6, 8200, 12900) : points),
                            style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.goldLight),
                          ),
                        ],
                      ),
                    ),
                  ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'هدف الأسبوع: ١٥٬٠٠٠ نقطة',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: goal,
                                minHeight: 10,
                                backgroundColor: Colors.black38,
                                color: AppColors.gold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Transform.scale(scale: .6 + .4 * chest, child: const Gfx('gift', size: 46)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

/// شعار ديوان: درع بحافة ذهبية.
class _Crest extends CustomPainter {
  _Crest(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final shield = Path()
      ..moveTo(w * .5, 0)
      ..lineTo(w, h * .14)
      ..lineTo(w * .94, h * .6)
      ..quadraticBezierTo(w * .8, h * .88, w * .5, h)
      ..quadraticBezierTo(w * .2, h * .88, w * .06, h * .6)
      ..lineTo(0, h * .14)
      ..close();
    canvas.drawPath(
      shield,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.lerp(color, Colors.white, .25)!, Color.lerp(color, Colors.black, .45)!],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      shield,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.5, w * .05)
        ..color = AppColors.gold,
    );
  }

  @override
  bool shouldRepaint(_Crest old) => old.color != color;
}

// ───────── ١٦ صوت مباشر

/// مين يتكلم ومتى (رقم المقعد، من، لين).
const _talks = [(4, .4, 2.0), (5, 2.0, 3.2), (0, 3.6, 5.6), (1, 5.6, 6.5)];

Widget _voice(double t) {
  const muted = 3;
  final talking = {for (final (i, a, b) in _talks) i: t >= a && t < b};
  const mic = Offset(750, 410);
  final hold = t >= 3.4 && t < 5.6;
  return _Table(
    venue: Venue.city,
    frameOf: (i) => talking[i] ?? false ? AppColors.green : null,
    over: (seats) => [
      for (final (i, c) in seats.indexed) ...[
        if (talking[i] ?? false) ...[
          at(
            c,
            76 + 8 * math.sin(t * 9).abs(),
            76 + 8 * math.sin(t * 9).abs(),
            IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.green, width: 3),
                  boxShadow: [BoxShadow(color: AppColors.green.withValues(alpha: .5), blurRadius: 16)],
                ),
              ),
            ),
          ),
          at(c + const Offset(0, -46), 40, 18, _Bars(t: t, seed: i)),
        ],
        at(
          c + const Offset(-26, 22),
          22,
          22,
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xE60B0818),
              border: Border.all(
                color: i == muted ? AppColors.traitor : (talking[i] ?? false ? AppColors.green : AppColors.muted),
                width: 1.5,
              ),
            ),
            child: Icon(
              i == muted ? Icons.mic_off : Icons.mic,
              size: 13,
              color: i == muted ? AppColors.traitorLight : AppColors.text,
            ),
          ),
        ),
      ],
      at(
        mic,
        64,
        64,
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: hold
                  ? const [Color(0xFF6DE3A0), Color(0xFF1E8E52)]
                  : const [Color(0xFF3B2F6B), Color(0xFF1C1638)],
            ),
            border: Border.all(color: hold ? Colors.white : AppColors.gold, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: (hold ? AppColors.green : Colors.black).withValues(alpha: .6),
                blurRadius: hold ? 22 : 8,
              ),
            ],
          ),
          child: const Icon(Icons.mic, color: Colors.white, size: 32),
        ),
      ),
      at(mic + const Offset(-92, 0), 110, 24, const Center(child: _Chip('اضغط وتكلم', size: 12))),
      const Positioned(top: 42, right: 16, child: _Chip('صوت مباشر · الروم الخاص', size: 13)),
      ?finger(t, [(2.9, const Offset(640, 470)), (3.35, mic)], [3.4], hold: 2.2),
    ],
  );
}

/// خطوط الصوت تطلع وتنزل.
class _Bars extends StatelessWidget {
  const _Bars({required this.t, required this.seed});

  final double t;
  final int seed;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      for (var k = 0; k < 5; k++)
        Container(
          width: 4,
          height: 4 + 12 * (.5 + .5 * math.sin(t * (9 + k * 2.3) + seed + k)).abs(),
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(color: AppColors.green, borderRadius: BorderRadius.circular(2)),
        ),
    ],
  );
}

// ───────── ١٧ الاشتراك الشهري

const _perks = [
  'إطار VIP متحرك',
  'خبرة ×٢ بكل لعبة',
  'اسمك ذهبي على الطاولة',
  '٥٠ جوهرة كل أسبوع',
  'تدخل طاولات نخبة VIP',
];

Widget _member(double t) => Stack(
  clipBehavior: Clip.none,
  children: [
    const Positioned.fill(child: MajlisRoom(venue: Venue.vip)),
    dim(.35),
    Positioned(
      right: 26,
      top: 46,
      width: 370,
      height: 384,
      child: _Panel(
        colors: const [Color(0xF5100C06), Color(0xF5241A0A)],
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(child: GoldText('عضوية المجلس الذهبية', size: 24)),
            const SizedBox(height: 8),
            for (final (k, perk) in _perks.indexed)
              Opacity(
                opacity: seg(t, .4 + k * .35, .7 + k * .35),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Transform.scale(
                        scale: Curves.elasticOut.transform(seg(t, .4 + k * .35, 1.0 + k * .35)),
                        child: const Gfx('check', size: 22),
                      ),
                      const SizedBox(width: 8),
                      Text(perk, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                    ],
                  ),
                ),
              ),
            const Spacer(),
            const Row(
              children: [
                Text(
                  '٤٫٩٩ \$',
                  style: TextStyle(fontFamily: kufi, fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.gold),
                ),
                SizedBox(width: 6),
                Text('بالشهر', style: TextStyle(fontWeight: FontWeight.w800)),
                Spacer(),
                Text('تقدر تلغيه بأي وقت', style: TextStyle(fontSize: 11, color: AppColors.muted)),
              ],
            ),
            const SizedBox(height: 8),
            Transform.scale(
              scale: 1 + .03 * math.sin(t * 5),
              child: const SizedBox(width: double.infinity, child: _Btn('اشترك', height: 46, size: 20)),
            ),
          ],
        ),
      ),
    ),
    at(
      const Offset(210, 220),
      260,
      300,
      Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              PlayerAvatar(avatar: 'emir', size: 140, style: frameStyle('frame_blackgold')),
              for (var k = 0; k < 6; k++)
                Positioned(
                  left: 70 + math.cos(t * .8 + k) * 96 - 6,
                  top: 70 + math.sin(t * .8 + k) * 96 - 6,
                  child: CustomPaint(size: const Size(12, 12), painter: _Star()),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const GoldText('أبو فهد', size: 26),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  gradient: const LinearGradient(colors: [Color(0xFFFDE68A), Color(0xFFB87A12)]),
                ),
                child: const Text(
                  'VIP',
                  style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.goldInk),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Transform.translate(
            offset: Offset(0, -4 * math.sin(t * 2)),
            child: const _Chip('خبرة ×٢', size: 13, icon: 'xp'),
          ),
        ],
      ),
    ),
  ],
);

// ───────── ١٨ إعلان اختياري

Widget _ad(double t) {
  final ad = seg(t, 1.1, 1.3) * (1 - seg(t, 3.9, 4.1));
  final coins = countTo(t, 4.2, 5.1, 12500, 12550);
  final left = t < 1.2 ? 3 : 2;
  const pill = Offset(80, 56);
  const button = Offset(400, 268);
  return NightBackground(
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: 44,
          left: 20,
          child: Transform.scale(
            scale: 1 + .15 * bump(t, 4.2, 5.3),
            child: CurrencyPill(icon: 'coin', amount: coins),
          ),
        ),
        at(
          const Offset(400, 226),
          440,
          176,
          _Panel(
            child: Column(
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [Gfx('gift', size: 34), SizedBox(width: 6), _Title('هدية سريعة', size: 20)],
                ),
                const Text('شاهد إعلان قصير وخذ ٥٠ ذهب', style: TextStyle(fontWeight: FontWeight.w800)),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _Btn(
                      'شاهد إعلان',
                      colors: const [Color(0xFF6DE3A0), Color(0xFF1E8E52)],
                      fg: const Color(0xFF062814),
                      press: bump(t, .9, 1.1),
                      height: 40,
                      size: 16,
                    ),
                    const SizedBox(width: 10),
                    _Chip(
                      'باقي لك ${arabicNumber(left)} اليوم',
                      color: AppColors.text,
                      border: AppColors.muted,
                      size: 12,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (ad > 0)
          Positioned.fill(
            child: Opacity(
              opacity: ad,
              child: ColoredBox(
                color: const Color(0xFF07070C),
                child: Stack(
                  children: [
                    const Positioned(
                      top: 44,
                      right: 20,
                      child: _Chip('إعلان', color: AppColors.text, border: AppColors.muted),
                    ),
                    Center(
                      child: Container(
                        width: 520,
                        height: 250,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            begin: Alignment(-1 + 2 * _shimmer(t), -1),
                            end: Alignment(1 + 2 * _shimmer(t), 1),
                            colors: const [Color(0xFF1F2937), Color(0xFF374151), Color(0xFF1F2937)],
                          ),
                        ),
                        child: const Text(
                          'هنا يطلع الإعلان (٥ ثواني)',
                          style: TextStyle(fontFamily: kufi, fontSize: 20, color: AppColors.muted),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 140,
                      right: 140,
                      bottom: 60,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: seg(t, 1.2, 3.5),
                          minHeight: 6,
                          backgroundColor: Colors.white12,
                          color: AppColors.gold,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 44,
                      left: 20,
                      child: t < 3.5
                          ? Container(
                              width: 34,
                              height: 34,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.muted, width: 2),
                              ),
                              child: Text(
                                arabicNumber(math.max(1, 5 - ((t - 1.2) / .46).floor())),
                                style: const TextStyle(fontWeight: FontWeight.w900),
                              ),
                            )
                          : Container(
                              width: 34,
                              height: 34,
                              decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                              child: const Icon(Icons.close, color: Colors.black, size: 22),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ...flyingIcons(t, 4.1, button, pill, count: 10),
        ?finger(t, [(.4, const Offset(600, 470)), (.88, const Offset(456, 268))], [.9]),
        ?finger(t, [(3.25, const Offset(220, 330)), (3.8, const Offset(37, 61))], [3.85]),
      ],
    ),
  );
}

double _shimmer(double t) => (t * .6) % 1;

// ───────── ١٩ غرفة التبديل

const _wardTabs = ['الشخصيات', 'الإطارات', 'الطاولات', 'الكروت', 'الفقاعات', 'الملصقات'];
const _wardFrames = [
  'frame_fire',
  'frame_galaxy',
  'frame_ice',
  'frame_neon',
  'frame_rainbow',
  'frame_sun',
  'frame_emerald',
];
const _wardAvatars = ['emir', 'falconer', 'wolf', 'pilot', 'sultana', 'lady_gold', 'cool'];
const _wardBubbles = [
  'bubble_classic',
  'bubble_galaxy',
  'bubble_gold',
  'bubble_neon',
  'bubble_rose',
  'bubble_sea',
  'bubble_fire',
];
const _wardTables = ['majlis', 'gold', 'night', 'oasis', 'palace', 'sand', 's1'];

/// مكان كل تبويب وكل خانة (عشان الإصبع يضغطها بالضبط).
Offset _tabAt(int k) => Offset(743 - k * 68.0, 82);
Offset _cellAt(int i) => Offset(772 - 52 - (i % 4) * 102.0, 152 + (i ~/ 4) * 104.0);

Widget _wardrobe(double t) {
  final tab = t < 1.5 ? 1 : (t < 3.1 ? 0 : (t < 4.7 ? 4 : 2));
  final frame = t < 1.0 ? 'frame_fire' : 'frame_galaxy';
  final avatar = t < 2.55 ? 'emir' : 'falconer';
  final bubble = t < 4.15 ? 'bubble_classic' : 'bubble_galaxy';
  final table = t < 5.75 ? 'majlis' : 'gold';
  final cells = switch (tab) {
    1 => [
      for (final f in _wardFrames) (PlayerAvatar(avatar: avatar, style: frameStyle(f), size: 52) as Widget, f == frame),
    ],
    0 => [for (final a in _wardAvatars) (PlayerAvatar(avatar: a, size: 56) as Widget, a == avatar)],
    4 => [
      for (final b in _wardBubbles)
        (ChatBubble(style: bubbleStyle(b), text: 'هلا', fontSize: 11, maxWidth: 80) as Widget, b == bubble),
    ],
    _ => [
      for (final id in _wardTables)
        (
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset('assets/tables/carpet_$id.webp', width: 84, height: 44, fit: BoxFit.cover),
          ) as Widget,
          id == table,
        ),
    ],
  };
  // آخر خانة: المزيد من المتجر
  cells.add((
    const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.add_circle_outline_rounded, color: AppColors.gold, size: 30),
        SizedBox(height: 2),
        Text(
          'المتجر',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.goldLight),
        ),
      ],
    ),
    false,
  ));
  return NightBackground(
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        // المعاينة (يسار): شخصيتك وإطارها وفقاعتك، وطاولتك وكروتك
        Positioned(
          left: 16,
          top: 42,
          width: 330,
          height: 396,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              children: [
                const Positioned.fill(child: MajlisRoom()),
                dim(.25),
                Positioned(
                  left: 0,
                  right: 0,
                  top: 70,
                  child: Center(
                    child: SizedBox(
                      width: 150,
                      height: 130,
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          const Positioned(top: 0, child: Cushion(width: 150, height: 100)),
                          Positioned(
                            top: 16,
                            child: PlayerAvatar(avatar: avatar, style: frameStyle(frame), size: 104),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: 18,
                  child: Center(
                    child: Transform.scale(
                      scale: 1 + .12 * bump(t, 4.15, 4.5),
                      child: ChatBubble(style: bubbleStyle(bubble), text: 'هلا والله بالربع!', fontSize: 13),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: 226,
                  child: Center(
                    child: Text(
                      'أبو فهد',
                      style: TextStyle(
                        fontFamily: kufi,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.goldLight,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 18,
                  height: 120,
                  child: Row(
                    children: [
                      Expanded(
                        child: Transform.scale(
                          scale: 1 + .08 * bump(t, 5.75, 6.1),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Image.asset('assets/tables/carpet_$table.webp', fit: BoxFit.contain),
                              FractionallySizedBox(
                                widthFactor: .5,
                                child: Image.asset('assets/tables/tray_$table.webp'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const PolicyCard(policy: Policy.traitor, width: 56),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // اللي تملكه (يمين)
        Positioned(right: 16, top: 42, width: 422, height: 396, child: const _Panel(child: SizedBox.expand())),
        for (final (k, name) in _wardTabs.indexed)
          at(
            _tabAt(k),
            64,
            30,
            Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: k == tab ? AppColors.gold.withValues(alpha: .22) : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: k == tab ? AppColors.gold : Colors.white12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  name,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: k == tab ? AppColors.goldLight : AppColors.muted,
                  ),
                ),
              ),
            ),
          ),
        for (final (i, (cell, on)) in cells.indexed)
          at(
            _cellAt(i),
            94,
            96,
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: on ? AppColors.green : Colors.white12, width: on ? 2.5 : 1),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  cell,
                  if (on) const Positioned(top: -8, right: -6, child: Gfx('check', size: 22)),
                ],
              ),
            ),
          ),
        Positioned(
          right: 16,
          bottom: 14,
          width: 422,
          child: Center(
            child: t < 6.2
                ? const Text(
                    'كل اللي اشتريته هنا، اضغط وتلبسه على طول',
                    style: TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w700),
                  )
                : Transform.scale(
                    scale: Curves.easeOutBack.transform(seg(t, 6.2, 6.5)),
                    child: const _Chip(
                      'تم الحفظ، وكل اللاعبين يشوفونه',
                      color: Color(0xFF6DE3A0),
                      border: AppColors.green,
                      size: 13,
                      icon: 'check',
                    ),
                  ),
          ),
        ),
        ?finger(
          t,
          [
            (.6, const Offset(560, 470)),
            (.95, _cellAt(1)),
            (1.45, _tabAt(0)),
            (2.5, _cellAt(1)),
            (3.05, _tabAt(4)),
            (4.1, _cellAt(1)),
            (4.65, _tabAt(2)),
            (5.7, _cellAt(1)),
          ],
          [.95, 1.45, 2.5, 3.05, 4.1, 4.65, 5.7],
        ),
      ],
    ),
  );
}

// ───────── ٢٠ الملصقات المفضلة

const _sheetStickers = [
  'b_laugh',
  'laugh_tears',
  'tr_evil',
  'det_hmm',
  'shock_jaw',
  'inn_halo',
  'b_think',
  'ang_steam',
];
const _favStickers = ['laugh_tears', 'tr_evil', 'shock_jaw', 'inn_halo', 'b_think'];

Offset _stickerCell(int i) => Offset(553 - (i % 4) * 92.0, 278 + (i ~/ 4) * 82.0);
Offset _favAt(int k) => Offset(690 - k * 52.0, 395);

Widget _favorites(double t) {
  final sheet = seg(t, 0, .3, Curves.easeOutCubic) * (1 - seg(t, 2.2, 2.55, Curves.easeInCubic));
  final starred = t > 1.25;
  const chat = Offset(748, 395);
  final sent = seg(t, 3.9, 4.35, Curves.easeInOutCubic);
  final you = _seats(6)[0];
  return _Table(
    venue: Venue.desert,
    over: (seats) => [
      at(
        chat,
        52,
        52,
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.panel.withValues(alpha: .9),
            border: Border.all(color: AppColors.gold, width: 2),
          ),
          child: const Center(child: Gfx('chat', size: 32)),
        ),
      ),
      if (sheet > 0) ...[
        dim(.4 * sheet),
        Positioned(
          left: 150,
          right: 120,
          bottom: -240 + 236 * sheet,
          height: 236,
          child: const _Panel(child: SizedBox.expand()),
        ),
        for (final (i, id) in _sheetStickers.indexed)
          at(
            _stickerCell(i) + Offset(0, 240 * (1 - sheet)),
            70,
            70,
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                StickerView(sticker: sticker(id), size: 60, pop: false),
                if (i == 2 && starred)
                  Positioned(
                    top: -6,
                    right: -4,
                    child: Transform.scale(
                      scale: Curves.elasticOut.transform(seg(t, 1.25, 1.8)),
                      child: const Icon(Icons.star_rounded, color: AppColors.gold, size: 26),
                    ),
                  ),
              ],
            ),
          ),
        if (t > 1.3 && t < 2.3)
          Positioned(
            bottom: 228 * sheet,
            left: 150,
            right: 120,
            child: const Center(child: _Chip('انضاف للمفضلة (٥ من ٥)', size: 13)),
          ),
      ],
      if (t > 2.7) ...[
        at(
          _favAt(2) + const Offset(0, -38),
          90,
          22,
          Opacity(opacity: seg(t, 2.7, 3.0), child: const _Chip('المفضلة', size: 11)),
        ),
        for (final (k, id) in _favStickers.indexed)
          at(
            _favAt(k),
            46,
            46,
            Transform.scale(
              scale:
                  Curves.easeOutBack.transform(seg(t, 2.75 + k * .08, 3.15 + k * .08)) *
                  (k == 1 ? 1 - .1 * bump(t, 3.75, 3.95) : 1),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.panel.withValues(alpha: .92),
                  border: Border.all(color: AppColors.gold.withValues(alpha: .7), width: 1.5),
                ),
                padding: const EdgeInsets.all(3),
                child: StickerView(sticker: sticker(id), size: 38, pop: false),
              ),
            ),
          ),
      ],
      if (sent > 0 && sent < 1)
        at(
          bezier(_favAt(1), Offset(560, you.dy - 160), you + const Offset(0, -70), sent),
          50,
          50,
          StickerView(sticker: sticker('tr_evil'), size: 50, pop: false),
        ),
      if (t >= 4.35)
        at(
          you + const Offset(0, -72),
          80,
          80,
          Transform.scale(
            scale: Curves.elasticOut.transform(seg(t, 4.35, 4.9)),
            child: StickerView(sticker: sticker('tr_evil'), size: 76, pop: false),
          ),
        ),
      ?finger(
        t,
        [(.3, const Offset(500, 470)), (.7, _stickerCell(2)), (3.2, _stickerCell(2)), (3.7, _favAt(1))],
        [.75, 3.75],
        hold: .55,
      ),
    ],
  );
}
