plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

import java.util.Base64

// dart-define を入れる変数を宣言
var dartDefines: Map<String, String> = emptyMap()

if (project.hasProperty("dart-defines")) {
    val encoded = project.property("dart-defines") as String

    dartDefines = encoded
        .split(",")
        .mapNotNull { entry ->
            val decoded = String(Base64.getDecoder().decode(entry))
            val pair = decoded.split("=")

            if (pair.size == 2) pair[0] to pair[1] else null
        }
        .toMap()
}

android {
    namespace = "com.example.flutter_sample"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = dartDefines["APP_ID"] ?: "com.example.default"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        resValue("string", "app_name", dartDefines["APP_NAME"] ?: "Flutter Sample")
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
