plugins {
    id("com.android.library")
}

android {
    namespace = "org.godotengine.plugin.android.MusicPlayerHelper"
    compileSdk = 35

    defaultConfig {
        //Don't change this godot requires minSdk to be 24
        minSdk = 24
        buildConfigField("String", "GODOT_PLUGIN_NAME", "\"MusicPlayer\"")
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
        consumerProguardFiles("src/main/keepRules/rules.keep")
    }

    buildFeatures { buildConfig = true }

    buildTypes {
        release {
            isMinifyEnabled = false
            buildConfigField(
                "String",
                "pluginPackageName",
                "\"org.godotengine.plugin.android.MusicPlayerHelper\""
            )
            buildConfigField("String", "pluginName", "\"MusicPlayer\"")
        }
        debug {
            buildConfigField(
                "String",
                "pluginPackageName",
                "\"org.godotengine.plugin.android.MusicPlayerHelper\""
            )
            buildConfigField("String", "pluginName", "\"MusicPlayer\"")
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    dependencies {
        implementation(libs.appcompat)
        implementation(libs.material)
        implementation("androidx.media:media:1.8.0")
        implementation("androidx.media3:media3-exoplayer:1.5.1")
        implementation("androidx.media3:media3-session:1.5.1")
        testImplementation(libs.junit)
        androidTestImplementation(libs.espresso.core)
        androidTestImplementation(libs.ext.junit)
        compileOnly("org.godotengine:godot:4.6.0.stable")
    }
}
