{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.apps.content-creation.editors.audacity;
in
  with lib; {
    options.apps.content-creation.editors.audacity = {
      enable = mkEnableOption "Enable Audacity audio editor";
    };

    config = mkIf cfg.enable {
      home.packages = with pkgs; [
        audacity
      ];
    };
  }
