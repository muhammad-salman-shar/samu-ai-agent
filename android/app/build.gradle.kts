plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.nova.localagent"
    compileSdk = 34

    defaultConfig {
        applicationId = "com.nova.localagent"
        minSdk = 26
        targetSdk = 34
        versionCode = 1
        versionName = "1.0.0"
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
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

dependencies {
    // Flutter embedding provides FlutterActivity, FlutterEngine, MethodChannel
    // AccessibilityService and WindowManager are standard Android framework APIs
    
    // AndroidX annotations for @OptIn, @MainThread, etc.
    implementation("androidx.annotation:annotation:1.7.1")
    
    // Core KTX for additional AndroidX utilities
    implementation("androidx.core:core-ktx:1.12.0")
}
