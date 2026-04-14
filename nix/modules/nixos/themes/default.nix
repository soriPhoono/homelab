{
  lib,
  config,
  ...
}: let
  cfg =
    config.themes;
in
  with lib; {
    options.themes = {
      enable = mkEnableOption "themes";
    };

    config = mkIf cfg.enable {
      stylix = {
        enable = true;
        homeManagerIntegration.followSystem = false;
      };
    };
  }
