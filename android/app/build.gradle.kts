import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// 正式签名：从 android/key.properties 读取（不提交到 git）。
// 只在构建 release / profile 时要求它存在；缺失或缺键时直接报错，不会悄悄退回调试签名。
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) FileInputStream(keystorePropertiesFile).use { load(it) }
}
val requiredSigningKeys = listOf("storeFile", "storePassword", "keyAlias", "keyPassword")

gradle.taskGraph.whenReady {
    val needsReleaseSigning = allTasks.any { task ->
        task.project == project && (task.name.contains("Release") || task.name.contains("Profile"))
    }
    if (!needsReleaseSigning) return@whenReady
    if (!keystorePropertiesFile.exists()) {
        throw GradleException(
            "找不到 ${keystorePropertiesFile.path}：release 构建需要正式签名。" +
                "请按 key.properties 的格式创建它（storeFile / storePassword / keyAlias / keyPassword）。",
        )
    }
    // 只报缺了哪个键，不输出任何值
    val missing = requiredSigningKeys.filter { keystoreProperties.getProperty(it).isNullOrBlank() }
    if (missing.isNotEmpty()) {
        throw GradleException("key.properties 缺少：${missing.joinToString()}")
    }
    val store = file(keystoreProperties.getProperty("storeFile"))
    if (!store.exists()) {
        throw GradleException("key.properties 里的 storeFile 指向的签名文件不存在")
    }
}

android {
    namespace = "com.xfx.facet"
    // flutter_local_notifications 要求 compileSdk >= 35
    compileSdk = maxOf(flutter.compileSdkVersion, 36)
    ndkVersion = flutter.ndkVersion

    buildFeatures {
        // 用 resValue 区分正式版 / 调试版的 App 名称
        resValues = true
    }

    compileOptions {
        // flutter_local_notifications 定时通知需要 Java 8+ 时间 API 的脱糖
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.xfx.facet"
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
        // 桌面图标下的名字（AndroidManifest 里引用 @string/app_name）
        resValue("string", "app_name", "XPlanner")
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                storeFile = keystoreProperties.getProperty("storeFile")?.let { file(it) }
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
        getByName("profile") {
            signingConfig = signingConfigs.getByName("release")
        }
        debug {
            // 调试版和正式版可以同时装在手机上：包名加 .debug，名字显示 XPlanner Dev
            applicationIdSuffix = ".debug"
            resValue("string", "app_name", "XPlanner Dev")
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

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
