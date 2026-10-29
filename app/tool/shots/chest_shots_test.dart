// الصندوق (الموسم) بحجم كبير وبحجمه في الرئيسية، لفحص الرسم.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:majlis/widgets/design_icons.dart';

import 'shot_helper.dart';

void main() {
  setUpAll(loadFonts);

  testWidgets('chest', (tester) async {
    await shot(
      tester,
      'chest',
      const ColoredBox(
        color: Color(0xFFE7D2A4),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ChestIcon(size: 360),
              SizedBox(width: 40),
              ChestIcon(size: 64),
              SizedBox(width: 20),
              ChestIcon(size: 30),
            ],
          ),
        ),
      ),
    );
  });
}
