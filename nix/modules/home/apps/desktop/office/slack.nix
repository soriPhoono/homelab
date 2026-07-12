{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.apps.desktop.office.slack;
in
  with lib; {
    options.apps.desktop.office.slack = {
      enable = mkEnableOption "Enable Slack desktop client";
    };

    config = mkIf cfg.enable {
      home.packages = with pkgs; [
        slack
      ];
    };
  }
