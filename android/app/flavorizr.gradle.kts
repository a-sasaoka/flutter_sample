import com.android.build.gradle.AppExtension

val android = project.extensions.getByType(AppExtension::class.java)

android.apply {
    flavorDimensions("flavor-type")

    productFlavors {
        create("local") {
            dimension = "flavor-type"
            applicationId = "jp.example.sample.local"
            resValue(type = "string", name = "app_name", value = "[Local] Sample")
        }
        create("dev") {
            dimension = "flavor-type"
            applicationId = "jp.example.sample.dev"
            resValue(type = "string", name = "app_name", value = "[Dev] Sample")
        }
        create("stg") {
            dimension = "flavor-type"
            applicationId = "jp.example.sample.stg"
            resValue(type = "string", name = "app_name", value = "[Stg] Sample")
        }
        create("prod") {
            dimension = "flavor-type"
            applicationId = "jp.example.sample"
            resValue(type = "string", name = "app_name", value = "Sample App")
        }
    }
}