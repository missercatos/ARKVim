-- arkvim/scaffold/web.lua — TypeScript / JavaScript / 前端模板
local util = require("arkvim.scaffold.util")

local M = {}
local gen = {}

local NODE_REQ = { bins = { "node", "npm" }, pacman = { "nodejs", "npm" } }
local BUN_REQ = { bins = { "bun" }, pacman = { "bun" } }

local TSCONFIG = '{\n  "compilerOptions": {\n    "target": "ES2022", "module": "Node16", "moduleResolution": "Node16",\n    "outDir": "dist", "rootDir": "src", "strict": true, "esModuleInterop": true\n  },\n  "include": ["src"]\n}\n'

gen.ts_node = function(target, name)
  local t = util.project_tokens(name)
  util.write_tree(target, {
    ["package.json"] = util.fill('{"name":"{{kebab}}","version":"1.0.0","scripts":{"dev":"tsx watch src/index.ts","build":"tsc","start":"node dist/index.js"},"devDependencies":{"tsx":"^4","typescript":"^5","@types/node":"^20"},"dependencies":{}}\n', t),
    ["tsconfig.json"] = TSCONFIG,
    ["src/index.ts"] = util.fill('console.log("Hello from {{NAME}}!")\n', t),
    [".gitignore"] = "node_modules/\ndist/\n",
  })
  return "Node.js (TypeScript) 已生成"
end

gen.express = function(target, name)
  local t = util.project_tokens(name)
  util.write_tree(target, {
    ["package.json"] = util.fill('{"name":"{{kebab}}","version":"1.0.0","scripts":{"dev":"tsx watch src/index.ts","build":"tsc","start":"node dist/index.js"},"dependencies":{"express":"^4"},"devDependencies":{"tsx":"^4","typescript":"^5","@types/express":"^4","@types/node":"^20"}}\n', t),
    ["tsconfig.json"] = TSCONFIG,
    ["src/index.ts"] = util.fill('import express from "express"\nconst app = express()\napp.get("/", (_req, res) => res.json({ message: "Hello from {{NAME}}!" }))\napp.listen(3000, () => console.log("http://localhost:3000"))\n', t),
    [".gitignore"] = "node_modules/\ndist/\n",
  })
  return "Express (TypeScript) 已生成"
end

gen.hono = function(target, name)
  local t = util.project_tokens(name)
  util.write_tree(target, {
    ["package.json"] = util.fill('{"name":"{{kebab}}","version":"1.0.0","type":"module","scripts":{"dev":"bun run src/index.ts","build":"bun build src/index.ts --outdir dist","start":"bun dist/index.js"},"dependencies":{"hono":"^4"},"devDependencies":{"bun-types":"latest","typescript":"^5"}}\n', t),
    ["tsconfig.json"] = '{\n  "compilerOptions": {\n    "target": "ESNext", "module": "ESNext", "moduleResolution": "bundler",\n    "strict": true, "esModuleInterop": true, "types": ["bun-types"]\n  },\n  "include": ["src"]\n}\n',
    ["src/index.ts"] = util.fill('import { Hono } from "hono"\n\nconst app = new Hono()\napp.get("/", (c) => c.json({ message: "Hello from {{NAME}}!" }))\n\nexport default { port: 3000, fetch: app.fetch }\n', t),
    [".gitignore"] = "node_modules/\ndist/\n",
  })
  return "Hono (Bun) 已生成"
end

