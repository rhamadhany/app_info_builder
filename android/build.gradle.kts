import org.jetbrains.kotlin.gradle.dsl.JvmTarget
import org.gradle.api.specs.Spec

plugins {
    id("com.android.library")
    id("org.jetbrains.kotlin.android")
}

group = "com.BNeoTech.app_info_builder"
version = "1.0-SNAPSHOT"

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

android {
    namespace = "com.BNeoTech.app_info_builder"
    compileSdk = 34

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    sourceSets {
        getByName("main").java.srcDirs("src/main/kotlin")
    }

    defaultConfig {
        minSdk = 21
    }
}

kotlin {
    compilerOptions {
        jvmTarget.set(JvmTarget.JVM_17)
    }
}

class AppInfoGeneratorPlugin : Plugin<Project> {

    private fun findFlutterProject(rootProject: Project): Project? {
        for (entry in rootProject.allprojects) {
            for (plugin in entry.plugins) {
                if (plugin.javaClass.name == "com.flutter.gradle.FlutterPlugin") {
                    return entry
                }
            }
        }
        return null
    }

    override fun apply(hostProject: Project) {
        val rootProj = hostProject.rootProject
        val flutterProject = findFlutterProject(rootProj)
        if (flutterProject == null) {
            println("[app_info_builder] FlutterPlugin not found; auto-generate disabled.")
            return
        }
        println("[app_info_builder] Flutter project found: " + flutterProject.path)

        val androidRootDir = rootProj.projectDir
        val userProjectDir = androidRootDir.parentFile
            ?: throw GradleException("Root project not found from: " + androidRootDir.absolutePath)

        val runGenerate: Action<Task> = object : Action<Task> {
            override fun execute(t: Task) {
                println("[app_info_builder] Running dart run app_info_builder:generate in " + userProjectDir)
                val pb = ProcessBuilder("dart", "run", "app_info_builder:generate")
                pb.directory(userProjectDir)
                pb.inheritIO()
                val proc = pb.start()
                val exitCode = proc.waitFor()
                if (exitCode != 0) {
                    throw GradleException("app_info_builder generate failed with exit code " + exitCode)
                }
            }
        }

        val existing = flutterProject.tasks.findByName("generateAppInfo")
        val appInfoTask: Task = existing ?: flutterProject.tasks.register("generateAppInfo", object : Action<Task> {
            override fun execute(t: Task) {
                t.group = "flutter"
                t.description = "Generate lib/generated/app_info.dart (compile-time constants)."
                t.doLast(runGenerate)
            }
        }).get()

        val hookAction: Action<Task> = object : Action<Task> {
            override fun execute(t: Task) {
                if (t.name.startsWith("compileFlutterBuild")) {
                    println("[app_info_builder] HOOK: " + t.path)
                    // Run `generateAppInfo` before this compile task.
                    // The task itself is unconditionally re-executed
                    // (up-to-date checks disabled) so the generated Dart file
                    // always reflects the current metadata.
                    t.dependsOn(appInfoTask)
                    appInfoTask.outputs.upToDateWhen(object : Spec<Task> {
                        override fun isSatisfiedBy(element: Task): Boolean = false
                    })
                }
            }
        }

        flutterProject.tasks.configureEach(hookAction)
    }
}

apply<AppInfoGeneratorPlugin>()
