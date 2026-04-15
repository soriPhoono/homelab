{
  lib,
  config,
  options,
  ...
}: let
  cfg = config.userapps.desktop.file-browser.plugins.gdrive;
in
  with lib; {
    options.userapps.desktop.file-browser.plugins.gdrive = {
      enable = mkEnableOption "Google Drive rclone bisync";

      remote = mkOption {
        type = types.str;
        default = "gdrive";
        description = "rclone remote name – must match the stanza in ~/.config/rclone/rclone.conf";
      };

      mountPoint = mkOption {
        type = types.str;
        default = "${config.home.homeDirectory}/GoogleDrive";
        description = "Local path for Google Drive bidirectional sync";
      };
    };

    config =
      mkIf cfg.enable
      {
        sops.secrets = mkIf (options ? sops) {
          "gdrive/client_id" = {};
          "gdrive/client_secret" = {};
        };

        programs.rclone = {
          enable = true;
          requiresUnit = "sops-nix.service";
          remotes."${cfg.remote}" = {
            config = {
              type = "drive";
              scope = "drive";
            };
            secrets = mkIf (options ? sops) {
              client_id = config.sops.secrets."gdrive/client_id".path;
              client_secret = config.sops.secrets."gdrive/client_secret".path;
            };
            mounts = {
              "${cfg.mountPoint}" = {
                inherit (cfg) mountPoint;

                enable = true;
              };
            };
          };
        };
      };
  }
