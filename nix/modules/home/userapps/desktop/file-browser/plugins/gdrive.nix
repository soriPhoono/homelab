{
  lib,
  pkgs,
  config,
  options,
  ...
}: let
  cfg = config.userapps.desktop.file-browser.plugins.gdrive;
  mountDir = "${config.home.homeDirectory}/GoogleDrive";
  rcloneConfName = "rclone/rclone.conf";
in
  with lib; {
    options.userapps.desktop.file-browser.plugins.gdrive = {
      enable = mkEnableOption "Google Drive rclone mount via FUSE";

      remote = mkOption {
        type = types.str;
        default = "gdrive";
        description = "Name used for the rclone remote in rclone.conf";
      };

      mountPoint = mkOption {
        type = types.str;
        default = mountDir;
        description = "Local FUSE mount path for Google Drive";
      };

      syncInterval = mkOption {
        type = types.str;
        default = "15m";
        description = "How often to run rclone bisync to keep the mount current";
      };
    };

    config = mkIf cfg.enable (
      mkMerge [
        # ── Package ─────────────────────────────────────────────────────────
        {
          home.packages = [pkgs.rclone];

          # Ensure mount point exists before activation
          home.activation.createGdriveMountDir = lib.hm.dag.entryAfter ["writeBoundary"] ''
            mkdir -p ${cfg.mountPoint}
          '';
        }

        # ── Secrets + templated rclone.conf ─────────────────────────────────
        (mkIf (options ? sops) {
          sops.secrets."gdrive/client_id" = {};
          sops.secrets."gdrive/client_secret" = {};

          # sops-nix renders this file at activation time, substituting placeholders
          # with the real decrypted secret values.
          sops.templates.${rcloneConfName} = {
            # Mode 0600 so only the user can read the OAuth tokens
            mode = "0600";
            content = ''
              [${cfg.remote}]
              type = drive
              client_id = ${config.sops.placeholder."gdrive/client_id"}
              client_secret = ${config.sops.placeholder."gdrive/client_secret"}
              scope = drive
              token_expiry_delta = 1m0s
            '';
          };
        })

        # ── Systemd: mount service ───────────────────────────────────────────
        {
          systemd.user.services.rclone-gdrive-mount = {
            Unit = {
              Description = "rclone FUSE mount for Google Drive (${cfg.remote}:)";
              After = ["network-online.target"];
              Wants = ["network-online.target"];
            };
            Service = {
              Type = "notify";
              ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p ${cfg.mountPoint}";
              ExecStart = lib.mkIf (options ? sops) (
                "${pkgs.rclone}/bin/rclone mount ${cfg.remote}: ${cfg.mountPoint}"
                + " --config ${config.sops.templates.${rcloneConfName}.path}"
                + " --vfs-cache-mode full"
                + " --vfs-cache-max-size 2G"
                + " --log-level INFO"
                + " --systemd-notify"
              );
              ExecStop = "${pkgs.fuse}/bin/fusermount -u ${cfg.mountPoint}";
              Restart = "on-failure";
              RestartSec = "5s";
            };
            Install = {
              WantedBy = ["default.target"];
            };
          };
        }

        # ── Systemd: bisync service + timer ─────────────────────────────────
        {
          systemd.user.services.rclone-gdrive-sync = {
            Unit = {
              Description = "rclone bisync for Google Drive (${cfg.remote}:)";
              After = ["network-online.target" "rclone-gdrive-mount.service"];
              Wants = ["network-online.target"];
            };
            Service = {
              Type = "oneshot";
              ExecStart = lib.mkIf (options ? sops) (
                "${pkgs.rclone}/bin/rclone bisync ${cfg.remote}: ${cfg.mountPoint}"
                + " --config ${config.sops.templates.${rcloneConfName}.path}"
                + " --resilient"
                + " --recover"
                + " --log-level INFO"
              );
            };
          };

          systemd.user.timers.rclone-gdrive-sync = {
            Unit = {
              Description = "Periodic rclone bisync for Google Drive";
            };
            Timer = {
              OnBootSec = "2m";
              OnUnitActiveSec = cfg.syncInterval;
            };
            Install = {
              WantedBy = ["timers.target"];
            };
          };
        }
      ]
    );
  }
