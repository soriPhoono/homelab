{
  lib,
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
      {
        # home.packages = [
        #   editorPackage.neovim
        # ];

        programs.nvf = {
          enable = true;

          settings = import ../../../../../nvim/${config.home.username}/default.nix;
        };
      }
    ]);
  }
