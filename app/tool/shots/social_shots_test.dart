// تصوير شاشات الدواوين والأصدقاء والدردشة والملف والنوافذ ببيانات تجريبية (بدون سيرفر).
// التشغيل:  flutter test tool/shots/social_shots_test.dart   (المخرجات في SHOT_DIR)
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:majlis/models/chat.dart';
import 'package:majlis/models/clan.dart';
import 'package:majlis/screens/chat_screen.dart';
import 'package:majlis/screens/clans_screen.dart';
import 'package:majlis/models/profile.dart';
import 'package:majlis/models/table_tier.dart';
import 'package:majlis/screens/friends_screen.dart';
import 'package:majlis/screens/private_screen.dart';
import 'package:majlis/screens/waiting_screen.dart';
import 'package:majlis/widgets/mode_theme.dart';
import 'package:majlis/screens/profile_screen.dart';
import 'package:majlis/screens/welcome_screen.dart';
import 'package:majlis/services/backend.dart';
import 'package:majlis/widgets/daily_reward.dart';
import 'package:majlis/widgets/gifts.dart';
import 'package:majlis/widgets/player_card.dart';
import 'package:majlis/widgets/settings.dart';
import 'package:majlis/widgets/common.dart';
import 'package:majlis/widgets/design_social.dart';

import 'shot_helper.dart';

const _week = '2026-W44';

/// ديوان تجريبي بعضوين مثل لقطة التصميم.
Clan _clan({String id = 'c1', List<(String, String, String, ClanRole, int)>? members}) {
  final list = members ?? [('u1', 'حسين', 'sheikh', ClanRole.owner, 120), ('u2', 'أحمد', 'wolf', ClanRole.member, 290)];
  return Clan.fromJson({
    'id': id,
    'name': 'ديوان',
    'color': 2,
    'emblem': 'sheikh',
    'ownerId': 'u1',
    'count': list.length,
    'total': 900,
    'weekly': {_week: 430},
    'members': {
      for (final (uid, name, avatar, role, points) in list)
        uid: {'name': name, 'avatar': avatar, 'role': role.name, 'joined': 1, 'week': _week, 'points': points},
    },
  }, _week);
}

ChatMessage _msg(String id, String uid, String name, String avatar, String text, {ClanRole? role, String? sticker}) =>
    ChatMessage.fromJson(id, {
      'uid': uid,
      'name': name,
      'avatar': avatar,
      'text': text,
      'sticker': sticker,
      'role': role?.name,
      'at': DateTime.now().millisecondsSinceEpoch,
    });

/// أخطاء معروفة من برا شاشاتي ما نوقف عليها التصوير: إطار الفارس يرسم تدرج غلط (frames/rare.dart)،
/// وإضافات الجوال (الصوت) ما تشتغل بالاختبار. شرح اللعب (how_to_play) ما ينصور هنا لأن صوت الراوي يرمي أخطاء من برا الفريم.
void _ignoreKnownErrors() {
  final old = FlutterError.onError;
  FlutterError.onError = (d) {
    final e = d.exceptionAsString();
    if (e.contains('"colors" must have length 2') || e.contains('MissingPluginException')) return;
    old?.call(d);
  };
  addTearDown(() => FlutterError.onError = old);
}

