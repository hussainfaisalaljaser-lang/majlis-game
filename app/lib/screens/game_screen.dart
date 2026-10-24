import 'package:flutter/material.dart';

import '../services/backend.dart';
import '../theme.dart';

/// شاشة اللعب. حالياً تعرض دورك ومرحلة اللعبة بس، والطاولة الكاملة جاية في الخطوة الجاية.
class GameScreen extends StatelessWidget {
  const GameScreen({super.key, required this.code});

  final String code;

  static const _roles = {
    'loyal': ('🔵', 'وفي', 'مهمتك تكشف الخونة وتمرر ٥ قرارات زرقاء', AppColors.loyal),
    'traitor': ('🔴', 'خائن', 'ساعد زعيمك يوصل للحكم بدون ما تنكشف', AppColors.traitor),
    'leader': ('🦹', 'زعيم الخونة', 'خلّهم يثقون فيك وينتخبونك مستشار', AppColors.traitor),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('روم $code')),
      body: StreamBuilder(
        stream: Backend.instance.watchView(code),
        builder: (context, snap) {
          final view = snap.data;
          if (view == null) return const Center(child: CircularProgressIndicator());
          final (emoji, name, goal, color) = _roles[view['yourRole']]!;
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('دورك السري', style: TextStyle(color: AppColors.muted)),
                  const SizedBox(height: 8),
                  Text(emoji, style: const TextStyle(fontSize: 72)),
                  Text(name, style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: color)),
                  const SizedBox(height: 8),
                  Text(goal, textAlign: TextAlign.center),
                  const SizedBox(height: 32),
                  const Text('🚧 الطاولة الكاملة قيد البناء', style: TextStyle(color: AppColors.muted)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
