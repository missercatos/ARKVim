# ARKVim 的 NixOS 模块：帮你把 home-manager 接起来
#
# 用法（在你的 NixOS flake 里）：
#   {
#     inputs.arkvim.url = "github:missercatos/ARKVim";
#     outputs = { nixpkgs, arkvim, ... }: {
#       nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
#         system = "x86_64-linux";
#         modules = [
#           arkvim.nixosModules.default
#           { programs.arkvim.users = [ "你的用户名" ]; }
#         ];
#       };
#     };
#   }
#
# 然后：sudo nixos-rebuild switch --flake .#myhost
{ self, home-manager }:
{ config, lib, ... }:
let
  cfg = config.programs.arkvim;
in
{
  imports = [ home-manager.nixosModules.home-manager ];

  options.programs.arkvim.users = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
    description = "为这些用户启用 ARKVim（home-manager 用户模块）";
  };

  config = lib.mkIf (cfg.users != [ ]) {
    home-manager.users = lib.genAttrs cfg.users (_: {
      imports = [ self.homeManagerModules.default ];
      programs.arkvim.enable = true;
      # 用户自己没设时给个默认，避免 home-manager 报错（mkDefault 优先级最低）
      home.stateVersion = lib.mkDefault "24.11";
    });
  };
}
