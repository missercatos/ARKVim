-- arkvim/scaffold/go.lua — Go 模板
local util = require("arkvim.scaffold.util")

local M = {}
local gen = {}

local GO_REQ = { bins = { "go" }, pacman = { "go" } }

gen.gomod = function(target, name)
  local t = util.project_tokens(name)
  local module = "example.com/" .. t.kebab
  util.write_tree(target, {
    ["go.mod"] = ("module %s\n\ngo 1.22\n"):format(module),
    ["main.go"] = util.fill('package main\nimport "fmt"\nfunc main() {\n\tfmt.Println("Hello from {{NAME}}!")\n}\n', t),
    [".gitignore"] = t.kebab .. "\n*.exe\n",
  })
  return "Go module 已生成"
end

gen.gin = function(target, name)
  local t = util.project_tokens(name)
  local module = "example.com/" .. t.kebab
  util.write_tree(target, {
    ["go.mod"] = ("module %s\n\ngo 1.22\n\nrequire github.com/gin-gonic/gin v1.9.1\n"):format(module),
    ["main.go"] = util.fill([[
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
  local t = util.project_tokens(name)
  local module = "example.com/" .. t.kebab
  util.write_tree(target, {
    ["go.mod"] = ("module %s\n\ngo 1.22\n\nrequire github.com/gofiber/fiber/v2 v2.52.0\n"):format(module),
    ["main.go"] = util.fill([[
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

gen.echo = function(target, name)
  local t = util.project_tokens(name)
  util.write_tree(target, {
    ["go.mod"] = util.fill('module {{kebab}}\n\ngo 1.22\n\nrequire github.com/labstack/echo/v4 v4.12.0\n', t),
    ["main.go"] = util.fill('package main\n\nimport (\n\t"net/http"\n\t"github.com/labstack/echo/v4"\n)\n\nfunc main() {\n\te := echo.New()\n\te.GET("/", func(c echo.Context) error {\n\t\treturn c.JSON(http.StatusOK, map[string]string{"message": "Hello from {{NAME}}!"})\n\t})\n\te.Logger.Fatal(e.Start(":3000"))\n}\n', t),
    [".gitignore"] = "",
  })
  return "Echo (Go) 已生成"
end

gen.chi = function(target, name)
  local t = util.project_tokens(name)
  util.write_tree(target, {
    ["go.mod"] = util.fill('module {{kebab}}\n\ngo 1.22\n\nrequire github.com/go-chi/chi/v5 v5.0.12\n', t),
    ["main.go"] = util.fill([[
package main

import (
	"encoding/json"
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
)

func main() {
	r := chi.NewRouter()
	r.Use(middleware.Logger)

	r.Get("/", func(w http.ResponseWriter, _ *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		_ = json.NewEncoder(w).Encode(map[string]string{"message": "Hello from {{NAME}}!"})
	})

	http.ListenAndServe(":8080", r)
}
]], t),
    [".gitignore"] = t.kebab .. "\n",
  })
  return "Go + Chi 已生成"
end

M.frameworks = {
  { label = "Go module", lang = "go", gen = gen.gomod, main = "main.go", requires = GO_REQ },
  { label = "Go + Gin (Web)", lang = "go", gen = gen.gin, main = "main.go", requires = GO_REQ },
  { label = "Go + Fiber (Web)", lang = "go", gen = gen.fiber, main = "main.go", requires = GO_REQ },
  { label = "Go + Echo (Web)", lang = "go", gen = gen.echo, main = "main.go", requires = GO_REQ },
  { label = "Go + Chi (Web)", lang = "go", gen = gen.chi, main = "main.go", requires = GO_REQ },
}

return M
