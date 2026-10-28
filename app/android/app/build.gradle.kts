plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.majlis.majlis"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.majlis.majlis"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // مفتاح ثابت للنسخ التجريبية، عشان بصمته (SHA-1) تبقى نفسها في كل بناء ويشتغل دخول قوقل.
    // للتجربة بس. ملف المتجر (AAB) يتوقّع بمفتاح الرفع من GitHub Secrets لو موجود (UPLOAD_KEYSTORE_PATH).
    val uploadKeystore = System.getenv("UPLOAD_KEYSTORE_PATH")
    signingConfigs {
        create("test") {
            storeFile = file("majlis-test.keystore")
            storePassword = "majlistest"
            keyAlias = "majlis"
            keyPassword = "majlistest"
        }
        if (uploadKeystore != null) {
            create("upload") {
                storeFile = file(uploadKeystore)
                storePassword = System.getenv("UPLOAD_KEYSTORE_PASSWORD")
                keyAlias = System.getenv("UPLOAD_KEY_ALIAS")
                keyPassword = System.getenv("UPLOAD_KEY_PASSWORD")
            }
        }
    }

    // ملف التثبيت اللي ينرسل مباشرة (build.yml يمرر compressLibs): مكتبات التشغيل مضغوطة عشان يصغر حجمه.
    // ملف المتجر (AAB) يبقى بدونها، وقوقل بلاي يقسّمه ويضغط التحميل بنفسه.
    packaging {
        jniLibs {
            useLegacyPackaging = project.hasProperty("compressLibs")
        }
    }

    buildTypes {
        debug {
            signingConfig = signingConfigs.getByName("test")
        }
        release {
            signingConfig = signingConfigs.getByName(if (uploadKeystore != null) "upload" else "test")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
