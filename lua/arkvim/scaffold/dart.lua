-- arkvim/scaffold/dart.lua — Dart / Flutter 模板
local util = require("arkvim.scaffold.util")

local M = {}
local gen = {}

gen.dart_cli = function(target, name)
  local t = util.project_tokens(name)
  util.write_tree(target, {
    ["pubspec.yaml"] = util.fill('name: {{kebab}}\ndescription: {{NAME}}\nversion: 0.1.0\n\nenvironment:\n  sdk: ">=3.2.0 <4.0.0"\n\nexecutables:\n  {{kebab}}: main\n', t),
    ["bin/main.dart"] = util.fill('void main() {\n  print("Hello from {{NAME}}!");\n}\n', t),
    [".gitignore"] = ".dart_tool/\nbuild/\n",
  })
  return "Dart CLI 已生成"
end

gen.flutter = function(target, name)
  local t = util.project_tokens(name)
  if util.executable("flutter") then
    vim.fn.system({ "flutter", "create", "--project-name", t.kebab, target })
    if vim.v.shell_error == 0 then
      return "Flutter 项目已生成"
    end
  end
  -- 离线兜底
  util.write_tree(target, {
    ["pubspec.yaml"] = util.fill('name: {{kebab}}\ndescription: {{NAME}}\nversion: 1.0.0+1\n\nenvironment:\n  sdk: ">=3.2.0 <4.0.0"\n\ndependencies:\n  flutter:\n    sdk: flutter\n  cupertino_icons: ^1.0.6\n\nflutter:\n  uses-material-design: true\n', t),
    ["lib/main.dart"] = util.fill([[
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
  return "Flutter (离线骨架) 已生成（未检测到 flutter 命令）"
end

M.frameworks = {
  { label = "Dart CLI", lang = "dart", gen = gen.dart_cli, main = "bin/main.dart",
    requires = { bins = { "dart" }, pacman = { "dart" } } },
  { label = "Flutter (Dart)", lang = "dart", gen = gen.flutter, main = "lib/main.dart",
    requires = { bins = { "flutter" }, pacman = { "flutter" }, note = "未安装时使用离线骨架，无法热重载" } },
}

return M
