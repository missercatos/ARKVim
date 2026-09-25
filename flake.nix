{
  description = "ARKVim — Neovim 配置（NixOS / home-manager 一键复现）";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = f:
        nixpkgs.lib.genAttrs systems (system: f {
          inherit system;
          pkgs = nixpkgs.legacyPackages.${system};
        });
    in
    {
      # ---- home-manager 模块（推荐路径） ----
      #   imports = [ arkvim.homeManagerModules.default ];
      #   programs.arkvim.enable = true;
      homeManagerModules = {
        default = import ./nix/module.nix { src = self; };
        arkvim = self.homeManagerModules.default;
      };

      # ---- NixOS 模块（内部用 home-manager 承接） ----
      #   imports = [ arkvim.nixosModules.default ];
      #   programs.arkvim.users = [ "you" ];
      nixosModules = {
        default = import ./nix/nixos.nix { inherit self home-manager; };
        arkvim = self.nixosModules.default;
      };

      # nix run github:missercatos/ARKVim  ->  带全套工具的 nvim
      packages = forAllSystems ({ pkgs, ... }:
        let
          tools = import ./nix/tools.nix { inherit pkgs; };
        in
        {
          default = pkgs.writeShellApplication {
            name = "arkvim";
            runtimeInputs = tools ++ [ pkgs.neovim ];
            text = ''
              export ARKVIM_NO_MASON="''${ARKVIM_NO_MASON:-1}"
              exec nvim "$@"
            '';
          };
        });

      # nix develop github:missercatos/ARKVim  ->  带全套工具的 shell
      devShells = forAllSystems ({ pkgs, ... }:
        let
          tools = import ./nix/tools.nix { inherit pkgs; };
        in
        {
          default = pkgs.mkShell {
            packages = tools ++ [ pkgs.neovim ];
            shellHook = ''
              echo "ARKVim 环境就绪：neovim + LSP/格式化/各语言工具链"
              echo "直接运行 nvim 即可；配置来自当前目录"
            '';
          };
        });

      formatter = forAllSystems ({ pkgs, ... }:
        if pkgs ? nixfmt-rfc-style then pkgs.nixfmt-rfc-style else pkgs.nixfmt);
    };
}