gen.react_vite = function(target, name)
  local t = util.project_tokens(name)
  util.write_tree(target, {
    ["package.json"] = util.fill('{"name":"{{kebab}}","private":true,"type":"module","scripts":{"dev":"vite","build":"tsc && vite build","preview":"vite preview"},"dependencies":{"react":"^18","react-dom":"^18"},"devDependencies":{"@types/react":"^18","@types/react-dom":"^18","@vitejs/plugin-react":"^4","typescript":"^5","vite":"^5"}}\n', t),
    ["index.html"] = '<!DOCTYPE html><html lang="zh-CN"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"><title>' .. t.NAME .. '</title></head><body><div id="root"></div><script type="module" src="/src/main.tsx"></script></body></html>\n',
    ["vite.config.ts"] = 'import { defineConfig } from "vite"\nimport react from "@vitejs/plugin-react"\nexport default defineConfig({ plugins: [react()] })\n',
    ["tsconfig.json"] = '{\n  "compilerOptions": {\n    "target": "ES2020", "module": "ESNext", "moduleResolution": "bundler",\n    "jsx": "react-jsx", "strict": true, "esModuleInterop": true\n  },\n  "include": ["src"]\n}\n',
    ["src/main.tsx"] = 'import React from "react"\nimport ReactDOM from "react-dom/client"\nimport App from "./App"\nReactDOM.createRoot(document.getElementById("root")!).render(<App />)\n',
    ["src/App.tsx"] = util.fill('export default function App() { return <h1>Hello from {{NAME}}!</h1> }\n', t),
    [".gitignore"] = "node_modules/\ndist/\n",
  })
  return "React + Vite 已生成"
end

gen.nextjs = function(target, name)
  local t = util.project_tokens(name)
  util.write_tree(target, {
    ["package.json"] = util.fill('{"name":"{{kebab}}","version":"1.0.0","scripts":{"dev":"next dev","build":"next build","start":"next start"},"dependencies":{"next":"^14","react":"^18","react-dom":"^18"},"devDependencies":{"@types/node":"^20","@types/react":"^18","typescript":"^5"}}\n', t),
    ["tsconfig.json"] = '{\n  "compilerOptions": {\n    "target": "ES2017", "lib": ["dom", "dom.iterable", "esnext"],\n    "allowJs": true, "skipLibCheck": true, "strict": true,\n    "noEmit": true, "esModuleInterop": true, "module": "esnext",\n    "moduleResolution": "bundler", "resolveJsonModule": true,\n    "isolatedModules": true, "jsx": "preserve", "incremental": true\n  },\n  "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx"]\n}\n',
    ["next.config.js"] = '/** @type {import("next").NextConfig} */\nconst nextConfig = {}\nmodule.exports = nextConfig\n',
    ["app/layout.tsx"] = 'export default function RootLayout({ children }: { children: React.ReactNode }) {\n  return (<html lang="zh-CN"><body>{children}</body></html>)\n}\n',
    ["app/page.tsx"] = util.fill('export default function Home() { return <h1>Hello from {{NAME}}!</h1> }\n', t),
    [".gitignore"] = "node_modules/\n.next/\n",
  })
  return "Next.js 已生成"
end

gen.vue = function(target, name)
  local t = util.project_tokens(name)
  util.write_tree(target, {
    ["package.json"] = util.fill('{"name":"{{kebab}}","private":true,"type":"module","scripts":{"dev":"vite","build":"vue-tsc && vite build","preview":"vite preview"},"dependencies":{"vue":"^3"},"devDependencies":{"@vitejs/plugin-vue":"^5","typescript":"^5","vite":"^5","vue-tsc":"^2"}}\n', t),
    ["index.html"] = '<!DOCTYPE html><html lang="zh-CN"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"><title>' .. t.NAME .. '</title></head><body><div id="app"></div><script type="module" src="/src/main.ts"></script></body></html>\n',
    ["vite.config.ts"] = 'import { defineConfig } from "vite"\nimport vue from "@vitejs/plugin-vue"\nexport default defineConfig({ plugins: [vue()] })\n',
    ["tsconfig.json"] = '{\n  "compilerOptions": {\n    "target": "ES2020", "module": "ESNext", "moduleResolution": "bundler",\n    "strict": true, "jsx": "preserve", "esModuleInterop": true\n  },\n  "include": ["src/**/*.ts", "src/**/*.vue"]\n}\n',
    ["src/main.ts"] = 'import { createApp } from "vue"\nimport App from "./App.vue"\ncreateApp(App).mount("#app")\n',
    ["src/App.vue"] = util.fill('<script setup lang="ts"></script>\n<template>\n  <h1>Hello from {{NAME}}!</h1>\n</template>\n', t),
    [".gitignore"] = "node_modules/\ndist/\n",
  })
  return "Vue + Vite 已生成"
