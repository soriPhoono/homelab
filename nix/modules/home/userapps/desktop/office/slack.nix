{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.userapps.desktop.office.slack;
in
  with lib; {
    options.userapps.desktop.office.slack = {
      enable = mkEnableOption "Enable Slack desktop client";
    };

    config = mkIf cfg.enable {
      home.packages = with pkgs; [
        slack
      ];
    };
  }
