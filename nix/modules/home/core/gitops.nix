{
  config,
  lib,
  pkgs,
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

  config = lib.mkIf cfg.enable {
    systemd.user.services.hm-gitops = {
      Unit = {
        Description = "Home Manager GitOps Sync Service";
      };
      Service = {
        Type = "oneshot";
        # We assume the flake is located at ~/Documents/Projects/homelab as per context
        ExecStart = let
          syncScript = pkgs.writeShellScript "hm-gitops-sync" ''
            set -e
            FLAKE_DIR="${config.home.homeDirectory}/Documents/Projects/homelab"
            if [ -d "$FLAKE_DIR" ]; then
              cd "$FLAKE_DIR"
              ${pkgs.git}/bin/git fetch origin
              ${pkgs.git}/bin/git reset --hard origin/${cfg.branch}
              # Using nh for the actual switch
              ${pkgs.nh}/bin/nh home switch .
            fi
          '';
        in "${syncScript}";
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