end

gen.nuxt = function(target, name)
  local t = util.project_tokens(name)
  util.write_tree(target, {
    ["package.json"] = util.fill('{"name":"{{kebab}}","version":"1.0.0","private":true,"scripts":{"dev":"nuxt dev","build":"nuxt build","preview":"nuxt preview","generate":"nuxt generate"},"dependencies":{"nuxt":"^3","vue":"^3","vue-router":"^4"}}\n', t),
    ["nuxt.config.ts"] = 'export default defineNuxtConfig({\n  devtools: { enabled: true },\n  compatibilityDate: "2024-11-01"\n})\n',
    ["app.vue"] = util.fill('<template>\n  <h1>Hello from {{NAME}}!</h1>\n</template>\n', t),
    [".gitignore"] = "node_modules/\n.nuxt/\ndist/\n",
  })
  return "Nuxt 已生成"
end

gen.angular = function(target, name)
  local t = util.project_tokens(name)
  util.write_tree(target, {
    ["package.json"] = util.fill('{"name":"{{kebab}}","version":"1.0.0","scripts":{"ng":"ng","start":"ng serve","build":"ng build","test":"ng test"},"dependencies":{"@angular/animations":"^17","@angular/common":"^17","@angular/compiler":"^17","@angular/core":"^17","@angular/forms":"^17","@angular/platform-browser":"^17","@angular/router":"^17","rxjs":"~7.8","tslib":"^2.3","zone.js":"~0.14"},"devDependencies":{"@angular-devkit/build-angular":"^17","@angular/cli":"^17","typescript":"~5.3"}}\n', t),
    ["src/index.html"] = '<!doctype html>\n<html lang="zh-CN"><head><meta charset="utf-8"><title>' .. t.NAME .. '</title><base href="/"><meta name="viewport" content="width=device-width, initial-scale=1"></head><body><app-root></app-root></body></html>\n',
    ["src/main.ts"] = 'import { bootstrapApplication } from "@angular/platform-browser"\nimport { AppComponent } from "./app/app.component"\nbootstrapApplication(AppComponent).catch(err => console.error(err))\n',
    ["src/app/app.component.ts"] = util.fill('import { Component } from "@angular/core"\n@Component({\n  selector: "app-root",\n  standalone: true,\n  template: `<h1>Hello from {{NAME}}!</h1>`\n})\nexport class AppComponent {}\n', t),
    ["tsconfig.json"] = '{\n  "compilerOptions": {\n    "target": "ES2022", "module": "ES2022", "moduleResolution": "node",\n    "strict": true, "experimentalDecorators": true, "skipLibCheck": true,\n    "lib": ["ES2022", "dom"]\n  },\n  "angularCompilerOptions": { "strictTemplates": true }\n}\n',
    [".gitignore"] = "node_modules/\ndist/\n.angular/\n",
  })
  return "Angular 已生成"
end

gen.sveltekit = function(target, name)
  local t = util.project_tokens(name)
  util.write_tree(target, {
    ["package.json"] = util.fill('{"name":"{{kebab}}","version":"1.0.0","type":"module","scripts":{"dev":"vite dev","build":"vite build","preview":"vite preview"},"dependencies":{"@sveltejs/kit":"^2","svelte":"^4","vite":"^5"}}\n', t),
    ["svelte.config.js"] = 'import adapter from "@sveltejs/adapter-auto"\n\n/** @type {import("@sveltejs/kit").Config} */\nconst config = { kit: { adapter: adapter() } }\n\nexport default config\n',
    ["vite.config.js"] = 'import { sveltekit } from "@sveltejs/kit/vite"\nimport { defineConfig } from "vite"\nexport default defineConfig({ plugins: [sveltekit()] })\n',
    ["src/app.html"] = '<!DOCTYPE html>\n<html lang="zh-CN">\n<head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">%sveltekit.head%</head>\n<body><div style="display:contents">%sveltekit.body%</div></body>\n</html>\n',
    ["src/routes/+page.svelte"] = util.fill('<h1>Hello from {{NAME}}!</h1>\n', t),
    [".gitignore"] = "node_modules/\n.svelte-kit/\nbuild/\n",
  })
  return "SvelteKit 已生成"
