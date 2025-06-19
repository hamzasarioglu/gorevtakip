plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.gorev_takip_uygulamasi"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"


   defaultConfig {
    applicationId = "com.example.gorev_takip_uygulamasi"
    minSdk = 23  // <-- Burayı 23 yapıyoruz
    targetSdk = 34
    versionCode = 1
    versionName = "1.0"
}


buildTypes {
    release {
        isMinifyEnabled = false
        isShrinkResources = false
    }
}

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("org.jetbrains.kotlin:kotlin-stdlib:1.9.24")
    implementation("androidx.core:core-ktx:1.12.0")
    implementation("androidx.appcompat:appcompat:1.6.1")
    implementation("com.google.android.material:material:1.11.0")

    // Firebase (örnek)
    implementation("com.google.firebase:firebase-auth-ktx:22.3.0")
    implementation("com.google.firebase:firebase-firestore-ktx:24.11.0")
}

