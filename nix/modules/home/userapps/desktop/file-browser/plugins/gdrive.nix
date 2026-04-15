{
  lib,
  pkgs,
  config,
  options,
  ...
}: let
  cfg = config.userapps.desktop.file-browser.plugins.gdrive;
  mountDir = "${config.home.homeDirectory}/GoogleDrive";
  rcloneConf = "${config.home.homeDirectory}/.config/rclone/rclone.conf";
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
        default = mountDir;
        description = "Local path for Google Drive bidirectional sync";
      };

      syncInterval = mkOption {
        type = types.str;
        default = "15m";
        description = "How often to run rclone bisync to keep the local copy current";
      };

      secretsFile = mkOption {
        type = with types; nullOr path;
        default = null;
        description = ''
          Override the sops file used for gdrive/client_id and gdrive/client_secret.
          Defaults to core.secrets.defaultSopsFile when null.
        '';
      };
    };

    config = mkIf cfg.enable (mkMerge [
      # ── Package + writable rclone.conf bootstrap ─────────────────────────
      {
        home.packages = [pkgs.rclone];

        # Seed a minimal writable rclone.conf if the remote stanza is missing.
        # rclone updates this file in-place on every token refresh – sops never
        # manages it.  The OAuth credentials are injected at runtime via the
        # RCLONE_DRIVE_* env vars defined in the systemd units below.
        home.activation.initGdriveRcloneConf = lib.hm.dag.entryAfter ["writeBoundary"] ''
          RCLONE_CONF="${rcloneConf}"
          mkdir -p "$(dirname "$RCLONE_CONF")"
          if ! grep -qs '^\[${cfg.remote}\]' "$RCLONE_CONF" 2>/dev/null; then
            printf '[%s]\ntype = drive\nscope = drive\n' '${cfg.remote}' >> "$RCLONE_CONF"
            echo "gdrive: bootstrapped [${cfg.remote}] stanza in rclone.conf"
          fi
        '';

        home.activation.createGdriveMountDir = lib.hm.dag.entryAfter ["writeBoundary"] ''
          mkdir -p ${cfg.mountPoint}
        '';
      }

      # ── Sops secrets + systemd units (only when sops module is present) ──
      (mkIf (options ? sops) (let
        # Per the rclone drive docs, the correct env vars for the drive backend
        # are RCLONE_DRIVE_CLIENT_ID and RCLONE_DRIVE_CLIENT_SECRET.
        # These are backend-global (not per-remote), and are read by rclone
        # at startup, while the token stanza is persisted and refreshed
        # in-place inside the writable ~/.config/rclone/rclone.conf.
        # See: https://rclone.org/drive/#standard-options
        mkEnvScript = name: rcloneCmd:
          pkgs.writeShellApplication {
            inherit name;
            runtimeInputs = [pkgs.rclone];
            text = ''
              export RCLONE_DRIVE_CLIENT_ID
              RCLONE_DRIVE_CLIENT_ID="$(cat "${config.sops.secrets."gdrive/client_id".path}")"

              export RCLONE_DRIVE_CLIENT_SECRET
              RCLONE_DRIVE_CLIENT_SECRET="$(cat "${config.sops.secrets."gdrive/client_secret".path}")"

              exec rclone ${rcloneCmd}
            '';
          };

        syncScript =
          mkEnvScript "rclone-gdrive-sync"
          "bisync ${cfg.remote}: ${cfg.mountPoint} --resilient --recover --log-level INFO";
      in {
        # Unconditionally declare both secrets so .path is always resolvable
        # in the let-bindings above.  The inner mkIf only conditionally
        # overrides the sopsFile; the {} ensures the keys are always present.
        sops.secrets."gdrive/client_id" = mkMerge [
          {}
          (mkIf (cfg.secretsFile != null) {sopsFile = cfg.secretsFile;})
        ];
        sops.secrets."gdrive/client_secret" = mkMerge [
          {}
          (mkIf (cfg.secretsFile != null) {sopsFile = cfg.secretsFile;})
        ];

        # Bisync service: oneshot periodic sync
        systemd.user.services.rclone-gdrive-sync = {
          Unit = {
            Description = "rclone bisync for Google Drive (${cfg.remote}:)";
            After = ["network-online.target"];
            Wants = ["network-online.target"];
          };
          Service = {
            Type = "oneshot";
            ExecStart = "${syncScript}/bin/rclone-gdrive-sync";
          };
        };

        # Timer: fires the bisync service on schedule
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
      }))
    ]);
  }
