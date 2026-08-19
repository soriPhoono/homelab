{
  inputs,
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.apps.development.editors.neovim;
in
  with lib; {
    options.apps.development.editors.neovim = {
      enable = mkEnableOption "The modular text editor";
    };

    config = mkIf cfg.enable (mkMerge [
      (let
        inherit (inputs.nvf.lib) neovimConfiguration;

        editorPackage = neovimConfiguration {
          inherit pkgs;
          modules =
            [
              {
                disabledModules = [
                  "${inputs.nvf}/modules/plugins/filetree/nvimtree/default.nix"
                  "${inputs.nvf}/modules/plugins/filetree/nvimtree/config.nix"
                  "${inputs.nvf}/modules/plugins/filetree/nvimtree/nvimtree.nix"
                ];
              }
            ]
            ++ (builtins.attrValues (import ../../../../nvf/default.nix {inherit lib;}))
            ++ [
              ../../../../../nvim/${config.home.username}/default.nix
            ];
        };
      in {
        home.packages = [
          editorPackage.neovim
        ];
      })
    ]);
  }
