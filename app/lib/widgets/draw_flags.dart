/// أنواع رسم تنطفي بس وقت «قياس الرسم والتنقل» في أدوات المطور (screens/draw_bench.dart)، عشان نعرف كم
/// ياخذ كل نوع من وقت الرسم في جوال اللاعب. باقي الوقت كلها شغالة.
abstract final class DrawFlags {
  /// ظل النصوص المحددة (OutlinedText).
  static bool textShadows = true;

  /// تدرج العناوين الذهبية (OutlinedText).
  static bool titleGradients = true;

  /// رسومات الأغراض في كروت المتجر (ItemPreview).
  static bool itemArt = true;

  static void reset() => textShadows = titleGradients = itemArt = true;
}
