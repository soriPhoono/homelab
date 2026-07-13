{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.apps.content-creation.asset-creation.darktable;
in
  with lib; {
    options.apps.content-creation.asset-creation.darktable = {
      enable = mkEnableOption "Enable the darktable photo editing software";
    };

    config = mkIf cfg.enable {
      home.packages = with pkgs; [
        darktable
      ];
    };
  }
