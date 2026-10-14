plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// CI supplies stable signing material via private repository secrets.
val medisuiviStoreFile = System.getenv("MEDISUIVI_SIGNING_STORE_FILE")
val medisuiviStorePassword = System.getenv("MEDISUIVI_SIGNING_STORE_PASSWORD")
val medisuiviKeyAlias = System.getenv("MEDISUIVI_SIGNING_KEY_ALIAS")
val medisuiviKeyPassword = System.getenv("MEDISUIVI_SIGNING_KEY_PASSWORD")
val medisuiviStableSigningReady = listOf(
    medisuiviStoreFile,
    medisuiviStorePassword,
    medisuiviKeyAlias,
    medisuiviKeyPassword,
).all { !it.isNullOrBlank() }


android {
    namespace = "com.example.medisuivi"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.medisuivi"
        manifestPlaceholders["medisuiviAppLabel"] = if (
            System.getenv("MEDISUIVI_REMOTE_SANDBOX_APK") == "true"
        ) "MediSuivi Test" else "MediSuivi"
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

    signingConfigs {
        if (medisuiviStableSigningReady) {
            create("medisuiviStableDemo") {
                storeFile = file(medisuiviStoreFile!!)
                storePassword = medisuiviStorePassword!!
                keyAlias = medisuiviKeyAlias!!
                keyPassword = medisuiviKeyPassword!!
            }
        }
    }

    buildTypes {
        debug {
            // Install the public-HTTPS sandbox alongside an existing MediSuivi
            // rather than replacing a different signed or offline build.
            if (System.getenv("MEDISUIVI_REMOTE_SANDBOX_APK") == "true") {
                applicationIdSuffix = ".sandbox"
                versionNameSuffix = "-sandbox"
            }
        }
        release {
            // Never silently sign a distributable release with a debug key.
            // Dedicated CI enforces pinned cert and refuses missing secrets.
            signingConfig = if (medisuiviStableSigningReady) {
                signingConfigs.getByName("medisuiviStableDemo")
            } else {
                null
            }
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
