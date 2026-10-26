import 'dart:js_interop';

import '../widgets/fx.dart';
import '../widgets/fx_sig.dart';

@JS('fxTime')
external set _fxTime(JSFunction f);

@JS('fxMoment')
external set _fxMoment(JSFunction f);

/// window.fxTime(ثواني) يثبت وقت الحركات (كل فريم بالتصوير نقدمه بنفسنا عشان الفيديو يطلع ناعم)،
/// وwindow.fxTime(null) يرجعها للساعة. window.fxMoment(مفتاح) يشغّل اللحظة الخاصة لصورة.
void installCaptureHook() {
  _fxTime = ((JSNumber? t) {
    FxClock.manual.value = t?.toDartDouble;
  }).toJS;
  _fxMoment = ((JSString key) {
    Moments.trigger(key.toDart);
  }).toJS;
}
