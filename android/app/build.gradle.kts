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
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.casharoo"
    compileSdk = 35
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.casharoo"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
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
