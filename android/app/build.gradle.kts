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
    // AccessibilityService aur WindowManager standard Android framework APIs hain
    
    // Material Components for Theme.MaterialComponents.DayNight.NoActionBar
    implementation("com.google.android.material:material:1.11.0")
}
