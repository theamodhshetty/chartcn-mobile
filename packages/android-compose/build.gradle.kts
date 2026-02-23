plugins {
  id("com.android.library") version "8.8.1"
  kotlin("android") version "2.1.10"
  kotlin("plugin.serialization") version "2.1.10"
  kotlin("plugin.compose") version "2.1.10"
}

android {
  namespace = "dev.chartcn.mobile"
  compileSdk = 35

  defaultConfig {
    minSdk = 24
    consumerProguardFiles("consumer-rules.pro")
  }

  buildFeatures {
    compose = true
  }

  compileOptions {
    sourceCompatibility = JavaVersion.VERSION_17
    targetCompatibility = JavaVersion.VERSION_17
  }

  kotlinOptions {
    jvmTarget = "17"
  }

  testOptions {
    unitTests.isIncludeAndroidResources = false
  }
}

dependencies {
  implementation("androidx.core:core-ktx:1.13.1")
  implementation("androidx.compose.ui:ui:1.7.8")
  implementation("androidx.compose.foundation:foundation:1.7.8")
  implementation("androidx.compose.material3:material3:1.3.1")
  implementation("androidx.compose.ui:ui-tooling-preview:1.7.8")

  implementation("androidx.sqlite:sqlite:2.5.0")
  implementation("androidx.sqlite:sqlite-ktx:2.5.0")

  implementation("org.jetbrains.kotlinx:kotlinx-serialization-json:1.8.0")

  testImplementation("junit:junit:4.13.2")
  testImplementation(kotlin("test"))
}
