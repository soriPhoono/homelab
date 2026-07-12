{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.apps.development.appliances.bambu-studio;
in
  with lib; {
    options.apps.development.appliances.bambu-studio = {
      enable = mkEnableOption "Enable Bambu Studio (Bambu Labs printer app)";
    };

    config = mkIf cfg.enable {
      home.packages = with pkgs; [
        bambu-studio
      ];
    };
  }
