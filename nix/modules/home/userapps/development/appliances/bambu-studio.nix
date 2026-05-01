{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.userapps.development.appliances.bambu-studio;
in
  with lib; {
    options.userapps.development.appliances.bambu-studio = {
      enable = mkEnableOption "Enable Bambu Studio (Bambu Labs printer app)";
    };

    config = mkIf cfg.enable {
      home.packages = with pkgs; [
        bambu-studio
      ];
    };
  }