end

-- Astro
gen.astro = function(target, name)
  local t = util.project_tokens(name)
  util.write_tree(target, {
    ["package.json"] = util.fill('{"name":"{{kebab}}","type":"module","version":"1.0.0","scripts":{"dev":"astro dev","build":"astro build","preview":"astro preview"},"dependencies":{"astro":"^4"}}\n', t),
    ["astro.config.mjs"] = 'import { defineConfig } from "astro/config"\n\nexport default defineConfig({})\n',
    ["src/pages/index.astro"] = util.fill('---\nconst title = "{{NAME}}"\n---\n\n<html lang="zh-CN">\n  <head><meta charset="utf-8" /><title>{title}</title></head>\n  <body><h1>Hello from {title}!</h1></body>\n</html>\n', t),
    ["tsconfig.json"] = '{\n  "extends": "astro/tsconfigs/strict"\n}\n',
    [".gitignore"] = "node_modules/\ndist/\n.astro/\n",
  })
  return "Astro 已生成"
end

-- SolidJS
gen.solid = function(target, name)
  local t = util.project_tokens(name)
  util.write_tree(target, {
    ["package.json"] = util.fill('{"name":"{{kebab}}","private":true,"type":"module","scripts":{"dev":"vite","build":"vite build","preview":"vite preview"},"dependencies":{"solid-js":"^1.8"},"devDependencies":{"vite":"^5","vite-plugin-solid":"^2","typescript":"^5"}}\n', t),
    ["index.html"] = '<!DOCTYPE html><html lang="zh-CN"><head><meta charset="UTF-8"><title>' .. t.NAME .. '</title></head><body><div id="root"></div><script type="module" src="/src/index.tsx"></script></body></html>\n',
    ["vite.config.ts"] = 'import { defineConfig } from "vite"\nimport solid from "vite-plugin-solid"\nexport default defineConfig({ plugins: [solid()] })\n',
    ["tsconfig.json"] = '{\n  "compilerOptions": {\n    "target": "ES2020", "module": "ESNext", "moduleResolution": "bundler",\n    "jsx": "preserve", "jsxImportSource": "solid-js", "strict": true\n  },\n  "include": ["src"]\n}\n',
    ["src/index.tsx"] = 'import { render } from "solid-js/web"\nimport App from "./App"\n\nrender(() => <App />, document.getElementById("root")!)\n',
    ["src/App.tsx"] = util.fill('export default function App() {\n  return <h1>Hello from {{NAME}}!</h1>\n}\n', t),
    [".gitignore"] = "node_modules/\ndist/\n",
  })
  return "SolidJS + Vite 已生成"
end

