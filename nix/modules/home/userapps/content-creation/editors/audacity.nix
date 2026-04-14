{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.userapps.content-creation.editors.audacity;
in
  with lib; {
    options.userapps.content-creation.editors.audacity = {
      enable = mkEnableOption "Enable Audacity audio editor";
    };

    config = mkIf cfg.enable {
      home.packages = with pkgs; [
        audacity
      ];
    };
  }
