-- ARKVIM scaffold: framework-oriented project generator
-- Pick a framework -> type a name -> project skeleton is created.
--     <leader>pc   (see lua/config/keymaps.lua)
--
-- Selection window is fixed-size and scrollable.
-- Plugins load ONLY when the language is detected after project creation.

local M = {}

local _log = vim.log.levels

-- ---------------------------------------------------------------------------
-- helpers
-- ---------------------------------------------------------------------------

local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO)
end

local function slug(name)
  local s = string.lower(tostring(name or ""))
  s = s:gsub("[^%w]+", "-"):gsub("^-+", ""):gsub("-+$", "")
  return s == "" and "app" or s
end

local function snake(name) return slug(name):gsub("-", "_") end

local function pascal(name)
  local parts = {}
  for p in slug(name):gsub("-", "_"):gsub("_", " "):gmatch("%S+") do
    parts[#parts + 1] = p:sub(1, 1):upper() .. p:sub(2)
  end
  return table.concat(parts)
end

local function fill(content, t)
  return (content:gsub("{{(%w+)}}", function(k)
    return t[k] or ("{{" .. k .. "}}")
  end))
end

local function write_tree(root, files)
  for rel, content in pairs(files) do
    local path = root .. "/" .. rel
    vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")
    local lines = vim.split(content, "\n", { plain = true })
    if lines[#lines] == "" then lines[#lines] = nil end
    vim.fn.writefile(lines, path)
  end
end

local function project_tokens(name)
  local kebab = slug(name)
  return { NAME = name, kebab = kebab, snake = snake(name), Pascal = pascal(name),
           pkg = "com.example." .. snake(name) }
end

local function unzip_strip(zip, target)
  local tmp = vim.fn.tempname()
  vim.fn.mkdir(tmp, "p")
  vim.fn.system({ "unzip", "-oq", zip, "-d", tmp })
  if vim.v.shell_error ~= 0 then vim.fn.system({ "rm", "-rf", tmp }); return false end
  local dirs = vim.fn.glob(tmp .. "/*/", false, true)
  local inner = #dirs == 1 and vim.fn.substitute(dirs[1], "/$", "", "") or tmp
  vim.fn.system({ "cp", "-a", inner .. "/.", target })
  local ok = vim.v.shell_error == 0
  vim.fn.system({ "rm", "-rf", tmp })
  return ok
end

local function mkdir_p(dir) vim.fn.mkdir(dir, "p") end

-- ---------------------------------------------------------------------------
-- generators
-- ---------------------------------------------------------------------------

local gen = {}

-- ===== Java =====
gen.springboot = function(target, name)
  local t = project_tokens(name)
  mkdir_p(target)
  local zip = vim.fn.tempname() .. ".zip"
  local url = string.format(
    "https://start.spring.io/starter.zip?type=maven-project&language=java"
      .. "&groupId=com.example&artifactId=%s&name=%s&packageName=%s"
      .. "&packaging=jar&javaVersion=17&dependencies=web,devtools,validation,lombok",
    t.kebab, t.NAME, t.pkg)
  vim.fn.system({ "curl", "-fsSL", "--max-time", "90", "-o", zip, url })
  if vim.v.shell_error == 0 and vim.fn.filereadable(zip) == 1 then
    local ok = unzip_strip(zip, target)
    if ok then vim.fn.system({ "rm", "-f", zip }); return "Spring Boot 已生成" end
  end
  vim.fn.system({ "rm", "-f", zip })
  local files = {
    ["pom.xml"] = fill([[<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>
  <parent>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-parent</artifactId>
    <version>3.3.5</version>
    <relativePath/>
  </parent>
  <groupId>com.example</groupId>
  <artifactId>{{kebab}}</artifactId>
  <version>0.0.1-SNAPSHOT</version>
  <name>{{NAME}}</name>
  <properties><java.version>17</java.version></properties>
  <dependencies>
    <dependency><groupId>org.springframework.boot</groupId><artifactId>spring-boot-starter-web</artifactId></dependency>
    <dependency><groupId>org.springframework.boot</groupId><artifactId>spring-boot-starter-test</artifactId><scope>test</scope></dependency>
  </dependencies>
  <build><plugins>
    <plugin><groupId>org.springframework.boot</groupId><artifactId>spring-boot-maven-plugin</artifactId></plugin>
  </plugins></build>
</project>]], t),
    [("src/main/java/com/example/%s/%sApplication.java"):format(t.snake, t.Pascal)] = fill([[
package com.example.{{snake}};
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;
@SpringBootApplication @RestController
public class {{Pascal}}Application {
  public static void main(String[] args) { SpringApplication.run({{Pascal}}Application.class, args); }
  @GetMapping("/") public String hello() { return "Hello from {{NAME}}!"; }
}]], t),
    ["src/main/resources/application.yml"] = "server:\n  port: 8080\n",
    [".gitignore"] = "target/\n*.class\n*.jar\n.idea/\n*.iml\n",
    ["README.md"] = fill("# {{NAME}}\n\n```bash\nmvn spring-boot:run\n```\n", t),
  }
  write_tree(target, files)
  return "Spring Boot (离线骨架) 已生成"
end

gen.javacli = function(target, name)
  local t = project_tokens(name)
  write_tree(target, {
    ["src/" .. t.snake .. "/Main.java"] = fill("package {{snake}};\npublic class Main {\n  public static void main(String[] args) {\n    System.out.println(\"Hello from {{NAME}}!\");\n  }\n}\n", t),
    ["Makefile"] = ("JAVAC := javac\nJAVA  := java\n\nbuild:\n\t$(JAVAC) -d out src/%s/Main.java\n\nrun: build\n\t$(JAVA) -cp out %s.Main\n\n.PHONY: build run\n"):format(t.snake, t.snake),
    [".gitignore"] = "out/\n*.class\n",
  })
  return "Java CLI 已生成"
end

-- ===== Kotlin =====
gen.kotlin_cli = function(target, name)
  local t = project_tokens(name)
  write_tree(target, {
    ["build.gradle.kts"] = fill([[
plugins { kotlin("jvm") version "1.9.22" application }
application { mainClass.set("{{Pascal}}Kt") }
repositories { mavenCentral() }
dependencies { implementation(kotlin("stdlib")) }
]], t),
    ["src/main/kotlin/" .. t.snake .. "/Main.kt"] = fill([[
fun main() { println("Hello from {{NAME}}!") }
]], t),
    [".gitignore"] = "build/\n.gradle/\n",
  })
  return "Kotlin CLI 已生成"
end

gen.android = function(target, name)
  local t = project_tokens(name)
  mkdir_p(target)
  local zip = vim.fn.tempname() .. ".zip"
  local url = "https://github.com/nicklasb Laurent/Android-Project-Templates/raw/main/BasicActivity.zip"
  vim.fn.system({ "curl", "-fsSL", "--max-time", "60", "-o", zip, url })
  if vim.v.shell_error == 0 and vim.fn.filereadable(zip) == 1 then
    local ok = unzip_strip(zip, target)
    if ok then vim.fn.system({ "rm", "-f", zip }); return "Android 项目已生成" end
  end
  vim.fn.system({ "rm", "-f", zip })
  -- offline fallback
  write_tree(target, {
    ["build.gradle.kts"] = fill([[
plugins { kotlin("android") version "1.9.22" }
android { namespace = "com.example.{{snake}}" }
dependencies { implementation("androidx.core:core-ktx:1.12.0") }
]], t),
    ["src/main/AndroidManifest.xml"] = '<manifest xmlns:android="http://schemas.android.com/apk/res/android"/>\n',
    [".gitignore"] = "build/\n.gradle/\n",
  })
  return "Android (离线骨架) 已生成"
end

gen.ktor = function(target, name)
  local t = project_tokens(name)
  write_tree(target, {
    ["build.gradle.kts"] = fill([[
plugins { kotlin("jvm") version "1.9.22" application }
application { mainClass.set("{{Pascal}}Kt") }
repositories { mavenCentral() }
dependencies {
  implementation("io.ktor:ktor-server-core:2.3.7")
  implementation("io.ktor:ktor-server-netty:2.3.7")
  implementation("ch.qos.logback:logback-classic:1.4.14")
}
]], t),
    ["src/main/kotlin/" .. t.snake .. "/Application.kt"] = fill([[
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

-- ===== C / C++ =====
gen.cmake_c = function(target, name)
  local t = project_tokens(name)
  write_tree(target, {
    ["CMakeLists.txt"] = fill("cmake_minimum_required(VERSION 3.16)\nproject({{NAME}} C)\nset(CMAKE_C_STANDARD 11)\nadd_executable({{kebab}} src/main.c)\n", t),
    ["src/main.c"] = fill('#include <stdio.h>\nint main(void) {\n  printf("Hello from {{NAME}}!\\n");\n  return 0;\n}\n', t),
    ["build.sh"] = "#!/usr/bin/env bash\nset -e\ncmake -S . -B build && cmake --build build && ./build/" .. t.kebab .. "\n",
    [".gitignore"] = "build/\n",
  })
  vim.fn.setfperm(target .. "/build.sh", "rwxr-xr-x")
  return "C + CMake 已生成"
end

gen.cmake_cpp = function(target, name)
  local t = project_tokens(name)
  write_tree(target, {
    ["CMakeLists.txt"] = fill("cmake_minimum_required(VERSION 3.16)\nproject({{NAME}} CXX)\nset(CMAKE_CXX_STANDARD 17)\nadd_executable({{kebab}} src/main.cpp)\n", t),
    ["src/main.cpp"] = fill('#include <iostream>\nint main() {\n  std::cout << "Hello from {{NAME}}!" << std::endl;\n  return 0;\n}\n', t),
    ["build.sh"] = "#!/usr/bin/env bash\nset -e\ncmake -S . -B build && cmake --build build && ./build/" .. t.kebab .. "\n",
    [".gitignore"] = "build/\n",
  })
  vim.fn.setfperm(target .. "/build.sh", "rwxr-xr-x")
  return "C++ + CMake 已生成"
end

-- ===== Go =====
gen.gomod = function(target, name)
  local t = project_tokens(name)
  local module = "example.com/" .. t.kebab
  write_tree(target, {
    ["go.mod"] = ("module %s\n\ngo 1.22\n"):format(module),
    ["main.go"] = fill('package main\nimport "fmt"\nfunc main() {\n\tfmt.Println("Hello from {{NAME}}!")\n}\n', t),
    [".gitignore"] = t.kebab .. "\n*.exe\n",
  })
  return "Go module 已生成"
end

gen.gin = function(target, name)
  local t = project_tokens(name)
  local module = "example.com/" .. t.kebab
  write_tree(target, {
    ["go.mod"] = ("module %s\n\ngo 1.22\n\nrequire github.com/gin-gonic/gin v1.9.1\n"):format(module),
    ["main.go"] = fill([[
package main
import "github.com/gin-gonic/gin"
func main() {
  r := gin.Default()
  r.GET("/", func(c *gin.Context) { c.String(200, "Hello from {{NAME}}!") })
  r.Run(":8080")
}
]], t),
    [".gitignore"] = t.kebab .. "\n",
  })
  return "Go + Gin 已生成"
end

gen.fiber = function(target, name)
  local t = project_tokens(name)
  local module = "example.com/" .. t.kebab
  write_tree(target, {
    ["go.mod"] = ("module %s\n\ngo 1.22\n\nrequire github.com/gofiber/fiber/v2 v2.52.0\n"):format(module),
    ["main.go"] = fill([[
package main
import "github.com/gofiber/fiber/v2"
func main() {
  app := fiber.New()
  app.Get("/", func(c *fiber.Ctx) error { return c.SendString("Hello from {{NAME}}!") })
  app.Listen(":8080")
}
]], t),
    [".gitignore"] = t.kebab .. "\n",
  })
  return "Go + Fiber 已生成"
end

-- ===== Rust =====
gen.cargo = function(target, name)
  local t = project_tokens(name)
  write_tree(target, {
    ["Cargo.toml"] = fill('[package]\nname = "{{kebab}}"\nversion = "0.1.0"\nedition = "2021"\n\n[dependencies]\n', t),
    ["src/main.rs"] = fill('fn main() {\n    println!("Hello from {{NAME}}!");\n}\n', t),
    [".gitignore"] = "/target\n",
  })
  return "Rust + Cargo 已生成"
end

gen.actix = function(target, name)
  local t = project_tokens(name)
  write_tree(target, {
    ["Cargo.toml"] = fill('[package]\nname = "{{kebab}}"\nversion = "0.1.0"\nedition = "2021"\n\n[dependencies]\nactix-web = "4"\nactix-rt = "2"\n', t),
    ["src/main.rs"] = fill([[
use actix_web::{web, App, HttpServer, HttpResponse};
async fn index() -> HttpResponse { HttpResponse::Ok().body("Hello from {{NAME}}!") }
#[actix_web::main]
async fn main() -> std::io::Result<()> {
    HttpServer::new(|| App::new().route("/", web::get().to(index)))
        .bind("127.0.0.1:8080")?.run().await
}
]], t),
    [".gitignore"] = "/target\n",
  })
  return "Rust + Actix 已生成"
end

gen.axum = function(target, name)
  local t = project_tokens(name)
  write_tree(target, {
    ["Cargo.toml"] = fill('[package]\nname = "{{kebab}}"\nversion = "0.1.0"\nedition = "2021"\n\n[dependencies]\naxum = "0.7"\ntokio = { version = "1", features = ["full"] }\n', t),
    ["src/main.rs"] = fill([[
use axum::{routing::get, Router};
async fn index() -> &'static str { "Hello from {{NAME}}!" }
#[tokio::main]
async fn main() {
    let app = Router::new().route("/", get(index));
    let listener = tokio::net::TcpListener::bind("0.0.0.0:8080").await.unwrap();
    axum::serve(listener, app).await.unwrap();
}
]], t),
    [".gitignore"] = "/target\n",
  })
  return "Rust + Axum 已生成"
end

-- ===== Python =====
gen.py_pkg = function(target, name)
  local t = project_tokens(name)
  write_tree(target, {
    ["pyproject.toml"] = fill('[build-system]\nrequires = ["setuptools>=68"]\nbuild-backend = "setuptools.build_meta"\n\n[project]\nname = "{{kebab}}"\nversion = "0.1.0"\nrequires-python = ">=3.9"\n', t),
    ["src/" .. t.snake .. "/__init__.py"] = '"""' .. t.NAME .. ' package."""\n__version__ = "0.1.0"\n',
    ["src/" .. t.snake .. "/__main__.py"] = fill('from {{snake}} import __version__\ndef main(): print(f"Hello from {{NAME}} (v{__version__})")\nif __name__ == "__main__": main()\n', t),
    [".gitignore"] = ".venv/\n__pycache__/\n*.egg-info/\n",
  })
  return "Python package 已生成"
end

gen.fastapi = function(target, name)
  local t = project_tokens(name)
  write_tree(target, {
    ["app/__init__.py"] = "",
    ["app/main.py"] = fill('from fastapi import FastAPI\napp = FastAPI(title="{{NAME}}")\n@app.get("/")\ndef root(): return {"message": "Hello from {{NAME}}!"}\n', t),
    ["requirements.txt"] = "fastapi>=0.110\nuvicorn[standard]>=0.29\n",
    [".gitignore"] = ".venv/\n__pycache__/\n",
  })
  return "FastAPI 已生成"
end

gen.django = function(target, name)
  local t = project_tokens(name)
  write_tree(target, {
    ["manage.py"] = '#!/usr/bin/env python\nimport os, sys\nif __name__ == "__main__":\n    os.environ.setdefault("DJANGO_SETTINGS_MODULE", "settings")\n    from django.core.management import execute_from_command_line\n    execute_from_command_line(sys.argv)\n',
    ["settings.py"] = 'SECRET_KEY = "dev"\nINSTALLED_APPS = ["django.contrib.contenttypes"]\nROOT_URLCONF = "urls"\n',
    ["urls.py"] = 'from django.urls import path\nurlpatterns = []\n',
    ["requirements.txt"] = "django>=5.0\n",
    [".gitignore"] = ".venv/\n__pycache__/\n*.pyc\n",
  })
  return "Django 骨架已生成 (需 pip install -r requirements.txt && python manage.py migrate)"
end

gen.flask = function(target, name)
  local t = project_tokens(name)
  write_tree(target, {
    ["app.py"] = fill('from flask import Flask\napp = Flask(__name__)\n@app.route("/")\ndef index(): return "Hello from {{NAME}}!"\nif __name__ == "__main__": app.run(debug=True)\n', t),
    ["requirements.txt"] = "flask>=3.0\n",
    [".gitignore"] = ".venv/\n__pycache__/\n",
  })
  return "Flask 已生成"
end

-- ===== Dart / Flutter =====
gen.dart_cli = function(target, name)
  local t = project_tokens(name)
  write_tree(target, {
    ["pubspec.yaml"] = fill('name: {{kebab}}\ndescription: {{NAME}}\nversion: 0.1.0\n\nenvironment:\n  sdk: ">=3.2.0 <4.0.0"\n\nexecutables:\n  {{kebab}}: main\n', t),
    ["bin/main.dart"] = fill('void main() {\n  print("Hello from {{NAME}}!");\n}\n', t),
    [".gitignore"] = ".dart_tool/\nbuild/\n",
  })
  return "Dart CLI 已生成"
end

gen.flutter = function(target, name)
  local t = project_tokens(name)
  if vim.fn.executable("flutter") == 1 then
    local out = vim.fn.system({ "flutter", "create", "--project-name", t.kebab, target })
    if vim.v.shell_error == 0 then return "Flutter 项目已生成" end
  end
  -- offline fallback
  write_tree(target, {
    ["pubspec.yaml"] = fill('name: {{kebab}}\ndescription: {{NAME}}\nversion: 1.0.0+1\n\nenvironment:\n  sdk: ">=3.2.0 <4.0.0"\n\ndependencies:\n  flutter:\n    sdk: flutter\n  cupertino_icons: ^1.0.6\n\nflutter:\n  uses-material-design: true\n', t),
    ["lib/main.dart"] = fill([[
import 'package:flutter/material.dart';
void main() => runApp(const MyApp());
class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '{{NAME}}',
      home: Scaffold(
        appBar: AppBar(title: const Text('{{NAME}}')),
        body: const Center(child: Text('Hello from {{NAME}}!')),
      ),
    );
  }
}
]], t),
    ["android/app/build.gradle"] = 'apply plugin: "com.android.application"\nandroid { namespace "com.example.' .. t.snake .. '" }\n',
    ["ios/Runner/Info.plist"] = "<dict><key>CFBundleName</key><string>" .. t.NAME .. "</string></dict>\n",
    [".gitignore"] = ".dart_tool/\nbuild/\n*.iml\n.idea/\n",
  })
  return "Flutter (离线骨架) 已生成"
end

-- ===== TypeScript / JavaScript =====
gen.ts_node = function(target, name)
  local t = project_tokens(name)
  write_tree(target, {
    ["package.json"] = fill('{"name":"{{kebab}}","version":"0.1.0","scripts":{"start":"ts-node src/index.ts"}}\n', t),
    ["tsconfig.json"] = '{"compilerOptions":{"target":"ES2022","module":"commonjs","strict":true,"esModuleInterop":true,"outDir":"dist"}}\n',
    ["src/index.ts"] = fill('console.log("Hello from {{NAME}}!");\n', t),
    [".gitignore"] = "node_modules/\ndist/\n",
  })
  return "TypeScript Node.js 已生成"
end

gen.express = function(target, name)
  local t = project_tokens(name)
  write_tree(target, {
    ["package.json"] = fill('{"name":"{{kebab}}","version":"0.1.0","scripts":{"start":"ts-node src/index.ts"}}\n', t),
    ["tsconfig.json"] = '{"compilerOptions":{"target":"ES2022","module":"commonjs","strict":true,"esModuleInterop":true,"outDir":"dist"}}\n',
    ["src/index.ts"] = fill([[
import express from "express";
const app = express();
app.get("/", (req, res) => res.send("Hello from {{NAME}}!"));
app.listen(3000, () => console.log("Server running on http://localhost:3000"));
]], t),
    ["src/routes.ts"] = 'import { Router } from "express";\nexport const router = Router();\n',
    [".gitignore"] = "node_modules/\ndist/\n",
  })
  return "Express + TypeScript 已生成"
end

gen.react_vite = function(target, name)
  local t = project_tokens(name)
  if vim.fn.executable("npm") == 1 then
    vim.fn.system({ "npm", "create", "vite@latest", t.kebab, "--", "--template", "react-ts" })
    if vim.v.shell_error == 0 then return "React (Vite + TypeScript) 已生成" end
  end
  write_tree(target, {
    ["package.json"] = fill('{"name":"{{kebab}}","scripts":{"dev":"vite","build":"vite build"}}\n', t),
    ["vite.config.ts"] = 'import { defineConfig } from "vite"\nimport react from "@vitejs/plugin-react"\nexport default defineConfig({ plugins: [react()] })\n',
    ["index.html"] = '<!DOCTYPE html><html><head><title>' .. t.NAME .. '</title></head><body><div id="root"></div><script type="module" src="/src/main.tsx"></script></body></html>\n',
    ["src/main.tsx"] = 'import React from "react"\nimport ReactDOM from "react-dom/client"\nReactDOM.createRoot(document.getElementById("root")!).render(<h1>Hello from ' .. t.NAME .. '!</h1>)\n',
    [".gitignore"] = "node_modules/\ndist/\n",
  })
  return "React + Vite 已生成"
end

gen.nextjs = function(target, name)
  local t = project_tokens(name)
  if vim.fn.executable("npx") == 1 then
    vim.fn.system({ "npx", "create-next-app@latest", t.kebab, "--typescript", "--eslint", "--app", "--no-src-dir" })
    if vim.v.shell_error == 0 then return "Next.js 已生成" end
  end
  write_tree(target, {
    ["package.json"] = fill('{"name":"{{kebab}}","scripts":{"dev":"next dev","build":"next build"}}\n', t),
    ["next.config.js"] = "/** @type {import('next').NextConfig} */\nmodule.exports = {}\n",
    ["app/page.tsx"] = fill('export default function Home() { return <h1>Hello from {{NAME}}!</h1> }\n', t),
    [".gitignore"] = "node_modules/\n.next/\n",
  })
  return "Next.js (离线骨架) 已生成"
end

gen.vue = function(target, name)
  local t = project_tokens(name)
  if vim.fn.executable("npm") == 1 then
    vim.fn.system({ "npm", "create", "vue@latest", t.kebab })
    if vim.v.shell_error == 0 then return "Vue 项目已生成" end
  end
  write_tree(target, {
    ["package.json"] = fill('{"name":"{{kebab}}","scripts":{"dev":"vite","build":"vite build"}}\n', t),
    ["vite.config.ts"] = 'import { defineConfig } from "vite"\nimport vue from "@vitejs/plugin-vue"\nexport default defineConfig({ plugins: [vue()] })\n',
    ["index.html"] = '<!DOCTYPE html><html><head><title>' .. t.NAME .. '</title></head><body><div id="app"></div><script type="module" src="/src/main.ts"></script></body></html>\n',
    ["src/main.ts"] = 'import { createApp } from "vue"\nimport App from "./App.vue"\ncreateApp(App).mount("#app")\n',
    ["src/App.vue"] = '<template><h1>Hello from ' .. t.NAME .. '!</h1></template>\n',
    [".gitignore"] = "node_modules/\ndist/\n",
  })
  return "Vue + Vite 已生成"
end

-- ===== PHP =====
gen.laravel = function(target, name)
  local t = project_tokens(name)
  if vim.fn.executable("composer") == 1 then
    vim.fn.system({ "composer", "create-project", "--prefer-dist", "laravel/laravel", t.kebab })
    if vim.v.shell_error == 0 then return "Laravel 已生成" end
  end
  write_tree(target, {
    ["composer.json"] = fill('{"name":"example/{{kebab}}","require":{"php":">=8.1","laravel/framework":"^10.0"}}\n', t),
    ["artisan"] = '#!/usr/bin/env php\n<?php\nrequire __DIR__."/vendor/autoload.php";\n$app = require_once __DIR__.'/bootstrap/app.php';\n$kernel = $app->make(Illuminate\\Contracts\\Console\\Kernel::class);\n$kernel->handle(new Symfony\\Component\\Console\\Input\\ArgvInput);\n',
    ["routes/web.php"] = fill("<?php\nuse Illuminate\\Support\\Facades\\Route;\nRoute::get('/', fn() => 'Hello from {{NAME}}!');\n", t),
    [".gitignore"] = "vendor/\n.env\n",
  })
  return "Laravel (离线骨架) 已生成"
end

gen.php_cli = function(target, name)
  local t = project_tokens(name)
  write_tree(target, {
    ["src/Main.php"] = fill("<?php\nnamespace {{snake}};\nclass Main {\n  public static function run(): void {\n    echo \"Hello from {{NAME}}!\\n\";\n  }\n}\n", t),
    ["composer.json"] = fill('{"name":"example/{{kebab}}","autoload":{"psr-4":{"{{snake}}/":"src/"}}}\n', t),
    [".gitignore"] = "vendor/\n",
  })
  return "PHP CLI 已生成"
end

-- ===== CSS =====
gen.tailwind = function(target, name)
  local t = project_tokens(name)
  write_tree(target, {
    ["package.json"] = fill('{"name":"{{kebab}}","scripts":{"build":"npx tailwindcss -i src/input.css -o dist/output.css --watch"}}\n', t),
    ["src/input.css"] = '@tailwind base;\n@tailwind components;\n@tailwind utilities;\n',
    ["tailwind.config.js"] = '/** @type {import("tailwindcss").Config} */\nmodule.exports = { content: ["*.html"], theme: { extend: {} }, plugins: [] }\n',
    ["index.html"] = fill('<!DOCTYPE html>\n<html lang="zh-CN">\n<head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0">\n<link rel="stylesheet" href="dist/output.css">\n<title>{{NAME}}</title></head>\n<body class="bg-gray-900 text-white flex items-center justify-center min-h-screen">\n<h1 class="text-4xl font-bold">Hello from {{NAME}}!</h1>\n</body>\n</html>\n', t),
    [".gitignore"] = "node_modules/\ndist/\n",
  })
  return "Tailwind CSS 已生成"
end

gen.static_html = function(target, name)
  local t = project_tokens(name)
  write_tree(target, {
    ["index.html"] = fill('<!DOCTYPE html>\n<html lang="zh-CN">\n<head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0">\n<title>{{NAME}}</title>\n<style>body{font-family:sans-serif;max-width:800px;margin:0 auto;padding:2rem;}</style>\n</head>\n<body>\n<h1>Hello from {{NAME}}!</h1>\n</body>\n</html>\n', t),
  })
  return "静态站点 已生成"
end

-- ===== DevOps =====
gen.docker = function(target, name)
  local t = project_tokens(name)
  write_tree(target, {
    ["docker-compose.yml"] = fill('services:\n  app:\n    build: .\n    container_name: {{kebab}}_app\n    ports:\n      - "8080:80"\n    restart: unless-stopped\n  db:\n    image: postgres:16-alpine\n    environment:\n      POSTGRES_USER: app\n      POSTGRES_PASSWORD: app\n      POSTGRES_DB: app\n    volumes:\n      - db_data:/var/lib/postgresql/data\nvolumes:\n  db_data:\n', t),
    ["Dockerfile"] = "FROM nginx:alpine\nCOPY . /usr/share/nginx/html\n",
    ["index.html"] = fill('<!DOCTYPE html><html><body><h1>Hello from {{NAME}}!</h1></body></html>\n', t),
    [".dockerignore"] = ".git\n*.md\n",
  })
  return "Docker Compose 已生成"
end

-- ---------------------------------------------------------------------------
-- Framework registry (flat list for selection)
-- Each entry: { label, lang, gen, main }
-- ---------------------------------------------------------------------------

M.frameworks = {
  -- Java
  { label = "Spring Boot (Java)",        lang = "java",       gen = gen.springboot, main = "pom.xml" },
  { label = "Java CLI (javac)",           lang = "java",       gen = gen.javacli,    main = "" },
  -- Kotlin
  { label = "Kotlin CLI",                lang = "kotlin",     gen = gen.kotlin_cli, main = "" },
  { label = "Android (Kotlin)",          lang = "kotlin",     gen = gen.android,    main = "" },
  { label = "Ktor 服务端 (Kotlin)",       lang = "kotlin",     gen = gen.ktor,       main = "" },
  -- C
  { label = "C + CMake",                 lang = "c",          gen = gen.cmake_c,    main = "src/main.c" },
  -- C++
  { label = "C++ + CMake (C++17)",       lang = "cpp",        gen = gen.cmake_cpp,  main = "src/main.cpp" },
  -- Go
  { label = "Go module",                 lang = "go",         gen = gen.gomod,      main = "main.go" },
  { label = "Go + Gin (Web)",            lang = "go",         gen = gen.gin,        main = "main.go" },
  { label = "Go + Fiber (Web)",          lang = "go",         gen = gen.fiber,      main = "main.go" },
  -- Rust
  { label = "Rust + Cargo",              lang = "rust",       gen = gen.cargo,      main = "src/main.rs" },
  { label = "Rust + Actix (Web)",        lang = "rust",       gen = gen.actix,      main = "src/main.rs" },
  { label = "Rust + Axum (Web)",         lang = "rust",       gen = gen.axum,       main = "src/main.rs" },
  -- Python
  { label = "Python package",            lang = "python",     gen = gen.py_pkg,     main = "" },
  { label = "FastAPI (Python)",          lang = "python",     gen = gen.fastapi,    main = "app/main.py" },
  { label = "Django (Python)",           lang = "python",     gen = gen.django,     main = "" },
  { label = "Flask (Python)",            lang = "python",     gen = gen.flask,      main = "app.py" },
  -- Dart
  { label = "Dart CLI",                  lang = "dart",       gen = gen.dart_cli,   main = "bin/main.dart" },
  { label = "Flutter (Dart)",            lang = "dart",       gen = gen.flutter,    main = "lib/main.dart" },
  -- TypeScript / JavaScript
  { label = "Node.js (TypeScript)",      lang = "typescript", gen = gen.ts_node,    main = "src/index.ts" },
  { label = "Express + TypeScript",      lang = "typescript", gen = gen.express,    main = "src/index.ts" },
  { label = "React + Vite (TS)",         lang = "typescript", gen = gen.react_vite, main = "" },
  { label = "Next.js (TS)",             lang = "typescript", gen = gen.nextjs,     main = "" },
  { label = "Vue + Vite (TS)",          lang = "typescript", gen = gen.vue,        main = "" },
  -- PHP
  { label = "Laravel (PHP)",             lang = "php",        gen = gen.laravel,    main = "" },
  { label = "PHP CLI",                   lang = "php",        gen = gen.php_cli,    main = "src/Main.php" },
  -- CSS
  { label = "Tailwind CSS",              lang = "css",        gen = gen.tailwind,   main = "index.html" },
  -- HTML
  { label = "静态站点 (HTML)",            lang = "html",       gen = gen.static_html, main = "index.html" },
  -- DevOps
  { label = "Docker Compose",            lang = "devops",     gen = gen.docker,     main = "docker-compose.yml" },
}

-- ---------------------------------------------------------------------------
-- selection window with search + grouped list
-- ---------------------------------------------------------------------------

local LIST_HEIGHT = 14
local WIN_WIDTH = 50
local SEARCH_HEIGHT = 1
local ns = vim.api.nvim_create_namespace("arkvim_picker")

local function sort_frameworks()
  local lang_order = {
    c = 1, cpp = 2, dart = 3, devops = 4, go = 5, html = 6,
    java = 7, kotlin = 8, php = 9, python = 10, rust = 11,
    typescript = 12, css = 13,
  }
  table.sort(M.frameworks, function(a, b)
    local la = lang_order[a.lang] or 99
    local lb = lang_order[b.lang] or 99
    if la ~= lb then return la < lb end
    return a.label < b.label
  end)
end

local function framework_picker(callback)
  sort_frameworks()
  local all = M.frameworks
  local filtered = vim.deepcopy(all)
  local cursor = 1
  local scroll_offset = 0
  local search_text = ""

  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].filetype = "arkvim-framework-picker"

  local total_h = SEARCH_HEIGHT + 1 + LIST_HEIGHT
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = WIN_WIDTH,
    height = total_h,
    row = math.floor((vim.o.lines - total_h) / 2),
    col = math.floor((vim.o.columns - WIN_WIDTH) / 2),
    style = "minimal",
    border = "rounded",
  })

  local function apply_filter()
    local q = search_text:lower()
    filtered = {}
    for _, f in ipairs(all) do
      if q == "" or f.label:lower():find(q, 1, true) or f.lang:lower():find(q, 1, true) then
        filtered[#filtered + 1] = f
      end
    end
    cursor = 1
    scroll_offset = 0
  end

  local function render()
    local visible = math.min(LIST_HEIGHT, #filtered)

    -- search line: simple text, no emoji
    local search_line = search_text == "" and " " or search_text
    local sep = string.rep("─", WIN_WIDTH - 2)

    -- list lines: original format "> label  (lang)"
    local lines = { search_line, sep }
    for i = scroll_offset + 1, math.min(scroll_offset + visible, #filtered) do
      local f = filtered[i]
      local mark = i == cursor and "> " or "  "
      lines[#lines + 1] = mark .. f.label .. "  (" .. f.lang .. ")"
    end
    while #lines < SEARCH_HEIGHT + 1 + visible + 1 do
      lines[#lines + 1] = ""
    end

    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

    -- highlights
    vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
    vim.api.nvim_buf_add_highlight(buf, ns, "Comment", 0, 0, -1)
    local list_start = SEARCH_HEIGHT + 1
    local sel_row = list_start + (cursor - scroll_offset)
    if sel_row >= list_start and sel_row < list_start + visible then
      vim.api.nvim_buf_add_highlight(buf, ns, "Visual", sel_row, 0, -1)
    end
  end

  local function move(delta)
    cursor = math.max(1, math.min(#filtered, cursor + delta))
    local visible = math.min(LIST_HEIGHT, #filtered)
    if cursor <= scroll_offset then
      scroll_offset = cursor - 1
    elseif cursor > scroll_offset + visible then
      scroll_offset = cursor - visible
    end
    render()
  end

  local function select()
    local chosen = filtered[cursor]
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
    if chosen then callback(chosen) end
  end

  local function cancel()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end

  -- keymaps
  local km = { buffer = buf, silent = true, nowait = true, noremap = true }
  -- navigation
  vim.keymap.set("n", "j", function() move(1) end, km)
  vim.keymap.set("n", "<Down>", function() move(1) end, km)
  vim.keymap.set("n", "k", function() move(-1) end, km)
  vim.keymap.set("n", "<Up>", function() move(-1) end, km)
  vim.keymap.set("n", "<C-d>", function() move(7) end, km)
  vim.keymap.set("n", "<C-u>", function() move(-7) end, km)
  vim.keymap.set("n", "G", function() cursor = #filtered; scroll_offset = math.max(0, #filtered - LIST_HEIGHT); render() end, km)
  vim.keymap.set("n", "gg", function() cursor = 1; scroll_offset = 0; render() end, km)
  -- select / cancel
  vim.keymap.set("n", "<CR>", select, km)
  vim.keymap.set("n", "<Space>", select, km)
  vim.keymap.set("n", "q", cancel, km)
  vim.keymap.set("n", "<Esc>", cancel, km)
  -- search: start in insert mode in the search line
  vim.api.nvim_win_set_cursor(win, { 1, 0 })
  vim.cmd("startinsert!")
  vim.keymap.set("i", "<Esc>", function() vim.cmd("stopinsert"); cancel() end, km)
  vim.keymap.set("i", "<CR>", function() vim.cmd("stopinsert"); select() end, km)
  vim.keymap.set("i", "<C-s>", function() vim.cmd("stopinsert"); select() end, km)
  vim.keymap.set("i", "<C-q>", function() vim.cmd("stopinsert"); cancel() end, km)
  -- search input: capture typed characters
  vim.keymap.set("i", "<BS>", function()
    search_text = search_text:sub(1, -2)
    apply_filter()
    render()
    -- keep cursor at end of search line
    local line = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1]
    vim.api.nvim_win_set_cursor(win, { 1, #line })
  end, km)
  vim.keymap.set("i", "<C-h>", function()
    search_text = search_text:sub(1, -2)
    apply_filter()
    render()
    local line = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1]
    vim.api.nvim_win_set_cursor(win, { 1, #line })
  end, km)
  -- any printable char → search
  for i = 32, 126 do
    local c = string.char(i)
    if c ~= "<" and c ~= "/" and c ~= "\\" then
      vim.keymap.set("i", c, function()
        search_text = search_text .. c
        apply_filter()
        render()
        local line = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1]
        vim.api.nvim_win_set_cursor(win, { 1, #line })
      end, km)
    end
  end
  -- arrow keys in insert mode for list navigation
  vim.keymap.set("i", "<C-j>", function() vim.cmd("stopinsert"); move(1) end, km)
  vim.keymap.set("i", "<C-k>", function() vim.cmd("stopinsert"); move(-1) end, km)
  vim.keymap.set("i", "<Down>", function() vim.cmd("stopinsert"); move(1) end, km)
  vim.keymap.set("i", "<Up>", function() vim.cmd("stopinsert"); move(-1) end, km)

  render()
end

-- ---------------------------------------------------------------------------
-- entry point
-- ---------------------------------------------------------------------------

function M.create()
  framework_picker(function(framework)
    local cwd = vim.fn.getcwd()
    local name = vim.fn.input("项目名: ", vim.fn.fnamemodify(cwd, ":t"))
    name = name:gsub("%s+", "-")
    if name == "" then name = "myapp" end
    local target = cwd .. "/" .. name
    if vim.fn.isdirectory(target) == 1 or vim.fn.filereadable(target) == 1 then
      notify("已存在同名文件/目录: " .. target, _log.ERROR)
      return
    end
    mkdir_p(target)
    local ok, res = pcall(framework.gen, target, name)
    if not ok then
      notify("生成失败: " .. tostring(res), _log.ERROR)
      vim.fn.system({ "rm", "-rf", target })
      return
    end
    -- save metadata for build module
    M.save_metadata(target, {
      lang = framework.lang,
      label = framework.label,
      main = framework.main or "",
    })
    vim.g.arkvim_project_main = framework.main or ""
    vim.cmd("cd " .. vim.fn.fnameescape(target))
    notify(target .. "\n" .. res .. "\n已进入项目目录")
    local main = framework.main or ""
    if main ~= "" then
      pcall(vim.cmd, "edit " .. vim.fn.fnameescape(target .. "/" .. main))
    end
  end)
end

--- Save project metadata to stdpath("state")/arkvim/projects.json
function M.save_metadata(root, data)
  local dir = vim.fn.stdpath("state") .. "/arkvim"
  vim.fn.mkdir(dir, "p")
  local file = dir .. "/projects.json"
  local db = {}
  if vim.fn.filereadable(file) == 1 then
    local ok, decoded = pcall(vim.fn.json_decode, vim.fn.readfile(file))
    if ok and type(decoded) == "table" then db = decoded end
  end
  db[root] = data
  vim.fn.writefile({ vim.fn.json_encode(db) }, file)
end

--- Load project metadata (returns table or nil)
function M.load_metadata(root)
  local file = vim.fn.stdpath("state") .. "/arkvim/projects.json"
  if vim.fn.filereadable(file) == 0 then return nil end
  local ok, db = pcall(vim.fn.json_decode, vim.fn.readfile(file))
  if not ok or type(db) ~= "table" then return nil end
  return db[root]
end

return M
