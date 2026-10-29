// سهم الرجوع الموحّد: مكبّر، وفي أشرطة الشاشات الأربعة (كلها لازم تطلع بنفس الرسمة).
// التشغيل:  flutter test tool/shots/back_arrow_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:majlis/widgets/design.dart';
import 'package:majlis/widgets/design_season.dart';
import 'package:majlis/widgets/design_shop.dart';
import 'package:majlis/widgets/design_social.dart';

import 'shot_helper.dart';

void main() {
  setUpAll(loadFonts);

  testWidgets('back arrow big', (tester) async {
    await shot(
      tester,
      'back_arrow_big',
      const WoodWall(
        child: Center(child: BackArrow(height: 260)),
      ),
      size: const Size(480, 360),
    );
  });

  testWidgets('back arrow in every bar', (tester) async {
    await shot(
      tester,
      'back_arrow_bars',
      const WoodWall(
        child: SafeArea(
          child: Column(
            children: [
              DesignAppBar(title: 'شريط التصميم'),
              ShopTopBar(title: 'المتجر'),
              SnTopBar(title: 'الموسم'),
              SocHeader(title: 'الأصدقاء', currency: false),
            ],
          ),
        ),
      ),
      size: const Size(960, 300),
    );
  });
}
