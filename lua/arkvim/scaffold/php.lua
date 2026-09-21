-- arkvim/scaffold/php.lua — PHP 模板
local util = require("arkvim.scaffold.util")

local M = {}
local gen = {}

local PHP_REQ = { bins = { "php" }, pacman = { "php" } }

gen.laravel = function(target, name)
  local t = util.project_tokens(name)
  util.write_tree(target, {
    ["composer.json"] = util.fill('{"name":"example/{{kebab}}","require":{},"autoload":{"psr-4":{"App/":"app/"}}}\n', t),
    ["artisan"] = "#!/usr/bin/env php\n<?php\n",
    ["app/Http/Controllers/Controller.php"] = "<?php\nnamespace App\\Http\\Controllers;\nabstract class Controller {}\n",
    ["public/index.php"] = "<?php\nrequire __DIR__ . '/../vendor/autoload.php';\n\necho 'Hello from " .. t.NAME .. "!';\n",
    [".gitignore"] = "vendor/\nstorage/*.key\n.env\n",
    ["README.md"] = util.fill("# {{NAME}}\n\n```bash\ncomposer install\nphp -S localhost:8000 -t public\n```\n", t),
  })
  return "Laravel (最小骨架) 已生成"
end

gen.symfony = function(target, name)
  local t = util.project_tokens(name)
  util.write_tree(target, {
    ["composer.json"] = util.fill([[{
  "name": "example/{{kebab}}",
  "type": "project",
  "require": {
    "php": ">=8.2",
    "symfony/framework-bundle": "^7.0",
    "symfony/runtime": "^7.0",
    "symfony/yaml": "^7.0"
  },
  "autoload": {
    "psr-4": { "App\\": "src/" }
  }
}
]], t),
    ["public/index.php"] = "<?php\nuse App\\Kernel;\n\nrequire_once dirname(__DIR__).'/vendor/autoload_runtime.php';\n\nreturn function (array $context) {\n    return new Kernel($context['APP_ENV'], (bool) $context['APP_DEBUG']);\n};\n",
    ["src/Kernel.php"] = "<?php\nnamespace App;\n\nuse Symfony\\Bundle\\FrameworkBundle\\Kernel\\MicroKernelTrait;\nuse Symfony\\Component\\HttpKernel\\Kernel as BaseKernel;\n\nclass Kernel extends BaseKernel\n{\n    use MicroKernelTrait;\n}\n",
    ["src/Controller/HomeController.php"] = util.fill("<?php\nnamespace App\\Controller;\n\nuse Symfony\\Component\\HttpFoundation\\Response;\nuse Symfony\\Component\\Routing\\Attribute\\Route;\n\nclass HomeController\n{\n    #[Route('/', name: 'home')]\n    public function index(): Response\n    {\n        return new Response('Hello from {{NAME}}!');\n    }\n}\n", t),
    [".gitignore"] = "vendor/\nvar/\n.env.local\n",
    ["README.md"] = util.fill("# {{NAME}}\n\n```bash\ncomposer install\nphp -S localhost:8000 -t public\n```\n", t),
  })
  return "Symfony (PHP) 已生成"
end

gen.php_cli = function(target, name)
  local t = util.project_tokens(name)
  util.write_tree(target, {
    ["src/Main.php"] = util.fill("<?php\nnamespace {{snake}};\n\nclass Main {\n    public static function main(): void {\n        echo \"Hello from {{NAME}}!\\n\";\n    }\n}\n\nMain::main();\n", t),
    ["composer.json"] = util.fill('{"name":"example/{{kebab}}","autoload":{"psr-4":{"{{snake}}\\\\":"src/"}}}\n', t),
    [".gitignore"] = "vendor/\n",
  })
  return "PHP CLI 已生成"
end

M.frameworks = {
  { label = "Laravel (PHP)", lang = "php", gen = gen.laravel, main = "public/index.php",
    requires = { bins = { "php", "composer" }, pacman = { "php", "composer" } } },
  { label = "Symfony (PHP)", lang = "php", gen = gen.symfony, main = "src/Controller/HomeController.php",
    requires = { bins = { "php", "composer" }, pacman = { "php", "composer" } } },
  { label = "PHP CLI", lang = "php", gen = gen.php_cli, main = "src/Main.php", requires = PHP_REQ },
}

return M
