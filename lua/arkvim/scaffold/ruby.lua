-- arkvim/scaffold/ruby.lua — Ruby 模板
local util = require("arkvim.scaffold.util")

local M = {}
local gen = {}

local RUBY_REQ = { bins = { "ruby" }, pacman = { "ruby" } }

gen.ruby_cli = function(target, name)
  local t = util.project_tokens(name)
  util.write_tree(target, {
    ["Gemfile"] = 'source "https://rubygems.org"\n\ngem "rubocop", group: :development\n',
    ["bin/" .. t.snake] = util.fill("#!/usr/bin/env ruby\n# frozen_string_literal: true\n\nputs \"Hello from {{NAME}}!\"\n", t),
    ["lib/" .. t.snake .. ".rb"] = util.fill("# frozen_string_literal: true\n\nmodule {{Pascal}}\n  VERSION = \"0.1.0\"\nend\n", t),
    ["Rakefile"] = 'task default: :run\n\ntask :run do\n  ruby "bin/' .. t.snake .. '"\nend\n',
    [".gitignore"] = ".bundle/\nvendor/bundle/\n*.gem\n",
  })
  vim.fn.setfperm(target .. "/bin/" .. t.snake, "rwxr-xr-x")
  return "Ruby CLI 已生成"
end

gen.sinatra = function(target, name)
  local t = util.project_tokens(name)
  util.write_tree(target, {
    ["Gemfile"] = 'source "https://rubygems.org"\n\ngem "sinatra"\ngem "puma"\ngem "rackup"\n',
    ["app.rb"] = util.fill([=[# frozen_string_literal: true

require "sinatra"

get "/" do
  "Hello from {{NAME}}!"
end
]=], t),
    ["config.ru"] = 'require_relative "app"\n\nrun Sinatra::Application\n',
    [".gitignore"] = ".bundle/\nvendor/bundle/\n",
    ["README.md"] = util.fill("# {{NAME}}\n\n```bash\nbundle install\nbundle exec ruby app.rb -p 4567\n```\n", t),
  })
  return "Sinatra (Ruby) 已生成"
end

gen.rails = function(target, name)
  local t = util.project_tokens(name)
  util.write_tree(target, {
    ["Gemfile"] = 'source "https://rubygems.org"\n\ngem "rails", "~> 7.1"\ngem "sqlite3"\ngem "puma"\n',
    ["config.ru"] = 'require_relative "config/environment"\n\nrun Rails.application\n',
    ["config/application.rb"] = util.fill([=[# frozen_string_literal: true

require_relative "boot"

require "rails"
require "action_controller/railtie"

Bundler.require(*Rails.groups)

module {{Pascal}}
  class Application < Rails::Application
    config.load_defaults 7.1
  end
end
]=], t),
    ["config/boot.rb"] = 'ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)\nrequire "bundler/setup"\n',
    ["config/environment.rb"] = 'require_relative "application"\n\nRails.application.initialize!\n',
    ["config/routes.rb"] = 'Rails.application.routes.draw do\n  root "home#index"\nend\n',
    ["app/controllers/home_controller.rb"] = util.fill('class HomeController < ApplicationController\n  def index\n    render plain: "Hello from {{NAME}}!"\n  end\nend\n', t),
    ["bin/rails"] = "#!/usr/bin/env ruby\nAPP_PATH = File.expand_path('../config/application', __dir__)\nrequire_relative '../config/boot'\nrequire 'rails/commands'\n",
    [".gitignore"] = "log/\ntmp/\nstorage/\nvendor/bundle/\n.bundle/\n*.sqlite3\n",
    ["README.md"] = util.fill("# {{NAME}}\n\n```bash\nbundle install\nbin/rails server\n```\n", t),
  })
  vim.fn.setfperm(target .. "/bin/rails", "rwxr-xr-x")
  return "Rails (最小骨架) 已生成"
end

M.frameworks = {
  { label = "Ruby CLI", lang = "ruby", gen = gen.ruby_cli, main = "",
    requires = { bins = { "ruby", "bundle" }, pacman = { "ruby" }, note = "bundle 需要 gem install bundler" } },
  { label = "Sinatra (Ruby Web)", lang = "ruby", gen = gen.sinatra, main = "app.rb",
    requires = { bins = { "ruby", "bundle" }, pacman = { "ruby" } } },
  { label = "Rails (Ruby)", lang = "ruby", gen = gen.rails, main = "",
    requires = { bins = { "ruby", "bundle" }, pacman = { "ruby" }, note = "建议用 gem install rails 后 rails new 获得完整骨架" } },
}

return M
