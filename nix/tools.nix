# ARKVim 外部工具清单（LSP / 格式化 / 检查 / 运行时 / 常用 CLI）
#
# 用 lib.attrByPath + tryEval 安全取包：某个包在当前 nixpkgs 里改名/不存在/
# 已废弃时会被静默跳过，不会让整个 flake 求值失败。
# 想精简：直接注释掉对应行即可。
{ pkgs }:
let
  inherit (pkgs) lib;

  # 安全取一个属性路径；不存在或 throwing alias 都返回 []
  opt = path:
    let
      r = builtins.tryEval (lib.attrByPath path null pkgs);
    in
    if r.success && r.value != null then [ r.value ] else [];

  paths = [
    # ---------- 基础 CLI ----------
    [ "ripgrep" ] [ "fd" ] [ "git" ] [ "lazygit" ] [ "gh" ]
    [ "curl" ] [ "wget" ] [ "unzip" ] [ "zip" ] [ "tar" ] [ "gzip" ]
    [ "jq" ] [ "yq" ] [ "tree" ] [ "less" ] [ "file" ] [ "which" ]
    [ "gnused" ] [ "gnugrep" ] [ "findutils" ] [ "coreutils" ]
    [ "tree-sitter" ]

    # ---------- 语言运行时 / 工具链 ----------
    [ "nodejs" ] [ "bun" ] [ "deno" ]
    [ "python3" ] [ "uv" ]
    [ "go" ] [ "gopls" ] [ "gotools" ] [ "gofumpt" ] [ "golangci-lint" ] [ "delve" ]
    [ "rustc" ] [ "cargo" ] [ "rust-analyzer" ] [ "rustfmt" ] [ "clippy" ]
    [ "jdk" ] [ "jdt-language-server" ] [ "google-java-format" ] [ "maven" ] [ "gradle" ]
    [ "kotlin" ] [ "kotlin-language-server" ]
    [ "gcc" ] [ "clang" ] [ "clang-tools" ] [ "cmake" ] [ "ninja" ] [ "gnumake" ]
    [ "gdb" ] [ "lldb" ]
    [ "php" ] [ "phpPackages" "composer" ]
    [ "ruby" ]
    [ "lua5_1" ] [ "luajit" ] [ "lua-language-server" ] [ "luacheck" ] [ "stylua" ]
    [ "dart" ]
    [ "elixir" ] [ "elixir-ls" ]
    [ "erlang" ] [ "rebar3" ]
    [ "ghc" ] [ "cabal-install" ] [ "haskell-language-server" ]
    [ "ocaml" ] [ "dune_3" ] [ "ocamlPackages" "ocaml-lsp" ]
    [ "zig" ] [ "zls" ]
    [ "nim" ] [ "nimble" ]
    [ "crystal" ] [ "shards" ]
    [ "julia" ]
    [ "dotnet-sdk" ]
    [ "clojure" ] [ "leiningen" ]
    [ "scala" ] [ "sbt" ]
    [ "sbcl" ] [ "guile" ] [ "racket" ]
    [ "R" ]

    # ---------- LSP（编辑器用） ----------
    [ "nil" ] [ "nixd" ]
    [ "basedpyright" ] [ "pyright" ] [ "ruff" ] [ "mypy" ] [ "black" ]
    [ "vscode-langservers-extracted" ]
    [ "typescript-language-server" ] [ "nodePackages" "typescript" ]
    [ "yaml-language-server" ] [ "bash-language-server" ]
    [ "dockerfile-language-server" ] [ "docker-compose-language-service" ]
    [ "emmet-language-server" ] [ "tailwindcss-language-server" ]
    [ "intelephense" ]
    [ "astro-language-server" ] [ "svelte-language-server" ] [ "vue-language-server" ]
    [ "html-lsp" ] [ "css-lsp" ] [ "json-lsp" ]
    [ "kotlin-language-server" ]

    # ---------- 格式化 / 检查 ----------
    [ "prettier" ] [ "prettierd" ]
    [ "shfmt" ] [ "shellcheck" ] [ "hadolint" ] [ "yamllint" ]
    [ "nixfmt-rfc-style" ] [ "alejandra" ] [ "statix" ] [ "deadnix" ]
    [ "eslint" ] [ "markdownlint-cli" ] [ "taplo" ] [ "sqlfluff" ]
    [ "rubyPackages" "rubocop" ] [ "rubyPackages" "solargraph" ]

    # ---------- 其它 ----------
    [ "sqlite" ] [ "redis" ] [ "postgresql" ]
    [ "docker-compose" ] [ "kubectl" ] [ "helm" ]
    [ "imagemagick" ] [ "ffmpeg" ] [ "chafa" ]
    [ "mpv" ] [ "yt-dlp" ]
    [ "watchexec" ] [ "entr" ]
    [ "btop" ] [ "htop" ] [ "ncdu" ] [ "lsof" ] [ "strace" ]
    [ "pkg-config" ] [ "xz" ]
  ];
in
lib.concatMap opt paths
