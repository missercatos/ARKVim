-- arkvim/scaffold/systems.lua — 系统级语言 / 少见语言模板
-- Zig / Nim / Crystal / D / Haskell / OCaml / Lisp / Scheme / Racket /
-- Erlang / Elixir / Julia / Swift / C# / Clojure / Scala
local util = require("arkvim.scaffold.util")

local M = {}
local gen = {}

-- ===== Zig =====
gen.zig = function(target, name)
  local t = util.project_tokens(name)
  util.write_tree(target, {
    ["build.zig"] = util.fill([[const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "{{kebab}}",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| run_cmd.addArgs(args);

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
]], t),
    ["src/main.zig"] = util.fill([[const std = @import("std");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("Hello from {{NAME}}!\n", .{});
}
]], t),
    [".gitignore"] = "zig-cache/\nzig-out/\n",
  })
  return "Zig 项目已生成"
end

-- ===== Nim =====
gen.nim = function(target, name)
  local t = util.project_tokens(name)
  util.write_tree(target, {
    [t.snake .. ".nimble"] = util.fill([[version       = "0.1.0"
author        = "you"
description   = "{{NAME}}"
license       = "MIT"
srcDir        = "src"

requires "nim >= 1.6.0"
]], t),
    ["src/main.nim"] = util.fill('echo "Hello from {{NAME}}!"\n', t),
    [".gitignore"] = "nimcache/\n",
  })
  return "Nim 项目已生成"
end

-- ===== Crystal =====
gen.crystal = function(target, name)
  local t = util.project_tokens(name)
  util.write_tree(target, {
    ["shard.yml"] = util.fill([[name: {{kebab}}
version: 0.1.0

targets:
  {{kebab}}:
    main: src/main.cr
]], t),
    ["src/main.cr"] = util.fill('puts "Hello from {{NAME}}!"\n', t),
    [".gitignore"] = "bin/\nlib/\nshard.lock\n",
  })
  return "Crystal 项目已生成"
end

-- ===== D =====
gen.dlang = function(target, name)
  local t = util.project_tokens(name)
  util.write_tree(target, {
    ["dub.json"] = util.fill('{\n  "name": "{{kebab}}",\n  "description": "{{NAME}}",\n  "authors": ["you"],\n  "license": "MIT",\n  "targetType": "executable"\n}\n', t),
    ["source/app.d"] = util.fill('import std.stdio;\n\nvoid main()\n{\n    writeln("Hello from {{NAME}}!");\n}\n', t),
    [".gitignore"] = ".dub/\n*.o\n",
  })
  return "D (dub) 项目已生成"
end

-- ===== Haskell =====
gen.haskell = function(target, name)
  local t = util.project_tokens(name)
  util.write_tree(target, {
    [t.kebab .. ".cabal"] = util.fill([[cabal-version:      2.4
name:               {{kebab}}
version:            0.1.0.0
build-type:         Simple
synopsis:           {{NAME}}

executable {{kebab}}
    main-is:          Main.hs
    hs-source-dirs:   app
    build-depends:    base ^>=4.17
    default-language: Haskell2010
]], t),
    ["app/Main.hs"] = util.fill([[module Main (main) where

main :: IO ()
main = putStrLn "Hello from {{NAME}}!"
]], t),
    ["Makefile"] = "build:\n\tcabal build\n\nrun:\n\tcabal run " .. t.kebab .. "\n\n.PHONY: build run\n",
    [".gitignore"] = "dist-newstyle/\n",
  })
  return "Haskell (cabal) 项目已生成"
end

-- ===== OCaml =====
gen.ocaml = function(target, name)
  local t = util.project_tokens(name)
  util.write_tree(target, {
    ["dune-project"] = "(lang dune 3.0)\n",
    ["bin/dune"] = util.fill("(executable\n (name main)\n (public_name {{kebab}}))\n", t),
    ["bin/main.ml"] = util.fill('let () = print_endline "Hello from {{NAME}}!"\n', t),
    [".gitignore"] = "_build/\n",
  })
  return "OCaml (dune) 项目已生成"
end

