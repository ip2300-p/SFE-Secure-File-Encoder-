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

// این بخش رو اضافه کردیم: مجبور می‌کنه همه‌ی ماژول‌ها (شامل پلاگین‌هایی مثل
// receive_sharing_intent) از یک نسخه‌ی یکسان جاوا/کاتلین (۱۷) استفاده کنن،
// تا خطای "Inconsistent JVM Target Compatibility" رفع بشه.
// نکته‌ی مهم: این بلاک باید قبل از evaluationDependsOn(":app") بیاد، وگرنه
// پروژه‌ی app زودتر از موقع evaluate میشه و afterEvaluate روش خطا میده.
subprojects {
    afterEvaluate {
        extensions.findByType(com.android.build.gradle.BaseExtension::class.java)?.apply {
            compileOptions {
                sourceCompatibility = JavaVersion.VERSION_17
                targetCompatibility = JavaVersion.VERSION_17
            }
        }
        tasks.withType(org.jetbrains.kotlin.gradle.tasks.KotlinCompile::class.java).configureEach {
            compilerOptions {
                jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}