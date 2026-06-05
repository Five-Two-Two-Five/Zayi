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
    afterEvaluate {
        if (project.name == "blue_thermal_printer") {
            // Set Namespace using reflection via the project extension
            val androidExtension = project.extensions.findByName("android")
            if (androidExtension != null) {
                try {
                    val method = androidExtension.javaClass.getMethod("setNamespace", String::class.java)
                    method.invoke(androidExtension, "id.kakzaki.blue_thermal_printer")
                } catch (e: Exception) {
                    println("Could not set namespace: ${e.message}")
                }
            }

            // Remove package attribute from Manifest
            tasks.matching { it.name.startsWith("process") && it.name.endsWith("Manifest") }.configureEach {
                doFirst {
                    val manifestFile = file("${project.projectDir}/src/main/AndroidManifest.xml")
                    if (manifestFile.exists()) {
                        val content = manifestFile.readText()
                        val newContent = content.replace(Regex("package=\"[^\"]*\""), "")
                        manifestFile.writeText(newContent)
                    }
                }
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
