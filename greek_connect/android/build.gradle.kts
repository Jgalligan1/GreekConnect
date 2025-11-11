allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    val appPath = ":app"
    // Avoid forcing evaluation of :app to prevent configuration-time errors (e.g. missing/broken NDK).
    // Only proceed if you really need to evaluate :app and have fixed the Android SDK/NDK setup.
    if (rootProject.findProject(appPath) != null) {
        // Intentionally do not call project.evaluationDependsOn(appPath) here.
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
