-- arkvim/scaffold/rust.lua — Rust 模板（Web / GUI / 游戏）
local util = require("arkvim.scaffold.util")

local M = {}
local gen = {}

local RUST_REQ = { bins = { "cargo", "rustc" }, pacman = { "rust" } }

gen.cargo = function(target, name)
  local t = util.project_tokens(name)
  util.write_tree(target, {
    ["Cargo.toml"] = util.fill('[package]\nname = "{{kebab}}"\nversion = "0.1.0"\nedition = "2021"\n\n[dependencies]\n', t),
    ["src/main.rs"] = util.fill('fn main() {\n    println!("Hello from {{NAME}}!");\n}\n', t),
    [".gitignore"] = "/target\n",
  })
  return "Rust + Cargo 已生成"
end

gen.actix = function(target, name)
  local t = util.project_tokens(name)
  util.write_tree(target, {
    ["Cargo.toml"] = util.fill('[package]\nname = "{{kebab}}"\nversion = "0.1.0"\nedition = "2021"\n\n[dependencies]\nactix-web = "4"\nactix-rt = "2"\n', t),
    ["src/main.rs"] = util.fill([[
use actix_web::{web, App, HttpServer, HttpResponse};

async fn index() -> HttpResponse {
    HttpResponse::Ok().body("Hello from {{NAME}}!")
}

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    HttpServer::new(|| App::new().route("/", web::get().to(index)))
        .bind("127.0.0.1:8080")?
        .run()
        .await
}
]], t),
    [".gitignore"] = "/target\n",
  })
  return "Rust + Actix 已生成"
end

