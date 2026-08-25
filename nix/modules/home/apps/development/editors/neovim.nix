{
  lib,
  config,
  ...
}: let
  cfg = config.apps.development.editors.neovim;
in
  with lib; {
    imports = [
      (import ../../../../../nvim/sphoono/default.nix)
    ];

    options.apps.development.editors.neovim = {
      enable = mkEnableOption "The modular text editor";
    };

    config = mkIf cfg.enable {
      programs.nvf.enable = true;
    };
  }