-- ===== Common Lisp =====
gen.commonlisp = function(target, name)
  local t = util.project_tokens(name)
  util.write_tree(target, {
    [t.kebab .. ".asd"] = util.fill([[(defsystem "{{kebab}}"
  :version "0.1.0"
  :depends-on ()
  :components ((:file "main"))
  :build-operation "program-op"
  :build-pathname "{{kebab}}"
  :entry-point "{{kebab}}:main")
]], t),
    ["main.lisp"] = util.fill([[(defpackage #:{{kebab}}
  (:use #:cl)
  (:export #:main))

(in-package #:{{kebab}})

(defun main ()
  (format t "Hello from {{NAME}}!~%"))

;; 直接脚本运行：sbcl --script main.lisp
(main)
]], t),
    ["Makefile"] = "run:\n\tsbcl --script main.lisp\n\nbuild:\n\tsbcl --eval '(asdf:load-asd (truename \"" .. t.kebab .. ".asd\"))' \\\n\t     --eval '(asdf:operate :build-op :" .. t.kebab .. ")'\n\n.PHONY: run build\n",
    [".gitignore"] = "*.fasl\n",
  })
  return "Common Lisp (SBCL) 项目已生成"
end

-- ===== Scheme (Guile) =====
gen.scheme = function(target, name)
  local t = util.project_tokens(name)
  util.write_tree(target, {
    ["main.scm"] = util.fill('(display "Hello from {{NAME}}!")\n(newline)\n', t),
    ["Makefile"] = "run:\n\tguile main.scm\n\n.PHONY: run\n",
    [".gitignore"] = "*.go\n",
  })
  return "Scheme (Guile) 项目已生成"
end

-- ===== Racket =====
gen.racket = function(target, name)
  local t = util.project_tokens(name)
  util.write_tree(target, {
    ["info.rkt"] = util.fill('#lang info\n(define collection "{{kebab}}")\n', t),
    ["main.rkt"] = util.fill('#lang racket\n\n(displayln "Hello from {{NAME}}!")\n', t),
    ["Makefile"] = "run:\n\tracket main.rkt\n\n.PHONY: run\n",
    [".gitignore"] = "compiled/\n",
  })
  return "Racket 项目已生成"
end

-- ===== Erlang =====
gen.erlang = function(target, name)
  local t = util.project_tokens(name)
  util.write_tree(target, {
    ["rebar.config"] = "{erl_opts, [debug_info]}.\n{deps, []}.\n",
    ["src/" .. t.snake .. ".app.src"] = util.fill([[{application, {{snake}},
 [{description, "{{NAME}}"},
  {vsn, "0.1.0"},
  {registered, []},
  {mod, {{{snake}}_app, []}},
  {applications, [kernel, stdlib]},
  {env, []}
 ]}.
]], t),
    ["src/" .. t.snake .. "_app.erl"] = util.fill([[-module({{snake}}_app).
-behaviour(application).
-export([start/2, stop/1]).

start(_Type, _Args) ->
    {{snake}}_sup:start_link().

stop(_State) ->
    ok.
]], t),
    ["src/" .. t.snake .. "_sup.erl"] = util.fill([[-module({{snake}}_sup).
-behaviour(supervisor).
-export([start_link/0, init/1]).

start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

init([]) ->
    {ok, {#{strategy => one_for_one, intensity => 1, period => 5}, []}}.
]], t),
    ["src/hello.erl"] = util.fill('%% -*- erlang -*-\n-module(hello).\n-export([main/0]).\n\nmain() ->\n    io:format("Hello from {{NAME}}!~n").\n', t),
    [".gitignore"] = "_build/\n*.beam\n",
  })
  return "Erlang (rebar3) 项目已生成"
end

-- ===== Elixir =====
gen.elixir = function(target, name)
  local t = util.project_tokens(name)
  util.write_tree(target, {
    ["mix.exs"] = util.fill([=[defmodule {{Pascal}}.MixProject do
  use Mix.Project

  def project do
    [
      app: :{{snake}},
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps, do: []
end
]=], t),
    ["lib/" .. t.snake .. ".ex"] = util.fill([[defmodule {{Pascal}} do
  @moduledoc "{{NAME}}"

  def hello, do: IO.puts("Hello from {{NAME}}!")
end
]], t),
    ["test/test_helper.exs"] = "ExUnit.start()\n",
    ["test/" .. t.snake .. "_test.exs"] = util.fill('defmodule {{Pascal}}Test do\n  use ExUnit.Case\n\n  test "hello" do\n    assert {{Pascal}}.hello() == :ok\n  end\nend\n', t),
    [".gitignore"] = "_build/\ndeps/\n*.ez\n",
    ["README.md"] = util.fill("# {{NAME}}\n\n```bash\nmix run -e '{{Pascal}}.hello()'\nmix test\n```\n", t),
  })
  return "Elixir (mix) 项目已生成"
end

-- ===== Elixir + Phoenix =====
gen.phoenix = function(target, name)
  local t = util.project_tokens(name)
  if util.executable("mix") then
    local out = vim.fn.system({ "mix", "phx.new", t.kebab, "--path", target, "--no-install", "--no-ecto" })
    if vim.v.shell_error == 0 then
      return "Phoenix 项目已生成（先 cd 进目录运行 mix deps.get）"
    end
  end
  -- 离线兜底：Plug/Cowboy 的最小 Web 骨架
  util.write_tree(target, {
    ["mix.exs"] = util.fill([[defmodule {{Pascal}}.MixProject do
  use Mix.Project

  def project do
    [
      app: :{{snake}},
      version: "0.1.0",
      elixir: "~> 1.15",
      deps: [
        {:plug_cowboy, "~> 2.7"}
      ]
    ]
  end

  def application do
    [extra_applications: [:logger], mod: {{{Pascal}}.Application}]
  end
end
]], t),
    ["lib/" .. t.snake .. "/application.ex"] = util.fill([[defmodule {{Pascal}}.Application do
  use Application

  def start(_type, _args) do
    children = [
      {Plug.Cowboy, scheme: :http, plug: {{Pascal}}.Router, options: [port: 4000]}
    ]
    Supervisor.start_link(children, strategy: :one_for_one, name: {{Pascal}}.Supervisor)
  end
end
]], t),
    ["lib/" .. t.snake .. "/router.ex"] = util.fill([[defmodule {{Pascal}}.Router do
  use Plug.Router

  plug :match
  plug :dispatch

  get "/" do
    send_resp(conn, 200, "Hello from {{NAME}}!")
  end
end
]], t),
    ["README.md"] = util.fill("# {{NAME}} (离线兜底骨架)\n\n想要完整 Phoenix：安装 elixir 后 `mix archive.install hex phx_new` 再重新生成。\n\n```bash\nmix deps.get\nmix run --no-halt\n```\n", t),
  })
  return "Elixir Web 骨架已生成（未检测到 mix，用的是 Plug/Cowboy 兜底）"
end

-- ===== Julia =====
gen.julia = function(target, name)
  local t = util.project_tokens(name)
  util.write_tree(target, {
    ["Project.toml"] = util.fill('name = "{{Pascal}}"\nuuid = "{{uuid}}"\nauthors = ["you"]\nversion = "0.1.0"\n\n[deps]\n', t),
    ["src/" .. t.Pascal .. ".jl"] = util.fill([[module {{Pascal}}

greet() = println("Hello from {{NAME}}!")

end # module
]], t),
    ["main.jl"] = util.fill('include("src/{{Pascal}}.jl")\nusing .{{Pascal}}\n\n{{Pascal}}.greet()\n', t),
    ["Makefile"] = "run:\n\tjulia main.jl\n\n.PHONY: run\n",
    [".gitignore"] = "Manifest.toml\n",
  })
  return "Julia 项目已生成"
end

-- ===== Swift (SPM) =====
gen.swift = function(target, name)
  local t = util.project_tokens(name)
  util.write_tree(target, {
    ["Package.swift"] = util.fill([[// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "{{Pascal}}",
    targets: [
        .executableTarget(name: "{{Pascal}}", path: "Sources/{{Pascal}}")
    ]
)
]], t),
    ["Sources/" .. t.Pascal .. "/main.swift"] = util.fill('print("Hello from {{NAME}}!")\n', t),
    [".gitignore"] = ".build/\n",
  })
  return "Swift Package 已生成"
end

-- ===== C# / .NET =====
gen.dotnet = function(target, name)
  local t = util.project_tokens(name)
  if util.executable("dotnet") then
    util.mkdir_p(target)
    vim.fn.system({ "dotnet", "new", "console", "-o", target, "-n", t.Pascal })
    if vim.v.shell_error == 0 then
      return ".NET 控制台项目已生成"
    end
  end
  util.write_tree(target, {
    [t.kebab .. ".csproj"] = util.fill([[<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <OutputType>Exe</OutputType>
    <TargetFramework>net8.0</TargetFramework>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
    <RootNamespace>{{Pascal}}</RootNamespace>
  </PropertyGroup>
</Project>
]], t),
    ["Program.cs"] = util.fill('Console.WriteLine("Hello from {{NAME}}!");\n', t),
    [".gitignore"] = "bin/\nobj/\n",
    ["README.md"] = util.fill("# {{NAME}}\n\n```bash\ndotnet run\n```\n", t),
  })
  return "C# (.NET) 离线骨架已生成"
end

-- ===== Clojure =====
gen.clojure = function(target, name)
  local t = util.project_tokens(name)
  util.write_tree(target, {
    ["deps.edn"] = util.fill('{:paths ["src"]\n :deps {}\n :aliases {:run {:main-opts ["-m" "{{snake}}.core"]}}}\n', t),
    ["src/" .. t.snake .. "/core.clj"] = util.fill([[(ns {{snake}}.core)

(defn -main [& _args]
  (println "Hello from {{NAME}}!"))
]], t),
    ["Makefile"] = "run:\n\tclj -M:run\n\n.PHONY: run\n",
    [".gitignore"] = ".cpcache/\ntarget/\n",
  })
  return "Clojure (deps.edn) 项目已生成"
end

-- ===== Scala (sbt) =====
gen.scala = function(target, name)
  local t = util.project_tokens(name)
  util.write_tree(target, {
    ["build.sbt"] = util.fill([[ThisBuild / scalaVersion := "3.3.3"
ThisBuild / organization := "com.example"

lazy val root = (project in file("."))
  .settings(
    name := "{{kebab}}"
  )
]], t),
    ["project/build.properties"] = "sbt.version=1.9.9\n",
    ["src/main/scala/Main.scala"] = util.fill('@main def hello(): Unit =\n  println("Hello from {{NAME}}!")\n', t),
    [".gitignore"] = "target/\nproject/target/\n.bsp/\n",
  })
  return "Scala (sbt) 项目已生成"
end

M.frameworks = {
  { label = "Zig", lang = "zig", gen = gen.zig, main = "src/main.zig",
    requires = { bins = { "zig" }, pacman = { "zig" } } },
  { label = "Nim", lang = "nim", gen = gen.nim, main = "src/main.nim",
    requires = { bins = { "nim" }, pacman = { "nim" } } },
  { label = "Crystal", lang = "crystal", gen = gen.crystal, main = "src/main.cr",
    requires = { bins = { "crystal" }, pacman = { "crystal" } } },
  { label = "D (dub)", lang = "d", gen = gen.dlang, main = "source/app.d",
    requires = { bins = { "dub" }, pacman = { "dmd" } } },
  { label = "Haskell (cabal)", lang = "haskell", gen = gen.haskell, main = "app/Main.hs",
    requires = { bins = { "cabal", "ghc" }, pacman = { "cabal-install", "ghc" } } },
  { label = "OCaml (dune)", lang = "ocaml", gen = gen.ocaml, main = "bin/main.ml",
    requires = { bins = { "dune", "ocaml" }, pacman = { "dune", "ocaml" } } },
  { label = "Common Lisp (SBCL)", lang = "lisp", gen = gen.commonlisp, main = "main.lisp",
    requires = { bins = { "sbcl" }, pacman = { "sbcl" } } },
  { label = "Scheme (Guile)", lang = "scheme", gen = gen.scheme, main = "main.scm",
    requires = { bins = { "guile" }, pacman = { "guile" } } },
  { label = "Racket", lang = "racket", gen = gen.racket, main = "main.rkt",
    requires = { bins = { "racket" }, pacman = { "racket" } } },
  { label = "Erlang (rebar3)", lang = "erlang", gen = gen.erlang, main = "src/hello.erl",
    requires = { bins = { "rebar3", "erl" }, pacman = { "rebar3", "erlang" } } },
  { label = "Elixir (mix)", lang = "elixir", gen = gen.elixir, main = "lib",
    requires = { bins = { "mix", "elixir" }, pacman = { "elixir" } } },
  { label = "Elixir + Phoenix", lang = "elixir", gen = gen.phoenix, main = "",
    requires = { bins = { "mix", "elixir" }, pacman = { "elixir" }, note = "完整 Phoenix 需: mix archive.install hex phx_new" } },
  { label = "Julia", lang = "julia", gen = gen.julia, main = "main.jl",
    requires = { bins = { "julia" }, pacman = { "julia" } } },
  { label = "Swift Package", lang = "swift", gen = gen.swift, main = "Sources",
    requires = { bins = { "swift" }, pacman = { "swift" } } },
  { label = "C# / .NET 控制台", lang = "csharp", gen = gen.dotnet, main = "Program.cs",
    requires = { bins = { "dotnet" }, pacman = { "dotnet-sdk" } } },
  { label = "Clojure (deps.edn)", lang = "clojure", gen = gen.clojure, main = "",
    requires = { bins = { "clj", "clojure" }, pacman = { "clojure" } } },
  { label = "Scala (sbt)", lang = "scala", gen = gen.scala, main = "src/main/scala/Main.scala",
    requires = { bins = { "sbt" }, pacman = { "sbt" } } },
}

return M