gen.axum = function(target, name)
  local t = util.project_tokens(name)
  util.write_tree(target, {
    ["Cargo.toml"] = util.fill('[package]\nname = "{{kebab}}"\nversion = "0.1.0"\nedition = "2021"\n\n[dependencies]\naxum = "0.7"\ntokio = { version = "1", features = ["full"] }\n', t),
    ["src/main.rs"] = util.fill([[
use axum::{routing::get, Router};

async fn index() -> &'static str {
    "Hello from {{NAME}}!"
}

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

gen.rocket = function(target, name)
  local t = util.project_tokens(name)
  util.write_tree(target, {
    ["Cargo.toml"] = util.fill('[package]\nname = "{{kebab}}"\nedition = "2021"\n\n[dependencies]\nrocket = "0.5"\n', t),
    ["src/main.rs"] = util.fill('#[macro_use] extern crate rocket\n\n#[get("/")] fn index() -> String { "Hello from {{NAME}}!".to_string() }\n\n#[launch] fn rocket() -> _ { rocket::build().mount("/", routes![index]) }\n', t),
    [".gitignore"] = "target/\n",
  })
  return "Rocket (Rust) 已生成"
end

gen.leptos = function(target, name)
  local t = util.project_tokens(name)
  util.write_tree(target, {
    ["Cargo.toml"] = util.fill('[package]\nname = "{{kebab}}"\nedition = "2021"\n\n[dependencies]\nleptos = { version = "0.6", features = [] }\nleptos_actix = { version = "0.6", optional = true }\nleptos_router = { version = "0.6", features = [] }\n', t),
    ["src/main.rs"] = util.fill('use leptos::*;\n\n#[component]\nfn App() -> impl IntoView {\n  view! { <h1>"Hello from {{NAME}}!"</h1> }\n}\n\nfn main() {\n  mount_to_body(|| view! { <App/> });\n}\n', t),
    [".gitignore"] = "target/\n",
  })
  return "Leptos (Rust WASM) 已生成"
end

-- egui: 立即模式 GUI
gen.egui = function(target, name)
  local t = util.project_tokens(name)
  util.write_tree(target, {
    ["Cargo.toml"] = util.fill('[package]\nname = "{{kebab}}"\nversion = "0.1.0"\nedition = "2021"\n\n[dependencies]\neframe = "0.27"\n', t),
    ["src/main.rs"] = util.fill([[
use eframe::egui;

struct App {
    name: String,
}

impl Default for App {
    fn default() -> Self {
        Self { name: "World".to_owned() }
    }
}

impl eframe::App for App {
    fn update(&mut self, ctx: &egui::Context, _frame: &mut eframe::Frame) {
        egui::CentralPanel::default().show(ctx, |ui| {
            ui.heading("{{NAME}}");
            ui.horizontal(|ui| {
                ui.label("名字:");
                ui.text_edit_singleline(&mut self.name);
            });
            ui.label(format!("Hello from {{NAME}}, {}!", self.name));
        });
    }
}

fn main() -> eframe::Result<()> {
    eframe::run_native(
        "{{NAME}}",
        eframe::NativeOptions::default(),
        Box::new(|_cc| Box::<App>::default()),
    )
}
]], t),
    [".gitignore"] = "/target\n",
    ["README.md"] = util.fill("# {{NAME}}\n\negui 桌面应用\n\n```bash\ncargo run\n```\n", t),
  })
  return "egui (Rust GUI) 已生成"
end

-- Bevy: 游戏引擎
gen.bevy = function(target, name)
  local t = util.project_tokens(name)
  util.write_tree(target, {
    ["Cargo.toml"] = util.fill([[package]
name = "{{kebab}}"
version = "0.1.0"
edition = "2021"

[dependencies]
bevy = "0.13"
]], t),
    ["src/main.rs"] = util.fill([[
use bevy::prelude::*;

fn main() {
    App::new()
        .add_plugins(DefaultPlugins.set(WindowPlugin {
            primary_window: Some(Window {
                title: "{{NAME}}".into(),
                ..default()
            }),
            ..default()
        }))
        .add_systems(Startup, setup)
        .add_systems(Update, rotate)
        .run();
}

#[derive(Component)]
struct Rotator;

fn setup(mut commands: Commands, asset_server: Res<AssetServer>) {
    commands.spawn(Camera2dBundle::default());
    commands.spawn((
        SpriteBundle {
            texture: asset_server.load("icon.png"),
            ..default()
        },
        Rotator,
    ));
}

fn rotate(time: Res<Time>, mut query: Query<&mut Transform, With<Rotator>>) {
    for mut transform in &mut query {
        transform.rotate_z(time.delta_seconds());
    }
}
]], t),
    [".gitignore"] = "/target\n",
    ["assets/.gitkeep"] = "",
    ["README.md"] = util.fill("# {{NAME}}\n\nBevy 游戏项目（把贴图放到 assets/）\n\n```bash\ncargo run\n```\n", t),
  })
  return "Bevy (Rust 游戏引擎) 已生成"
end

-- Tauri: 桌面应用（Rust + Web 前端）
gen.tauri = function(target, name)
  local t = util.project_tokens(name)
  util.write_tree(target, {
    ["package.json"] = util.fill('{"name":"{{kebab}}","private":true,"version":"0.1.0","type":"module","scripts":{"dev":"vite","build":"vite build","tauri":"tauri"},"dependencies":{"@tauri-apps/api":"^2"},"devDependencies":{"@tauri-apps/cli":"^2","vite":"^5"}}\n', t),
    ["index.html"] = '<!DOCTYPE html><html lang="zh-CN"><head><meta charset="UTF-8"><title>' .. t.NAME .. '</title></head><body><div id="app"></div><script type="module" src="/src/main.js"></script></body></html>\n',
    ["src/main.js"] = util.fill('document.querySelector("#app").innerHTML = `<h1>Hello from {{NAME}}!</h1>`\n', t),
    ["src-tauri/Cargo.toml"] = util.fill('[package]\nname = "{{kebab}}"\nversion = "0.1.0"\nedition = "2021"\n\n[build-dependencies]\ntauri-build = { version = "2", features = [] }\n\n[dependencies]\ntauri = { version = "2", features = [] }\nserde = { version = "1", features = ["derive"] }\nserde_json = "1"\n', t),
    ["src-tauri/tauri.conf.json"] = util.fill('{\n  "$schema": "https://schema.tauri.app/config/2",\n  "productName": "{{NAME}}",\n  "version": "0.1.0",\n  "identifier": "com.example.{{kebab}}",\n  "build": {\n    "frontendDist": "../dist",\n    "devUrl": "http://localhost:1420",\n    "beforeDevCommand": "npm run dev",\n    "beforeBuildCommand": "npm run build"\n  },\n  "app": {\n    "windows": [{ "title": "{{NAME}}", "width": 900, "height": 600 }],\n    "security": { "csp": null }\n  }\n}\n', t),
    ["src-tauri/src/main.rs"] = 'fn main() {\n    tauri::Builder::default()\n        .run(tauri::generate_context!())\n        .expect("error while running tauri application");\n}\n',
    ["src-tauri/build.rs"] = 'fn main() {\n    tauri_build::build()\n}\n',
    [".gitignore"] = "node_modules/\ndist/\nsrc-tauri/target/\n",
    ["README.md"] = util.fill("# {{NAME}}\n\nTauri 桌面应用（Rust 后端 + Web 前端）\n\n```bash\nnpm install\nnpm run tauri dev\n```\n", t),
  })
  return "Tauri (Rust + Web) 已生成"
end

M.frameworks = {
  { label = "Rust + Cargo", lang = "rust", gen = gen.cargo, main = "src/main.rs", requires = RUST_REQ },
  { label = "Rust + Actix (Web)", lang = "rust", gen = gen.actix, main = "src/main.rs", requires = RUST_REQ },
  { label = "Rust + Axum (Web)", lang = "rust", gen = gen.axum, main = "src/main.rs", requires = RUST_REQ },
  { label = "Rust + Rocket (Web)", lang = "rust", gen = gen.rocket, main = "src/main.rs", requires = RUST_REQ },
  { label = "Rust + Leptos (WASM)", lang = "rust", gen = gen.leptos, main = "src/main.rs", requires = RUST_REQ },
  { label = "egui (Rust GUI)", lang = "rust", gen = gen.egui, main = "src/main.rs", requires = RUST_REQ },
  { label = "Bevy (Rust 游戏引擎)", lang = "rust", gen = gen.bevy, main = "src/main.rs", requires = RUST_REQ },
  { label = "Tauri (Rust + Web 桌面)", lang = "rust", gen = gen.tauri, main = "src-tauri/src/main.rs",
    requires = { bins = { "cargo", "node", "npm" }, pacman = { "rust", "nodejs", "npm" }, note = "WebView 依赖需要系统已装 webkit2gtk" } },
}

return M