void main() {
  setUpAll(loadFonts);

  final clan = _clan();
  Widget members(ClanMember m, bool big) => ClanMemberTile(member: m, online: m.uid == 'u1', big: big, onTap: () {});

  Widget clanPanel() => ClanPanelView(
    clan: clan,
    myUid: 'u1',
    chatFresh: false,
    chatOpen: false,
    memberBuilder: members,
    onLeave: () {},
    onChat: () {},
    onInvite: () {},
    onRequests: () {},
    onSettings: () {},
    onClaim: () {},
  );

  Widget ranking() => ClanRankingView(
    search: TextEditingController(),
    onSearch: (_) {},
    clans: [
      clan,
      _clan(id: 'c2'),
      _clan(id: 'c3'),
      _clan(id: 'c4'),
    ],
    ranked: true,
    mine: 'c1',
    canJoin: false,
    labelOf: (_) => ('ادخل', true),
    onJoin: (_) {},
    onDetails: (_) {},
  );

  Widget clanChat() => ChatPanelView(
    header: const SocDiamondTitle('دردشة الديوان'),
    messages: [
      _msg('3', 'u1', 'حسين', 'sheikh', '', role: ClanRole.owner, sticker: 'laugh_grin'),
      _msg('2', 'u2', 'أحمد', 'wolf', 'جاهز! مين معنا بعد؟'),
      _msg('1', 'u1', 'حسين', 'sheikh', 'الليلة بطولة الديوان… جاهزين؟', role: ClanRole.owner),
    ],
    myUid: 'u3',
    clan: true,
    controller: TextEditingController(),
    focus: FocusNode(),
    sending: false,
    onSend: () {},
    onStickers: () {},
  );

  testWidgets('clans', (tester) async {
    await shot(
      tester,
      'clans',
      SocScaffold(
        title: 'الدواوين',
        icon: const Gfx('shield', size: 30),
        currency: false,
        body: SocTwoPanels(main: clanPanel(), side: ranking()),
      ),
    );
  });

  testWidgets('clans_chat', (tester) async {
    await shot(
      tester,
      'clans_chat',
      SocScaffold(
        title: 'الدواوين',
        icon: const Gfx('shield', size: 30),
        currency: false,
        body: SocTwoPanels(main: clanPanel(), side: clanChat()),
      ),
    );
  });

  Widget friendsPanel({int tab = 0}) => FriendsPanelView(
    tab: tab,
    onTab: (_) {},
    chatsBadge: 0,
    requestsBadge: 2,
    onAdd: () {},
    child: ListView(
      padding: const EdgeInsets.only(top: 6),
      children: [
        FriendRowView(
          name: 'جود',
          avatar: 'rose',
          status: 'متصل الحين',
          statusColor: socGreenText,
          dot: SocDot.online,
          selected: true,
          trailing: [
            SocButton(label: 'ادعُ', tone: SocTone.green, height: 36, fontSize: 17, width: 86, onPressed: () {}),
          ],
        ),
        FriendRowView(
          name: 'فيصل',
          avatar: 'cool',
          status: 'يلعب الحين',
          statusColor: socOrangeText,
          dot: SocDot.playing,
          trailing: [
            SocButton(label: 'تفرّج', tone: SocTone.blue, height: 36, fontSize: 17, width: 86, onPressed: () {}),
          ],
        ),
        FriendRowView(
          name: 'لولوة',
          avatar: 'pearl',
          status: 'متصل الحين',
          statusColor: socGreenText,
          dot: SocDot.online,
          unread: 3,
          trailing: [
            SocButton(label: 'ادعُ', tone: SocTone.green, height: 36, fontSize: 17, width: 86, onPressed: () {}),
          ],
        ),
        const FriendRowView(name: 'بدر', avatar: 'desert', status: 'قبل ساعة', dot: SocDot.offline),
        const FriendRowView(name: 'ماجد', avatar: 'youth', status: 'قبل يوم', dot: SocDot.offline),
      ],
    ),
  );

  Widget dmChat() => ChatPanelView(
    header: ChatFriendHeader(
      friend: (uid: 'f1', name: 'جود', avatar: 'rose', frame: null),
      presence: Stream.value(Presence(on: true, at: DateTime.now())),
    ),
    messages: [
      _msg('3', 'u3', 'أنا', 'wolf', 'جاي، سوّي روم'),
      _msg('2', 'f1', 'جود', 'rose', '', sticker: 'laugh_grin'),
      _msg('1', 'f1', 'جود', 'rose', 'وينك؟ يالله نلعب!'),
    ],
    myUid: 'u3',
    clan: false,
    controller: TextEditingController(),
    focus: FocusNode(),
    sending: false,
    onSend: () {},
    onStickers: () {},
    footer: ChatInviteCard(name: 'جود', avatar: 'rose', note: '٥ من ٧ داخلين', onJoin: () {}, onLater: () {}),
  );

  testWidgets('friends', (tester) async {
    await shot(
      tester,
      'friends',
      SocScaffold(
        title: 'الأصدقاء',
        icon: const Gfx('friends', size: 30),
        body: SocTwoPanels(main: friendsPanel(), side: dmChat()),
      ),
    );
  });

  /// صفحة فاضية تفتح نافذة بعد أول فريم (لتصوير النوافذ).
  Widget popupHost(Future<void> Function(BuildContext) open) => _PopupHost(open);

  testWidgets('profile', (tester) async {
    _ignoreKnownErrors();
    final p = Backend.instance.profile.value;
    await shot(
      tester,
      'profile',
      SocScaffold(
        title: 'ملفي',
        icon: const Gfx('profile', size: 28),
        body: SocTwoPanels(
          mainFlex: 8,
          sideFlex: 11,
          main: ProfileIdentityPanel(
            profile: p,
            ready: true,
            onEdit: () {},
            onWardrobe: () {},
            onDev: () {},
            onPremiumId: () {},
            settings: SettingsCard(profile: p),
          ),
          side: ProfileStatsPanel(
            profile: p,
            levelRoad: LevelRoad(level: p.level),
            onHistory: () {},
          ),
        ),
      ),
    );
  });

  testWidgets('edit_profile', (tester) async {
    await shot(
      tester,
      'edit_profile',
      EditProfileView(
        firstTime: true,
        avatar: 'falcon',
        frame: null,
        name: TextEditingController(text: 'حسين'),
        error: null,
        saving: false,
        choices: const [
          'falcon',
          'pearl',
          'desert',
          'sheikh',
          'rose',
          'cool',
          'youth',
          'masked',
          'wolf',
          'jasmine',
          'emir',
          'knight',
          'queen',
          'poet',
          'scholar',
          'merchant',
          'sky',
          'night',
        ],
        locked: (a) => a == 'queen' || a == 'knight',
        onPick: (_) {},
        onLocked: (_) {},
        onSave: () {},
      ),
    );
  });

  testWidgets('welcome', (tester) async {
    await shot(tester, 'welcome', WelcomeView(busy: false, onGoogle: () {}, onGuest: () {}));
  });

  testWidgets('popup_daily', (tester) async {
    await shot(tester, 'popup_daily', popupHost((c) => showDailyReward(c)));
  });

  testWidgets('popup_gift', (tester) async {
    await shot(
      tester,
      'popup_gift',
      popupHost(
        (c) => showGiftDialog(
          c,
          Gift.fromJson({'kind': 'tutorial', 'n': 10, 'coins': 500, 'diamonds': 20, 'items': <String>[]}),
        ),
      ),
    );
  });

  testWidgets('popup_player', (tester) async {
    await shot(tester, 'popup_player', popupHost((c) => showPlayerCard(c, uid: 'x', name: 'فيصل', avatar: 'cool')));
  });

  testWidgets('private', (tester) async {
    await shot(
      tester,
      'private',
      PrivateRoomView(
        mode: ModeTheme.classic,
        playerCount: 5,
        quick: false,
        busy: false,
        ready: true,
        friendsCount: 3,
        onCount: (_) {},
        onQuick: (_) {},
        onCreate: () {},
        onJoin: () {},
        onFriends: () {},
      ),
    );
  });

  testWidgets('waiting', (tester) async {
    await shot(tester, 'waiting', WaitingScreen(tier: tableTiers.first, playerCount: 7));
  });

  testWidgets('waiting_private', (tester) async {
    await shot(tester, 'waiting_private', const WaitingScreen(tier: null, playerCount: 5));
  });

  // أحجام جوالات صغيرة: ما لازم يطلع overflow ولا يتقص شي.
  for (final size in const [Size(700, 320), Size(800, 360)]) {
    final tag = '${size.width.toInt()}x${size.height.toInt()}';
    testWidgets('small_clans_$tag', (tester) async {
      await shot(
        tester,
        'small_clans_$tag',
        SocScaffold(
          title: 'الدواوين',
          icon: const Gfx('shield', size: 30),
          currency: false,
          body: SocTwoPanels(main: clanPanel(), side: clanChat()),
        ),
        size: size,
      );
    });
    testWidgets('small_friends_$tag', (tester) async {
      await shot(
        tester,
        'small_friends_$tag',
        SocScaffold(
          title: 'الأصدقاء',
          icon: const Gfx('friends', size: 30),
          body: SocTwoPanels(main: friendsPanel(), side: dmChat()),
        ),
        size: size,
      );
    });
    testWidgets('small_profile_$tag', (tester) async {
      _ignoreKnownErrors();
      final p = Backend.instance.profile.value;
      await shot(
        tester,
        'small_profile_$tag',
        SocScaffold(
          title: 'ملفي',
          icon: const Gfx('profile', size: 28),
          body: SocTwoPanels(
            mainFlex: 8,
            sideFlex: 11,
            main: ProfileIdentityPanel(
              profile: p,
              ready: true,
              onEdit: () {},
              onWardrobe: () {},
              onDev: () {},
              onPremiumId: () {},
              settings: SettingsCard(profile: p),
            ),
            side: ProfileStatsPanel(
              profile: p,
              levelRoad: LevelRoad(level: p.level),
              onHistory: () {},
            ),
          ),
        ),
        size: size,
      );
    });
    testWidgets('small_waiting_$tag', (tester) async {
      await shot(tester, 'small_waiting_$tag', WaitingScreen(tier: tableTiers.first, playerCount: 7), size: size);
    });
    testWidgets('small_private_$tag', (tester) async {
      await shot(
        tester,
        'small_private_$tag',
        PrivateRoomView(
          mode: ModeTheme.classic,
          playerCount: 5,
          quick: false,
          busy: false,
          ready: true,
          friendsCount: 3,
          onCount: (_) {},
          onQuick: (_) {},
          onCreate: () {},
          onJoin: () {},
          onFriends: () {},
        ),
        size: size,
      );
    });
    testWidgets('small_welcome_$tag', (tester) async {
      await shot(
        tester,
        'small_welcome_$tag',
        WelcomeView(busy: false, onGoogle: () {}, onGuest: () {}),
        size: size,
      );
    });
    testWidgets('small_edit_$tag', (tester) async {
      await shot(
        tester,
        'small_edit_$tag',
        EditProfileView(
          firstTime: true,
          avatar: 'falcon',
          frame: null,
          name: TextEditingController(text: 'حسين'),
          error: null,
          saving: false,
          choices: const [
            'falcon',
            'pearl',
            'desert',
            'sheikh',
            'rose',
            'cool',
            'youth',
            'masked',
            'wolf',
            'jasmine',
            'emir',
            'knight',
          ],
          locked: (a) => a == 'knight',
          onPick: (_) {},
          onLocked: (_) {},
          onSave: () {},
        ),
        size: size,
      );
    });
    testWidgets('small_daily_$tag', (tester) async {
      await shot(tester, 'small_daily_$tag', popupHost((c) => showDailyReward(c)), size: size);
    });
    testWidgets('small_gift_$tag', (tester) async {
      await shot(
        tester,
        'small_gift_$tag',
        popupHost(
          (c) => showGiftDialog(
            c,
            Gift.fromJson({'kind': 'tutorial', 'n': 10, 'coins': 500, 'diamonds': 20, 'items': <String>[]}),
          ),
        ),
        size: size,
      );
    });
  }

  testWidgets('create_clan', (tester) async {
    await shot(
      tester,
      'create_clan',
      SocScaffold(
        title: 'الدواوين',
        icon: const Gfx('shield', size: 30),
        currency: false,
        body: SocTwoPanels(
          main: CreateClanView(
            name: TextEditingController(text: 'ديوان الصقور'),
            color: 2,
            emblem: 'falcon',
            busy: false,
            label: 'سوّ الديوان بـ٥٬٠٠٠ ذهب',
            onName: () {},
            onColor: (_) {},
            onEmblem: (_) {},
            onCreate: () {},
          ),
          side: ranking(),
        ),
      ),
    );
  });

  testWidgets('friends_screen', (tester) async {
    await shot(tester, 'friends_screen', const FriendsScreen());
  });

  testWidgets('friends_requests', (tester) async {
    await shot(
      tester,
      'friends_requests',
      SocScaffold(
        title: 'الأصدقاء',
        icon: const Gfx('friends', size: 30),
        body: SocTwoPanels(
          main: FriendsPanelView(
            tab: 2,
            onTab: (_) {},
            chatsBadge: 1,
            requestsBadge: 2,
            onAdd: () {},
            child: ListView(
              padding: const EdgeInsets.only(top: 6),
              children: [
                FriendRowView(
                  name: 'بدر',
                  avatar: 'desert',
                  status: 'يبي يصير صديقك · مستوى ١٢',
                  dot: null,
                  trailing: [
                    SocButton(
                      label: 'قبول',
                      tone: SocTone.green,
                      height: 36,
                      fontSize: 16,
                      width: 80,
                      onPressed: () {},
                    ),
                    SocButton(label: 'رفض', tone: SocTone.grey, height: 36, fontSize: 16, width: 70, onPressed: () {}),
                  ],
                ),
              ],
            ),
          ),
          side: dmChat(),
        ),
      ),
    );
  });

  testWidgets('popup_addfriend', (tester) async {
    await shot(tester, 'popup_addfriend', popupHost((c) => showAddFriend(c)));
  });
}

class _PopupHost extends StatefulWidget {
  const _PopupHost(this.open);

  final Future<void> Function(BuildContext) open;

  @override
  State<_PopupHost> createState() => _PopupHostState();
}

class _PopupHostState extends State<_PopupHost> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.open(context));
  }

  @override
  Widget build(BuildContext context) => const SocScaffold(title: 'الأصدقاء', body: SizedBox.expand());
}
