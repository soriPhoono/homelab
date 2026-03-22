{
  lib,
  config,
  ...
}: let
  cfg = config.core.shells.starship;
in {
  options.core.shells.starship = {
    enable = lib.mkEnableOption "starship";
  };

  config = lib.mkIf cfg.enable {
    programs.starship = {
      enable = true;

      settings = {
        add_newline = true;

        format = "$character";
        right_format = "$all";

        character = {
          success_symbol = "[➜](bold green) ";
          error_symbol = "[➜](bold red) ";
        };
      };
    };
  };
}
