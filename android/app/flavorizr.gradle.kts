import com.android.build.gradle.AppExtension
import java.util.Properties

val android = project.extensions.getByType(AppExtension::class.java)

// 💡 .env.{flavor} から環境依存のドメイン名を動的に読み込むヘルパー
fun loadEnvProperty(flavorName: String, propertyKey: String, defaultValue: String): String {
    val properties = Properties()
    val envFile = project.rootProject.file(".env.$flavorName")
    if (envFile.exists()) {
        envFile.inputStream().use { properties.load(it) }
        return properties.getProperty(propertyKey) ?: defaultValue
    }
    return defaultValue
}

android.apply {
    flavorDimensions("flavor-type")

    productFlavors {
        create("local") {
            dimension = "flavor-type"
            applicationId = "jp.example.sample.local"
            resValue(type = "string", name = "app_name", value = "[Local] Sample")
            manifestPlaceholders["customUrlScheme"] = "flsamplelocal"
            manifestPlaceholders["appLinkDomain"] = loadEnvProperty("local", "APP_LINK_DOMAIN", "unused")
        }
        create("dev") {
            dimension = "flavor-type"
            applicationId = "jp.example.sample.dev"
            resValue(type = "string", name = "app_name", value = "[Dev] Sample")
            manifestPlaceholders["customUrlScheme"] = "flsampledev"
            manifestPlaceholders["appLinkDomain"] = loadEnvProperty("dev", "APP_LINK_DOMAIN", "dev-flutter-sample.web.app")
        }
        create("stg") {
            dimension = "flavor-type"
            applicationId = "jp.example.sample.stg"
            resValue(type = "string", name = "app_name", value = "[Stg] Sample")
            manifestPlaceholders["customUrlScheme"] = "flsamplestg"
            manifestPlaceholders["appLinkDomain"] = loadEnvProperty("stg", "APP_LINK_DOMAIN", "stg-flutter-sample.web.app")
        }
        create("prod") {
            dimension = "flavor-type"
            applicationId = "jp.example.sample"
            resValue(type = "string", name = "app_name", value = "Sample App")
            manifestPlaceholders["customUrlScheme"] = "flsample"
            manifestPlaceholders["appLinkDomain"] = loadEnvProperty("prod", "APP_LINK_DOMAIN", "flutter-sample.web.app")
        }
    }
}