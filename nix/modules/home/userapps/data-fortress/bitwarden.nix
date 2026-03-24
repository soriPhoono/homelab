{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.userapps.data-fortress.bitwarden;
in
  with lib; {
    options.userapps.data-fortress.bitwarden = {
      enable = mkEnableOption "Enable Bitwarden desktop client";
    };

    config = mkIf cfg.enable {
      home.packages = with pkgs; [
        bitwarden-cli
        bitwarden-desktop
      ];

      core.shells.sessionVariables = {
        SSH_AUTH_SOCK = "/home/${config.home.username}/.bitwarden-ssh-agent.sock";
      };
    };
  }
