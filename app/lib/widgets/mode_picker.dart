import 'package:flutter/material.dart';

import '../theme.dart';
import 'common.dart';

/// وش فيه كل طور (تحت الاختيار وفي غرفة الانتظار).
String modeHint(bool roles) =>
    roles ? 'فيه العرّاف والحارس والقاضي والشيخ والجاسوس' : 'الزعيم والخونة والأوفياء بس، بدون أدوار خاصة';

/// الطور: عادي (الزعيم والخونة والأوفياء بس) أو الشخصيات (فيه أدوار خاصة).
class ModePicker extends StatelessWidget {
  const ModePicker({super.key, required this.roles, required this.onChanged});

  final bool roles;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      SegmentedButton<bool>(
        showSelectedIcon: false,
        style: const ButtonStyle(visualDensity: VisualDensity.compact),
        segments: const [
          ButtonSegment(value: false, label: Text('عادي'), icon: Gfx('dagger', size: 18)),
          ButtonSegment(value: true, label: Text('الشخصيات'), icon: Gfx('seer', size: 18)),
        ],
        selected: {roles},
        onSelectionChanged: (s) => onChanged(s.first),
      ),
      const SizedBox(height: 3),
      Text(
        modeHint(roles),
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.muted, fontSize: 11.5),
      ),
    ],
  );
}