-- Remix
gen.remix = function(target, name)
  local t = util.project_tokens(name)
  util.write_tree(target, {
    ["package.json"] = util.fill('{"name":"{{kebab}}","private":true,"sideEffects":false,"type":"module","scripts":{"dev":"remix vite:dev","build":"remix vite:build","start":"remix-serve ./build/server/index.js"},"dependencies":{"@remix-run/node":"^2","@remix-run/react":"^2","@remix-run/serve":"^2","isbot":"^4","react":"^18","react-dom":"^18"},"devDependencies":{"@types/react":"^18","@types/react-dom":"^18","typescript":"^5","vite":"^5","vite-tsconfig-paths":"^4"}}\n', t),
    ["vite.config.ts"] = 'import { vitePlugin as remix } from "@remix-run/dev"\nimport { defineConfig } from "vite"\nimport tsconfigPaths from "vite-tsconfig-paths"\n\nexport default defineConfig({ plugins: [remix(), tsconfigPaths()] })\n',
    ["app/root.tsx"] = 'import { Links, Meta, Outlet, Scripts } from "@remix-run/react"\n\nexport default function App() {\n  return (\n    <html lang="zh-CN">\n      <head><Meta /><Links /></head>\n      <body><Outlet /><Scripts /></body>\n    </html>\n  )\n}\n',
    ["app/routes/_index.tsx"] = util.fill('export default function Index() {\n  return <h1>Hello from {{NAME}}!</h1>\n}\n', t),
    ["tsconfig.json"] = '{\n  "include": ["**/*.ts", "**/*.tsx"],\n  "compilerOptions": {\n    "lib": ["DOM", "DOM.Iterable", "ES2022"], "types": ["@remix-run/node", "vite/client"],\n    "isolatedModules": true, "esModuleInterop": true, "jsx": "react-jsx",\n    "module": "ESNext", "moduleResolution": "Bundler", "resolveJsonModule": true,\n    "target": "ES2022", "strict": true, "baseUrl": ".", "paths": { "~/*": ["./app/*"] },\n    "noEmit": true\n  }\n}\n',
    [".gitignore"] = "node_modules/\nbuild/\n.cache/\n",
  })
  return "Remix 已生成"
end

-- Electron
gen.electron = function(target, name)
  local t = util.project_tokens(name)
  util.write_tree(target, {
    ["package.json"] = util.fill('{"name":"{{kebab}}","version":"1.0.0","main":"main.js","scripts":{"start":"electron ."},"devDependencies":{"electron":"^30"}}\n', t),
    ["main.js"] = util.fill([=[const { app, BrowserWindow } = require("electron")
const path = require("path")

function createWindow() {
  const win = new BrowserWindow({ width: 1000, height: 700, title: "{{NAME}}" })
  win.loadFile(path.join(__dirname, "index.html"))
}

app.whenReady().then(createWindow)
app.on("window-all-closed", () => { if (process.platform !== "darwin") app.quit() })
app.on("activate", () => { if (BrowserWindow.getAllWindows().length === 0) createWindow() })
]=], t),
    ["index.html"] = '<!DOCTYPE html><html lang="zh-CN"><head><meta charset="UTF-8"><title>' .. t.NAME .. '</title></head><body><h1>Hello from ' .. t.NAME .. '!</h1></body></html>\n',
    [".gitignore"] = "node_modules/\ndist/\n",
    ["README.md"] = util.fill("# {{NAME}}\n\n```bash\nnpm install\nnpm start\n```\n", t),
  })
  return "Electron 已生成"
end

-- React Native (Expo)
gen.expo = function(target, name)
  local t = util.project_tokens(name)
  util.write_tree(target, {
    ["package.json"] = util.fill('{"name":"{{kebab}}","version":"1.0.0","main":"expo/AppEntry.js","scripts":{"start":"expo start","android":"expo start --android","ios":"expo start --ios"},"dependencies":{"expo":"^50","expo-status-bar":"~1.11","react":"^18","react-native":"^0.73"},"devDependencies":{"@babel/core":"^7"}}\n', t),
    ["App.js"] = util.fill([=[import { StatusBar } from "expo-status-bar"
import { StyleSheet, Text, View } from "react-native"

export default function App() {
  return (
    <View style={styles.container}>
      <Text>Hello from {{NAME}}!</Text>
      <StatusBar style="auto" />
    </View>
  )
}

const styles = StyleSheet.create({
  container: { flex: 1, alignItems: "center", justifyContent: "center" },
})
]=], t),
    ["app.json"] = util.fill('{\n  "expo": {\n    "name": "{{NAME}}",\n    "slug": "{{kebab}}",\n    "version": "1.0.0",\n    "orientation": "portrait"\n  }\n}\n', t),
    ["babel.config.js"] = 'module.exports = function (api) {\n  api.cache(true)\n  return { presets: ["babel-preset-expo"] }\n}\n',
    [".gitignore"] = "node_modules/\n.expo/\n",
    ["README.md"] = util.fill("# {{NAME}}\n\n```bash\nnpm install\nnpx expo start\n```\n", t),
  })
  return "React Native (Expo) 已生成"
