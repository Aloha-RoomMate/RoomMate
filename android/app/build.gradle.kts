plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("org.jetbrains.kotlin.android") // 권장. 기존 kotlin-android도 동작은 함
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.roommate"

    compileSdk = 36
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }
    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.roommate"

        // ★ Kotlin DSL에서는 이렇게 씁니다
        minSdk = flutter.minSdkVersion
        // 필요하면 Flutter 값 따라가도록:
        // targetSdk = flutter.targetSdkVersion
        targetSdk = 36

        // Flutter 플러그인 타입에 따라 다르므로 먼저 이렇게 시도:
        versionCode = flutter.versionCode      // 안 되면 아래 주석라인로 교체
        versionName = flutter.versionName      // 안 되면 아래 주석라인로 교체

        // 타입 불일치 오류가 나올 때 대안:
        // versionCode = flutter.versionCode.toInt()
        // versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
