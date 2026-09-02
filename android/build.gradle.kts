import org.jetbrains.kotlin.gradle.tasks.KotlinCompile

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Global build directory configuration
rootProject.layout.buildDirectory.set(rootProject.layout.projectDirectory.dir("../build"))

subprojects {
    project.layout.buildDirectory.set(rootProject.layout.buildDirectory.dir(project.name))
}

subprojects {
    if (project.name != "app") {
        project.evaluationDependsOn(":app")
    }
}

// Force all modules (app + plugins) to use the same compatible versions
subprojects {
    fun configureProject() {
        // Skip the app module to avoid "sourceCompatibility has been finalized" error
        if (project.name == "app") return

        if (project.hasProperty("android")) {
            val android = project.extensions.getByName("android") as? com.android.build.gradle.BaseExtension
            android?.apply {
                compileSdkVersion(36)
                buildToolsVersion("36.0.0")
                defaultConfig {
                    targetSdkVersion(36)
                }
                compileOptions {
                    sourceCompatibility = JavaVersion.VERSION_17
                    targetCompatibility = JavaVersion.VERSION_17
                }
            }
        }

        tasks.withType<JavaCompile>().configureEach {
            sourceCompatibility = "17"
            targetCompatibility = "17"
        }

        tasks.withType<KotlinCompile>().configureEach {
            compilerOptions {
                jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
            }
        }
    }

    if (project.state.executed) {
        configureProject()
    } else {
        afterEvaluate {
            configureProject()
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
