{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.userapps.office.slack;
in
  with lib; {
    options.userapps.office.slack = {
      enable = mkEnableOption "Enable Slack desktop client";
    };

    config = mkIf cfg.enable {
      home.packages = with pkgs; [
        slack
      ];
    };
  }
