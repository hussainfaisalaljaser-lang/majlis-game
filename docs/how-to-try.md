# 📱 كيف تجرب اللعبة على جوالك

## الخطوة ١: تحميل التطبيق (بدون أي شي ثاني)

كل مرة ينحفظ شغل في GitHub، ينبني ملف APK لحاله.

1. افتح صفحة **Releases** في المستودع:
   https://github.com/hussainfaisalaljaser-lang/majlis-game/releases
2. افتح آخر **"نسخة تجريبية"**، وحمّل ملف `majlis-XX.apk`
3. افتح الملف على جوالك. لو طلب منك، اسمح بـ **"تثبيت التطبيقات من مصادر غير معروفة"**

> ⚠️ التطبيق يفتح، بس **ما يقدر يلعب** لين نرفع السيرفر (الخطوة ٢).

## الخطوة ٢: رفع السيرفر (مرة وحدة)

### أ. ترقية Firebase إلى Blaze
1. افتح https://console.firebase.google.com واختر مشروع **majlis-game**
2. اضغط **Spark plan** فوق ← **Upgrade** ← أضف البطاقة
3. **مهم:** حط **تنبيه ميزانية** (Budget alert) بـ ٥ دولار، عشان يجيك إيميل لو صار أي استهلاك

### ب. تفعيل الخدمات
1. **Authentication** ← Get started ← Sign-in method ← **Anonymous** ← Enable
2. **Firestore Database**: قاعدة `gulf` في الدوحة (**`me-central1`**) تنسوى لحالها أول رفع للسيرفر (deploy.yml)

### ج. مفتاح الرفع التلقائي
1. افتح https://console.cloud.google.com/iam-admin/serviceaccounts?project=majlis-game-1d739
2. **Create service account** ← الاسم: `github-deploy`
3. أعطه هذي الصلاحيات (Roles):
   - **Firebase Admin**
   - **Cloud Functions Admin**
   - **Service Account User**
   - **Cloud Build Editor**
   - **Artifact Registry Administrator**
   - **Cloud Run Admin**
4. افتح الحساب ← **Keys** ← **Add key** ← **JSON**، وبيتحمّل ملف
5. في GitHub: افتح المستودع ← **Settings** ← **Secrets and variables** ← **Actions** ← **New repository secret**
   - **Name:** `FIREBASE_SERVICE_ACCOUNT`
   - **Secret:** افتح الملف اللي تحمّل بـ Notepad، وانسخ كل اللي فيه والصقه هنا
6. احذف الملف من جهازك بعدها

> 🔒 **لا ترسل هذا الملف في أي محادثة.** مكانه في GitHub Secrets بس.

### د. أول رفع
في GitHub: **Actions** ← **Deploy server** ← **Run workflow**.
بعدها كل ما تغيّر شي في السيرفر في الفرع `main`، يترفع لحاله.

## الخطوة ٣: العب!

- **🤖 تدريب:** من الرئيسية اضغط **"تدريب"**، وتلعب أنت و٤ بوتات على طول
- **👥 مع أصحابك:** "أنشئ روم خاص" وأرسل لهم الكود. ولو ما كملتوا ٥، اضغط **"أضف بوت"**
- **⚡ العب الحين:** يدخلك طاولة عامة. ولو ما اكتملت خلال ٢٠ ثانية، **تتكمل ببوتات** وتبدأ

## الإشعارات
تأكد إن **Firebase Cloud Messaging API (V1)** مفعّل:
Firebase Console ← ⚙️ Project settings ← **Cloud Messaging**.
