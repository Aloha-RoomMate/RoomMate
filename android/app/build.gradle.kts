plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
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

    signingConfigs {
        getByName("debug") {
            // 기본 debug.keystore를 사용하도록 보장합니다.
        }
    }

    defaultConfig {
        applicationId = "com.example.roommate"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        minSdkVersion(24) 
        // 타입 오류 나는 경우가 있어 안전하게 toInt 사용 권장
        versionCode = flutter.versionCode.toInt()
        versionName = flutter.versionName
    }

    signingConfigs {
        create("debugCustom") {
            storeFile = file(System.getProperty("user.home") + "/.android/debug_custom.keystore")
            storePassword = "android"
            keyAlias = "androiddebugkey"
            keyPassword = "android"
        }
    }

    buildTypes {
        debug {
            signingConfig = signingConfigs.getByName("debugCustom")
            isMinifyEnabled = false
            isShrinkResources = false
        }
        release {
            // 실제 배포 시에는 별도 릴리즈 키 사용 권장
            signingConfig = signingConfigs.getByName("debugCustom")
            isMinifyEnabled = false
            isShrinkResources = false
        }
        getByName("debug"){
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
