import java.util.Base64

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// O Flutter repassa os `--dart-define` para o build Android como uma lista
// separada por vírgula de pares KEY=VALUE codificados em base64.
val dartDefines: List<String> =
    (project.findProperty("dart-defines") as String? ?: "")
        .split(",")
        .mapNotNull { encoded ->
            runCatching { String(Base64.getDecoder().decode(encoded)) }.getOrNull()
        }

// Mesma GOOGLE_MAPS_API_KEY usada no Dart (AppConfig), agora para o meta-data
// com.google.android.geo.API_KEY do Google Maps Android SDK.
//
// Sem a chave o build **compila mesmo assim** (placeholder vazio): o mapa
// exibirá uma mensagem de erro do SDK, mas o restante do app funciona —
// rotas/geocoding usam a chave pelo lado Dart com erro tratado pelo Result.
val mapsApiKey: String =
    dartDefines
        .firstOrNull { it.startsWith("GOOGLE_MAPS_API_KEY=") }
        ?.substringAfter("=")
        ?: ""

android {
    namespace = "com.example.spixs_tecnologia"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.spixs_tecnologia"
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
        // Substitui o placeholder ${GOOGLE_MAPS_API_KEY} do AndroidManifest.xml.
        // O placeholder é SEMPRE registrado (mesmo vazio), evitando a falha
        // do manifest merger quando o build roda sem `--dart-define`.
        manifestPlaceholders["GOOGLE_MAPS_API_KEY"] = mapsApiKey
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
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
