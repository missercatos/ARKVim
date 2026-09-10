-- ARKVIM scaffold: one-key project generator
-- Pick a language -> pick a framework template -> type a name,
-- the pre-built project skeleton is created in the current directory.
--     <leader>pc   (see lua/config/keymaps.lua)
--
-- Available scaffolds:
--   Java   : Spring Boot (start.spring.io, offline fallback) / plain javac
--   C      : CMake
--   C++    : CMake
--   Go     : go module
--   Rust   : cargo binary
--   Python : package / FastAPI
--   DevOps : docker compose stack
-- Add new entries to `langs[].frameworks[]` with a `gen` function.

local M = {}

local _log = vim.log.levels

-- ---------------------------------------------------------------------------
-- helpers
-- ---------------------------------------------------------------------------

local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO)
end

local function shellescape(s)
  return vim.fn.shellescape(s)
end

local function slug(name)
  local s = string.lower(tostring(name or ""))
  s = s:gsub("[^%w]+", "-")
  s = s:gsub("^-+", ""):gsub("-+$", "")
  if s == "" then
    s = "app"
  end
  return s
end

local function snake(name)
  return slug(name):gsub("-", "_")
end

local function pascal(name)
  local parts = {}
  for p in slug(name):gsub("-", "_"):gsub("_", " "):gmatch("%S+") do
    parts[#parts + 1] = p:sub(1, 1):upper() .. p:sub(2)
  end
  return table.concat(parts)
end

---@param content string
---@param t table<string,string>
local function fill(content, t)
  return (content:gsub("{{(%w+)}}", function(k)
    return t[k] or ("{{" .. k .. "}}")
  end))
end

---@param root string
---@param files table<string,string> relpath -> content
local function write_tree(root, files)
  for rel, content in pairs(files) do
    local path = root .. "/" .. rel
    vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")
    local lines = vim.split(content, "\n", { plain = true })
    if lines[#lines] == "" then
      lines[#lines] = nil
    end
    vim.fn.writefile(lines, path)
  end
end

local function project_tokens(name)
  local kebab = slug(name)
  return {
    NAME = name,
    kebab = kebab,
    snake = snake(name),
    Pascal = pascal(name),
    pkg = "com.example." .. snake(name),
  }
end

--- Extract a zip that has a single top-level directory into `target`.
local function unzip_strip(zip, target)
  local tmp = vim.fn.tempname()
  vim.fn.mkdir(tmp, "p")
  vim.fn.system({ "unzip", "-oq", zip, "-d", tmp })
  if vim.v.shell_error ~= 0 then
    vim.fn.system({ "rm", "-rf", tmp })
    return false
  end
  local dirs = vim.fn.glob(tmp .. "/*/", false, true)
  local inner = #dirs == 1 and vim.fn.substitute(dirs[1], "/$", "", "") or tmp
  vim.fn.system({ "cp", "-a", inner .. "/.", target })
  local ok = vim.v.shell_error == 0
  vim.fn.system({ "rm", "-rf", tmp })
  return ok
end

local function mkdir_p(dir)
  vim.fn.mkdir(dir, "p")
end

-- ---------------------------------------------------------------------------
-- generators
-- ---------------------------------------------------------------------------

local gen = {}

-- ===== Java: Spring Boot (start.spring.io, offline fallback) =====
gen.springboot = function(target, name)
  local t = project_tokens(name)
  mkdir_p(target)

  local zip = vim.fn.tempname() .. ".zip"
  local url = string.format(
    "https://start.spring.io/starter.zip?type=maven-project&language=java"
      .. "&groupId=com.example&artifactId=%s&name=%s&packageName=%s"
      .. "&packaging=jar&javaVersion=17&dependencies=web,devtools,validation,lombok",
    t.kebab,
    t.NAME,
    t.pkg
  )
  vim.fn.system({ "curl", "-fsSL", "--max-time", "90", "-o", zip, url })

  if vim.v.shell_error == 0 and vim.fn.filereadable(zip) == 1 then
    local ok = unzip_strip(zip, target)
    if ok then
      vim.fn.system({ "rm", "-f", zip })
      return "Spring Boot (start.spring.io) 已生成"
    end
  end
  vim.fn.system({ "rm", "-f", zip })

  -- offline fallback: minimal Spring Boot web app
  local files = {
    ["pom.xml"] = fill([[
<?xml version="1.0" encoding="UTF-8"?>
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
  <description>Demo project for Spring Boot</description>
  <properties>
    <java.version>17</java.version>
  </properties>
  <dependencies>
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-web</artifactId>
    </dependency>
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-test</artifactId>
      <scope>test</scope>
    </dependency>
  </dependencies>
  <build>
    <plugins>
      <plugin>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-maven-plugin</artifactId>
      </plugin>
    </plugins>
  </build>
</project>
]], t),
    [("src/main/java/com/example/%s/%sApplication.java"):format(t.snake, t.Pascal)] = fill([[
package com.example.{{snake}};

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@SpringBootApplication
@RestController
public class {{Pascal}}Application {

  public static void main(String[] args) {
    SpringApplication.run({{Pascal}}Application.class, args);
  }

  @GetMapping("/")
  public String hello() {
    return "Hello from {{NAME}}!";
  }
}
]], t),
    ["src/main/resources/application.yml"] = [[
server:
  port: 8080
]],
    ["src/test/java/com/example/" .. t.snake .. "/" .. t.Pascal .. "ApplicationTests.java"] = fill([[
package com.example.{{snake}};

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;

@SpringBootTest
class {{Pascal}}ApplicationTests {

  @Test
  void contextLoads() {
  }
}
]], t),
    [".gitignore"] = [[
target/
*.class
*.jar
!.mvn/wrapper/maven-wrapper.jar
.idea/
*.iml
.vscode/
]],
    ["README.md"] = fill([[# {{NAME}}

Minimal Spring Boot skeleton (offline fallback).

Run with:

```bash
mvn spring-boot:run
```
]], t),
  }
  write_tree(target, files)
  return "Spring Boot (离线最小骨架) 已生成"
end

-- ===== Java: plain javac =====
gen.javacli = function(target, name)
  local t = project_tokens(name)
  local files = {
    ["src/" .. t.snake .. "/Main.java"] = fill([[
package {{snake}};

public class Main {
  public static void main(String[] args) {
    System.out.println("Hello from {{NAME}}!");
  }
}
]], t),
    ["Makefile"] = ("JAVAC := javac\nJAVA  := java\n\nbuild:\n@TAB@$(JAVAC) -d out src/%s/Main.java\n\nrun: build\n@TAB@$(JAVA) -cp out %s.Main\n\n.PHONY: build run\n"):format(t.snake, t.snake):gsub("@TAB@", "\t"),
    [".gitignore"] = "out/\n*.class\n",
    ["README.md"] = fill([[# {{NAME}}

Plain Java CLI. Compile & run:

```bash
make run
```
]], t),
  }
  write_tree(target, files)
  return "Java (plain) 已生成"
end

-- ===== C: CMake =====
gen.cmake_c = function(target, name)
  local t = project_tokens(name)
  local files = {
    ["CMakeLists.txt"] = fill([[
cmake_minimum_required(VERSION 3.16)
project({{NAME}} C)

set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)

if(NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE Debug)
endif()

add_executable({{kebab}} src/main.c)
]], t),
    ["src/main.c"] = fill([[
#include <stdio.h>

int main(void) {
  printf("Hello from {{NAME}}!\n");
  return 0;
}
]], t),
    ["build.sh"] = "#!/usr/bin/env bash\nset -e\ncmake -S . -B build\ncmake --build build\n./build/{{kebab}}\n",
    [".gitignore"] = "build/\n",
    ["README.md"] = fill([[# {{NAME}}

C project built with CMake.

```bash
./build.sh
```
]], t),
  }
  write_tree(target, files)
  -- substitute the project name inside build.sh as well
  local sh = target .. "/build.sh"
  local content = table.concat(vim.fn.readfile(sh), "\n"):gsub("{{kebab}}", t.kebab)
  vim.fn.writefile(vim.split(content, "\n", { plain = true }), sh)
  vim.fn.setfperm(sh, "rwxr-xr-x")
  return "C + CMake 已生成"
end

-- ===== C++: CMake =====
gen.cmake_cpp = function(target, name)
  local t = project_tokens(name)
  local files = {
    ["CMakeLists.txt"] = fill([[
cmake_minimum_required(VERSION 3.16)
project({{NAME}} CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

if(NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE Debug)
endif()

add_executable({{kebab}} src/main.cpp)
target_include_directories({{kebab}} PRIVATE include)
]], t),
    ["src/main.cpp"] = fill([[
#include <iostream>

int main() {
  std::cout << "Hello from {{NAME}}!" << std::endl;
  return 0;
}
]], t),
    ["include/" .. t.snake .. "/version.h"] = fill([[
#pragma once
#define {{Pascal}}_VERSION "0.1.0"
]], t),
    ["build.sh"] = "#!/usr/bin/env bash\nset -e\ncmake -S . -B build\ncmake --build build\n./build/{{kebab}}\n",
    [".gitignore"] = "build/\n",
    ["README.md"] = fill([[# {{NAME}}

C++ project built with CMake (C++17).

```bash
./build.sh
```
]], t),
  }
  write_tree(target, files)
  local sh = target .. "/build.sh"
  local content = table.concat(vim.fn.readfile(sh), "\n"):gsub("{{kebab}}", t.kebab)
  vim.fn.writefile(vim.split(content, "\n", { plain = true }), sh)
  vim.fn.setfperm(sh, "rwxr-xr-x")
  return "C++ + CMake 已生成"
end

-- ===== Go: go module =====
gen.gomod = function(target, name)
  local t = project_tokens(name)
  local module = string.format("example.com/%s", t.kebab)
  if vim.fn.executable("go") == 1 then
    local out = vim.fn.system({ "go", "env", "GOMODCACHE" })
    -- ignore, we just keep a readable module path below
  end
  local files = {
    ["go.mod"] = ("module %s\n\ngo 1.22\n"):format(module),
    ["main.go"] = fill([[
package main

import "fmt"

func main() {
	fmt.Println("Hello from {{NAME}}!")
}
]], t),
    [".gitignore"] = "{{kebab}}\n*.exe\n",
    ["README.md"] = fill([[# {{NAME}}

Go module `{{module}}`.

```bash
go run .
```
]], { NAME = t.NAME, module = module, kebab = t.kebab }),
  }
  files[".gitignore"] = files[".gitignore"]:gsub("{{kebab}}", t.kebab)
  write_tree(target, files)
  return "Go module 已生成"
end

-- ===== Rust: cargo binary =====
gen.cargo = function(target, name)
  local t = project_tokens(name)
  local crate = t.kebab:gsub("-", "_")
  local files = {
    ["Cargo.toml"] = fill([[
[package]
name = "{{kebab}}"
version = "0.1.0"
edition = "2021"

[dependencies]
]], t),
    ["src/main.rs"] = fill([[
fn main() {
    println!("Hello from {{NAME}}!");
}
]], t),
    [".gitignore"] = "/target\n",
    ["README.md"] = fill([[# {{NAME}}

Rust binary crate.

```bash
cargo run
```
]], t),
  }
  write_tree(target, files)
  return "Rust + cargo 已生成 (crate: " .. crate .. ")"
end

-- ===== Python: package =====
gen.py_pkg = function(target, name)
  local t = project_tokens(name)
  local files = {
    ["pyproject.toml"] = fill([[
[build-system]
requires = ["setuptools>=68"]
build-backend = "setuptools.build_meta"

[project]
name = "{{kebab}}"
version = "0.1.0"
description = "{{NAME}}"
requires-python = ">=3.9"

[project.optional-dependencies]
dev = ["pytest"]

[tool.setuptools.packages.find]
where = ["src"]
]], t),
    ["src/" .. t.snake .. "/__init__.py"] = fill([["""{{NAME}} package."""

__version__ = "0.1.0"
]], t),
    ["src/" .. t.snake .. "/__main__.py"] = fill([[
from {{snake}} import __version__


def main() -> None:
    print(f"Hello from {{NAME}} (v{__version__})")


if __name__ == "__main__":
    main()
]], t),
    ["tests/test_" .. t.snake .. ".py"] = fill([[
from {{snake}} import __version__


def test_version():
    assert __version__ == "0.1.0"
]], t),
    ["README.md"] = fill([[# {{NAME}}

```bash
python -m venv .venv && source .venv/bin/activate
pip install -e ".[dev]"
python -m {{snake}}
pytest
```
]], t),
    [".gitignore"] = ".venv/\n__pycache__/\n*.egg-info/\ndist/\nbuild/\n",
  }
  write_tree(target, files)
  return "Python package 已生成"
end

-- ===== Python: FastAPI =====
gen.fastapi = function(target, name)
  local t = project_tokens(name)
  local files = {
    ["app/__init__.py"] = "",
    ["app/main.py"] = fill([[
from fastapi import FastAPI

app = FastAPI(title="{{NAME}}")


@app.get("/")
def read_root():
    return {"message": "Hello from {{NAME}}!"}
]], t),
    ["requirements.txt"] = "fastapi>=0.110\nuvicorn[standard]>=0.29\n",
    ["README.md"] = fill([[# {{NAME}}

FastAPI project.

```bash
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload
```
]], t),
    [".gitignore"] = ".venv/\n__pycache__/\n*.egg-info/\n",
  }
  write_tree(target, files)
  return "FastAPI 已生成"
end

-- ===== DevOps: docker compose stack =====
gen.docker = function(target, name)
  local t = project_tokens(name)
  local files = {
    ["docker-compose.yml"] = fill([[
services:
  app:
    build: .
    container_name: {{kebab}}_app
    ports:
      - "8080:80"
    restart: unless-stopped

  db:
    image: postgres:16-alpine
    container_name: {{kebab}}_db
    environment:
      POSTGRES_USER: app
      POSTGRES_PASSWORD: app
      POSTGRES_DB: app
    volumes:
      - db_data:/var/lib/postgresql/data

volumes:
  db_data:
]], t),
    ["Dockerfile"] = [[
FROM nginx:alpine
COPY . /usr/share/nginx/html
]],
    ["index.html"] = fill([[
<!DOCTYPE html>
<html lang="zh-CN">
<head>
  <meta charset="UTF-8">
  <title>{{NAME}}</title>
</head>
<body>
  <h1>Hello from {{NAME}}!</h1>
</body>
</html>
]], t),
    [".dockerignore"] = ".git\n*.md\n",
    ["README.md"] = fill([[# {{NAME}}

Docker Compose stack.

```bash
docker compose up -d --build
docker compose ps
docker compose logs -f
docker compose down
```
]], t),
  }
  write_tree(target, files)
  return "Docker Compose 已生成"
end

-- ===== registry =====
M.langs = {
  {
    label = "Java",
    frameworks = {
      { label = "Spring Boot (start.spring.io / 离线回退)", gen = gen.springboot, main = "pom.xml" },
      { label = "Plain Java (javac)", gen = gen.javacli, main = "" },
    },
  },
  {
    label = "C",
    frameworks = {
      { label = "CMake project", gen = gen.cmake_c, main = "src/main.c" },
    },
  },
  {
    label = "C++",
    frameworks = {
      { label = "CMake project (C++17)", gen = gen.cmake_cpp, main = "src/main.cpp" },
    },
  },
  {
    label = "Go",
    frameworks = {
      { label = "go module", gen = gen.gomod, main = "main.go" },
    },
  },
  {
    label = "Rust",
    frameworks = {
      { label = "cargo binary", gen = gen.cargo, main = "src/main.rs" },
    },
  },
  {
    label = "Python",
    frameworks = {
      { label = "Python package (setuptools)", gen = gen.py_pkg, main = "" },
      { label = "FastAPI web app", gen = gen.fastapi, main = "app/main.py" },
    },
  },
  {
    label = "DevOps",
    frameworks = {
      { label = "Docker Compose stack", gen = gen.docker, main = "docker-compose.yml" },
    },
  },
}

-- ---------------------------------------------------------------------------
-- entry point
-- ---------------------------------------------------------------------------

local function pick(prompt, items, cb)
  vim.ui.select(items, {
    prompt = prompt,
    format_item = function(item)
      return item.label
    end,
  }, function(choice)
    if choice then
      cb(choice)
    end
  end)
end

--- Language -> default file extension map (used by autocmds + <space>a)
M.lang_ext = {
  java = "java", python = "py", rust = "rs", go = "go",
  c = "c", cpp = "cpp", devops = "yml",
}

function M.create()
  pick("选择语言", M.langs, function(lang)
    pick("选择框架模板 (" .. lang.label .. ")", lang.frameworks, function(tpl)
      local cwd = vim.fn.getcwd()
      local name = vim.fn.input("项目名: ", vim.fn.fnamemodify(cwd, ":t"))
      name = name:gsub("%s+", "-")
      if name == "" then
        name = "myapp"
      end
      local target = cwd .. "/" .. name
      if vim.fn.isdirectory(target) == 1 or vim.fn.filereadable(target) == 1 then
        notify("已存在同名文件/目录: " .. target, _log.ERROR)
        return
      end
      mkdir_p(target)
      local ok, res = pcall(tpl.gen, target, name)
      if not ok then
        notify("生成失败: " .. tostring(res), _log.ERROR)
        vim.fn.system({ "rm", "-rf", target })
        return
      end

      -- Set project language for auto-extension (autocmds + <space>a)
      local lang_key = lang.label:lower()
      if lang_key == "c++" then
        lang_key = "cpp"
      elseif lang_key == "devops" then
        lang_key = "devops"
      end
      vim.g.arkvim_project_lang = lang_key
      vim.g.arkvim_project_main = tpl.main or ""

      -- cd into the project so <space>e tree shows only this project
      vim.cmd("cd " .. vim.fn.fnameescape(target))
      notify(target .. "\n" .. res .. "\n已进入项目目录")

      -- Auto-open the main file
      local main = tpl.main or ""
      if main ~= "" then
        pcall(vim.cmd, "edit " .. vim.fn.fnameescape(target .. "/" .. main))
      end
    end)
  end)
end

return M
