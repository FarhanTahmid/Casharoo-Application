import java.util.Properties
import java.io.FileInputStream

// Load signing props from key.properties
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
    println("Loaded keystore properties from ${keystorePropertiesFile.path}")
}

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// The one place the app ID lives. Flavours add a suffix so dev, staging and
// prod can sit side by side on one phone. Change before the first Play upload.
val baseApplicationId = "com.example.casharoo"

android {
    namespace = "com.example.casharoo"
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
        applicationId = baseApplicationId
        minSdk = 24
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Pair each flavour with its config/<flavour>.json for the Dart side:
    //   flutter run --flavor dev --dart-define-from-file=config/dev.json
    flavorDimensions += "environment"
    productFlavors {
        create("dev") {
            dimension = "environment"
            applicationIdSuffix = ".dev"
            versionNameSuffix = "-dev"
            resValue("string", "app_name", "Casharoo Dev")
        }
        create("staging") {
            dimension = "environment"
            applicationIdSuffix = ".stg"
            versionNameSuffix = "-stg"
            resValue("string", "app_name", "Casharoo Staging")
        }
        create("prod") {
            dimension = "environment"
            resValue("string", "app_name", "Casharoo")
        }
    }

    signingConfigs {
        // Use getByName to modify existing entries rather than create duplicates
        create("releaseCustom") {
        val storeFileProp = keystoreProperties.getProperty("storeFile")
        if (!storeFileProp.isNullOrBlank()) {
            val sf = file(storeFileProp)
            if (!sf.exists()) logger.warn("Keystore not found: $sf")
            storeFile = sf
            storePassword = keystoreProperties.getProperty("storePassword")
            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")
        } else {
            logger.warn("Missing 'storeFile' in key.properties")
        }
        }

        // OPTIONAL: sign debug with custom key too
        create("debugCustom") {
        val storeFileProp = keystoreProperties.getProperty("storeFile")
        if (!storeFileProp.isNullOrBlank()) {
            val sf = file(storeFileProp)
            if (!sf.exists()) logger.warn("Keystore not found: $sf")
            storeFile = sf
            storePassword = keystoreProperties.getProperty("storePassword")
            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")
        }
        }
    }

    buildTypes {
        getByName("release") {
        // <<< THIS is the key line >>>
        signingConfig = signingConfigs.getByName("releaseCustom")
        }
        getByName("debug") {
        // comment this if you want default debug keystore
        signingConfig = signingConfigs.getByName("debugCustom")
        }
    }
}

flutter {
    source = "../.."
}
