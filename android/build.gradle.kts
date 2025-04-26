buildscript {
    repositories {
        google() // Add this for Google Services
        mavenCentral() // Add this for other dependencies
    }
    dependencies {
        classpath("com.google.gms:google-services:4.4.2") // Latest as of 2025
        classpath("com.android.tools.build:gradle:8.1.0") // Example version
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.0")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
