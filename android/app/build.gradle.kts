import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "me.neon16bit.argus"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "me.neon16bit.argus"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["appName"] = "Argus"
    }

    dependenciesInfo {
        includeInApk = false
        includeInBundle = false
    }

    val keystorePropertiesFile = rootProject.file("key.properties")
    val hasKeyProperties = keystorePropertiesFile.exists()

    signingConfigs {
        if (hasKeyProperties) {
            create("release") {
                val keystoreProperties = Properties()
                keystoreProperties.load(FileInputStream(keystorePropertiesFile))
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                val storeFilePath = keystoreProperties.getProperty("storeFile")
                if (storeFilePath != null) {
                    storeFile = file(storeFilePath)
                }
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        debug {
            signingConfig = signingConfigs.getByName("debug")
            applicationIdSuffix = ".debug"
            manifestPlaceholders["appName"] = "Argus Debug"
        }
        release {
            if (hasKeyProperties) {
                signingConfig = signingConfigs.getByName("release")
            }
            manifestPlaceholders["appName"] = "Argus"
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
