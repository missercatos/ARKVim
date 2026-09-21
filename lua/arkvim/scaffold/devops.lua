-- arkvim/scaffold/devops.lua — DevOps / 基础设施模板
local util = require("arkvim.scaffold.util")

local M = {}
local gen = {}

gen.docker = function(target, name)
  local t = util.project_tokens(name)
  util.write_tree(target, {
    ["docker-compose.yml"] = util.fill('services:\n  app:\n    build: .\n    container_name: {{kebab}}_app\n    ports:\n      - "8080:80"\n    restart: unless-stopped\n\n  db:\n    image: postgres:16-alpine\n    environment:\n      POSTGRES_USER: app\n      POSTGRES_PASSWORD: app\n      POSTGRES_DB: app\n    volumes:\n      - db_data:/var/lib/postgresql/data\n\nvolumes:\n  db_data:\n', t),
    ["Dockerfile"] = "FROM nginx:alpine\nCOPY . /usr/share/nginx/html\n",
    [".dockerignore"] = ".git\n*.md\n",
    ["index.html"] = util.fill('<!DOCTYPE html><html lang="zh-CN"><body><h1>Hello from {{NAME}}!</h1></body></html>\n', t),
    ["README.md"] = util.fill("# {{NAME}}\n\n```bash\ndocker compose up -d --build\n```\n", t),
  })
  return "Docker Compose 已生成"
end

-- 只放 compose 文件（PHP/Laravel、Node 等项目的常用配套）
gen.compose_only = function(target, name)
  local t = util.project_tokens(name)
  util.write_tree(target, {
    ["docker-compose.yml"] = util.fill('services:\n  db:\n    image: postgres:16-alpine\n    environment:\n      POSTGRES_USER: {{snake}}\n      POSTGRES_PASSWORD: {{snake}}\n      POSTGRES_DB: {{snake}}\n    ports:\n      - "5432:5432"\n    volumes:\n      - db_data:/var/lib/postgresql/data\n\n  redis:\n    image: redis:7-alpine\n    ports:\n      - "6379:6379"\n\nvolumes:\n  db_data:\n', t),
    ["README.md"] = util.fill("# {{NAME}} · 基础设施\n\n```bash\ndocker compose up -d\n```\n", t),
  })
  return "Docker Compose (Postgres + Redis) 已生成"
end

M.frameworks = {
  { label = "Docker Compose (nginx + postgres)", lang = "devops", gen = gen.docker, main = "docker-compose.yml",
    requires = { bins = { "docker" }, pacman = { "docker", "docker-compose" } } },
  { label = "Docker Compose 基础设施 (PG + Redis)", lang = "devops", gen = gen.compose_only, main = "docker-compose.yml",
    requires = { bins = { "docker" }, pacman = { "docker", "docker-compose" } } },
}

return M
