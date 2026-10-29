import 'package:flutter/material.dart';

import '../services/music.dart';
import '../services/sfx.dart';
import '../services/sounds.dart';
import '../theme.dart';
import 'common.dart';
import 'design.dart';
import 'ui.dart';

/// نافذة مستوى الصوت: شريط للموسيقى وشريط للمعلق وشريط للمؤثرات، كل واحد لحاله. تنحفظ في الجوال.
Future<void> showVolumeDialog(BuildContext context) =>
    showDialog<void>(context: context, builder: (_) => const _VolumeDialog());

class _VolumeDialog extends StatelessWidget {
  const _VolumeDialog();

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: Colors.transparent,
    insetPadding: const EdgeInsets.all(16),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: SingleChildScrollView(
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 22),
              child: ParchmentCard(
                padding: const EdgeInsets.fromLTRB(16, 34, 16, 14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const VolumePanel(),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: 160,
                      child: GameButton(
                        label: 'تمام',
                        height: 44,
                        fontSize: 20,
                        tone: ButtonTone.green,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const RibbonTitle('الصوت', size: 22),
          ],
        ),
      ),
    ),
  );
}

/// ثلاث أشرطة: الموسيقى، المعلق (الراوي)، المؤثرات. السحب لليمين أو اليسار يعلّي ويخفض، وأقصى الطرف الأدنى يسكته.
class VolumePanel extends StatelessWidget {
  const VolumePanel({super.key});

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      _VolumeRow(
        icon: 'music',
        offIcon: 'music_off',
        label: 'الموسيقى',
        level: Music.volume,
        onChanged: (v, {required bool save}) {
          Music.setVolume(v, save: save);
          // كان كاتم الموسيقى من زر قديم: تحريك الشريط يرجعها
          if (v > 0 && Music.muted.value) Music.toggle();
        },
      ),
      _VolumeRow(
        icon: 'megaphone',
        offIcon: 'mute',
        label: 'المعلق',
        level: Sfx.volume,
        onChanged: (v, {required bool save}) {
          Sfx.setVolume(v, save: save);
          if (v > 0 && Sfx.muted.value) Sfx.toggle();
          // بعد ما يفلت الشريط: جملة قصيرة عشان تسمع المستوى
          if (save) {
            Sfx.hush();
            Sfx.say('your_turn');
          }
        },
      ),
      _VolumeRow(
        icon: 'sound',
        offIcon: 'mute',
        label: 'المؤثرات',
        level: Sounds.volume,
        onChanged: (v, {required bool save}) {
          Sounds.setVolume(v, save: save);
          if (v > 0 && Sfx.muted.value) Sfx.toggle();
          // بعد ما يفلت الشريط: ضربة ختم عشان تسمع المستوى
          if (save) Sounds.play('stamp');
        },
      ),
    ],
  );
}

class _VolumeRow extends StatelessWidget {
  const _VolumeRow({
    required this.icon,
    required this.offIcon,
    required this.label,
    required this.level,
    required this.onChanged,
  });

  final String icon, offIcon, label;
  final ValueNotifier<double> level;

  /// [save] صح لما يفلت اللاعب الشريط.
  final void Function(double value, {required bool save}) onChanged;

  /// المستوى قبل الكتم، عشان ضغطة ثانية ترجّعه.
  static final _before = <ValueNotifier<double>, double>{};

  void _toggleMute(double v) {
    if (v > 0) {
      _before[level] = v;
      onChanged(0, save: true);
    } else {
      onChanged(_before[level] ?? .5, save: true);
    }
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
    valueListenable: level,
    builder: (context, v, _) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // ضغطة الأيقونة تكتم، وضغطة ثانية ترجّع المستوى اللي كان
          Semantics(
            button: true,
            label: v <= 0 ? 'شغّل $label' : 'اكتم $label',
            excludeSemantics: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _toggleMute(v),
              child: Padding(padding: const EdgeInsets.all(4), child: Gfx(v <= 0 ? offIcon : icon, size: 30)),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: kufi,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: Color(0xFF3A2212),
                    height: 1.2,
                  ),
                ),
                SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 9,
                    activeTrackColor: const Color(0xFFD08A22),
                    inactiveTrackColor: const Color(0xFF5A3B22).withValues(alpha: .45),
                    thumbColor: const Color(0xFFFFF0B8),
                    overlayColor: const Color(0xFFD08A22).withValues(alpha: .2),
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 11, elevation: 2),
                    trackShape: const RoundedRectSliderTrackShape(),
                  ),
                  child: SizedBox(
                    height: 30,
                    child: Slider(
                      value: v,
                      onChanged: (x) => onChanged(x, save: false),
                      onChangeEnd: (x) => onChanged(x, save: true),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 44,
            child: Text(
              '${arabicNumber((v * 100).round())}٪',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: kufi,
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: Color(0xFF6B4A2A),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
