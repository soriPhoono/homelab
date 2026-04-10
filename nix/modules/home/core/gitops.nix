{
  config,
  lib,
  pkgs,
  nixosConfig,
  ...
}: let
  cfg = config.core.gitops;
in {
  options.core.gitops = {
    enable = lib.mkEnableOption "Enable Home Manager GitOps";
    repo = lib.mkOption {
      type = lib.types.str;
      description = "Git repository URL to fetch updates from";
    };
    branch = lib.mkOption {
      type = lib.types.str;
      default = "main";
      description = "Branch to pull from";
    };
    interval = lib.mkOption {
      type = lib.types.str;
      default = "15m";
      description = "Interval between syncs";
    };
  };

  config = lib.mkIf (cfg.enable && !nixosConfig) {
    systemd.user.services.hm-gitops = {
      Unit = {
        Description = "Home Manager GitOps Sync Service";
      };
      Service = {
        Type = "oneshot";
        # We assume the flake is located at ~/Documents/Projects/homelab as per context
        ExecStart = "${pkgs.writeShellApplication {
          name = "hm-gitops-sync";
          runtimeDependencies = with pkgs; [
            git
            nh
          ];
          text = ''
            set -e
            FLAKE_DIR="${config.home.homeDirectory}/.homelab"
            if [ -d "$FLAKE_DIR" ]; then
              cd "$FLAKE_DIR"
              git fetch origin
              git reset --hard origin/${cfg.branch}
              # Using nh for the actual switch
              nh home switch .
            else
              git clone ${cfg.repo} "$FLAKE_DIR"
              cd "$FLAKE_DIR"
              nh home switch .
            fi
          '';
        }}/bin/hm-gitops-sync";
      };
    };

    systemd.user.timers.hm-gitops = {
      Unit = {
        Description = "Home Manager GitOps Sync Timer";
      };
      Timer = {
        OnBootSec = "2m";
        OnUnitActiveSec = cfg.interval;
      };
      Install = {
        WantedBy = ["timers.target"];
      };
    };
  };
}
