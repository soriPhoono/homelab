{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.userapps.data-fortress.auth.bitwarden;
in
  with lib; {
    options.userapps.data-fortress.auth.bitwarden = {
      enable = mkEnableOption "Enable Bitwarden desktop client";

      ssh-agent.enable = mkEnableOption "Enable Bitwarden SSH agent";
    };

    config = mkIf cfg.enable {
      home.packages = with pkgs; [
        bitwarden-desktop
      ];
    };
  }
