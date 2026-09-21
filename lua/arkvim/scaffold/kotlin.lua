-- arkvim/scaffold/kotlin.lua — Kotlin / Android / Compose 模板
local util = require("arkvim.scaffold.util")

local M = {}
local gen = {}

gen.kotlin_cli = function(target, name)
  local t = util.project_tokens(name)
  util.write_tree(target, {
    ["build.gradle.kts"] = util.fill([[
plugins { kotlin("jvm") version "1.9.22" application }
application { mainClass.set("{{Pascal}}Kt") }
repositories { mavenCentral() }
dependencies { implementation(kotlin("stdlib")) }
]], t),
    ["src/main/kotlin/" .. t.snake .. "/Main.kt"] = util.fill([[
fun main() { println("Hello from {{NAME}}!") }
]], t),
    [".gitignore"] = "build/\n.gradle/\n",
  })
  return "Kotlin CLI 已生成"
end

gen.android = function(target, name)
  local t = util.project_tokens(name)
  util.write_tree(target, {
    ["build.gradle.kts"] = util.fill([[
plugins { kotlin("android") version "1.9.22" }
android { namespace = "com.example.{{snake}}" }
dependencies { implementation("androidx.core:core-ktx:1.12.0") }
]], t),
    ["src/main/AndroidManifest.xml"] = '<manifest xmlns:android="http://schemas.android.com/apk/res/android"/>\n',
    [".gitignore"] = "build/\n.gradle/\n",
  })
  return "Android (Kotlin) 骨架已生成"
end

gen.ktor = function(target, name)
  local t = util.project_tokens(name)
  util.write_tree(target, {
    ["build.gradle.kts"] = util.fill([[
plugins { kotlin("jvm") version "1.9.22" application }
application { mainClass.set("{{Pascal}}Kt") }
repositories { mavenCentral() }
dependencies {
  implementation("io.ktor:ktor-server-core:2.3.7")
  implementation("io.ktor:ktor-server-netty:2.3.7")
  implementation("ch.qos.logback:logback-classic:1.4.14")
}
]], t),
    ["src/main/kotlin/" .. t.snake .. "/Application.kt"] = util.fill([[
import io.ktor.server.engine.*
import io.ktor.server.netty.*
import io.ktor.server.response.*
import io.ktor.server.routing.*
fun main() {
  embeddedServer(Netty, port = 8080) {
    routing { get("/") { call.respondText("Hello from {{NAME}}!") } }
  }.start(wait = true)
}
]], t),
    ["src/main/resources/logback.xml"] = '<configuration><appender name="STDOUT" class="ch.qos.logback.core.ConsoleAppender"><encoder><pattern>%d{HH:mm:ss.SSS} [%thread] %-5level %logger{36} - %msg%n</pattern></encoder></appender><root level="INFO"><appender-ref ref="STDOUT"/></root></configuration>\n',
    [".gitignore"] = "build/\n.gradle/\n",
  })
  return "Ktor 服务端 已生成"
end

-- Compose Multiplatform（Desktop 入口）
gen.compose = function(target, name)
  local t = util.project_tokens(name)
  util.write_tree(target, {
    ["settings.gradle.kts"] = util.fill('rootProject.name = "{{kebab}}"\n', t),
    ["build.gradle.kts"] = util.fill([[
import org.jetbrains.compose.desktop.application.dsl.TargetFormat

plugins {
  kotlin("jvm") version "1.9.22"
  id("org.jetbrains.compose") version "1.6.2"
}

repositories {
  mavenCentral()
  maven("https://maven.pkg.jetbrains.space/public/p/compose/dev")
}

dependencies {
  implementation(compose.desktop.currentOs)
}

compose.desktop {
  application {
    mainClass = "MainKt"
    nativeDistributions { targetFormats(TargetFormat.Dmg, TargetFormat.Msi, TargetFormat.Deb) }
  }
}
]], t),
    ["src/main/kotlin/Main.kt"] = util.fill([[
import androidx.compose.material.*
import androidx.compose.runtime.*
import androidx.compose.ui.window.*

fun main() = application {
  Window(onCloseRequest = ::exitApplication, title = "{{NAME}}") {
    MaterialTheme { Text("Hello from {{NAME}}!") }
  }
}
]], t),
    [".gitignore"] = "build/\n.gradle/\n",
    ["README.md"] = util.fill("# {{NAME}}\n\n```bash\n./gradlew run\n```\n", t),
  })
  return "Compose Multiplatform (Kotlin) 已生成"
end

M.frameworks = {
  { label = "Kotlin CLI", lang = "kotlin", gen = gen.kotlin_cli, main = "",
    requires = { bins = { "kotlinc", "gradle" }, pacman = { "kotlin", "gradle" }, note = "本项目用 Gradle 构建" } },
  { label = "Ktor 服务端 (Kotlin)", lang = "kotlin", gen = gen.ktor, main = "",
    requires = { bins = { "gradle" }, pacman = { "gradle" } } },
  { label = "Compose Multiplatform (Kotlin)", lang = "kotlin", gen = gen.compose, main = "src/main/kotlin/Main.kt",
    requires = { bins = { "gradle" }, pacman = { "gradle" } } },
  { label = "Android (Kotlin)", lang = "kotlin", gen = gen.android, main = "",
    requires = { bins = { "gradle" }, pacman = { "gradle", "android-sdk" }, note = "还需要 Android SDK" } },
}

return M