end

gen.tailwind = function(target, name)
  local t = util.project_tokens(name)
  util.write_tree(target, {
    ["package.json"] = util.fill('{"name":"{{kebab}}","scripts":{"build":"npx tailwindcss -i src/input.css -o dist/output.css --watch"}}\n', t),
    ["src/input.css"] = '@tailwind base;\n@tailwind components;\n@tailwind utilities;\n',
    ["tailwind.config.js"] = '/** @type {import("tailwindcss").Config} */\nmodule.exports = { content: ["*.html"], theme: { extend: {} }, plugins: [] }\n',
    ["index.html"] = util.fill('<!DOCTYPE html>\n<html lang="zh-CN">\n<head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0">\n<link rel="stylesheet" href="dist/output.css">\n<title>{{NAME}}</title></head>\n<body class="bg-gray-900 text-white flex items-center justify-center min-h-screen">\n<h1 class="text-4xl font-bold">Hello from {{NAME}}!</h1>\n</body>\n</html>\n', t),
    [".gitignore"] = "node_modules/\ndist/\n",
  })
  return "Tailwind CSS 已生成"
end

gen.static_html = function(target, name)
  local t = util.project_tokens(name)
  util.write_tree(target, {
    ["index.html"] = util.fill('<!DOCTYPE html>\n<html lang="zh-CN">\n<head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0">\n<title>{{NAME}}</title>\n<style>body{font-family:sans-serif;max-width:800px;margin:0 auto;padding:2rem;}</style>\n</head>\n<body>\n<h1>Hello from {{NAME}}!</h1>\n</body>\n</html>\n', t),
  })
  return "静态站点 已生成"
end

M.frameworks = {
  { label = "Node.js (TypeScript)", lang = "typescript", gen = gen.ts_node, main = "src/index.ts", requires = NODE_REQ },
  { label = "Express + TypeScript", lang = "typescript", gen = gen.express, main = "src/index.ts", requires = NODE_REQ },
  { label = "Hono (Bun)", lang = "typescript", gen = gen.hono, main = "src/index.ts", requires = BUN_REQ },
  { label = "React + Vite (TS)", lang = "typescript", gen = gen.react_vite, main = "src/App.tsx", requires = NODE_REQ },
  { label = "Next.js (TS)", lang = "typescript", gen = gen.nextjs, main = "app/page.tsx", requires = NODE_REQ },
  { label = "Vue + Vite (TS)", lang = "typescript", gen = gen.vue, main = "src/App.vue", requires = NODE_REQ },
  { label = "Nuxt (Vue SSR)", lang = "typescript", gen = gen.nuxt, main = "app.vue", requires = NODE_REQ },
  { label = "Angular (TS)", lang = "typescript", gen = gen.angular, main = "src/app/app.component.ts", requires = NODE_REQ },
  { label = "SvelteKit (TS)", lang = "typescript", gen = gen.sveltekit, main = "src/routes/+page.svelte", requires = NODE_REQ },
  { label = "Astro", lang = "typescript", gen = gen.astro, main = "src/pages/index.astro", requires = NODE_REQ },
  { label = "SolidJS + Vite", lang = "typescript", gen = gen.solid, main = "src/App.tsx", requires = NODE_REQ },
  { label = "Remix", lang = "typescript", gen = gen.remix, main = "app/routes/_index.tsx", requires = NODE_REQ },
  { label = "Electron 桌面", lang = "typescript", gen = gen.electron, main = "main.js", requires = NODE_REQ },
  { label = "React Native (Expo)", lang = "typescript", gen = gen.expo, main = "App.js", requires = NODE_REQ },
  { label = "Tailwind CSS", lang = "css", gen = gen.tailwind, main = "index.html", requires = NODE_REQ },
  { label = "静态站点 (HTML)", lang = "html", gen = gen.static_html, main = "index.html", requires = nil },
}

return M
