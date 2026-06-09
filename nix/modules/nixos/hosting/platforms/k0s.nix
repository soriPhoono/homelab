{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.hosting.platforms.k0s;
  yamlFormat = pkgs.formats.yaml {};
  configFile = yamlFormat.generate "k0s.yaml" cfg.config;
in
  with lib; {
    options.hosting.platforms.k0s = {
      enable = mkEnableOption "Enable k0s (Zero Friction Kubernetes)";

      role = mkOption {
        type = types.enum ["controller" "worker" "single"];
        default = "single";
        description = ''
          The role of the k0s node:
          - `controller`: runs control plane only
          - `worker`: runs worker plane only
          - `single`: runs both control plane and worker plane on this machine
        '';
      };

      config = mkOption {
        inherit (yamlFormat) type;
        default = {};
        description = "Declarative configuration for k0s.";
      };

      extraArgs = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "Extra arguments to pass to the k0s command.";
      };

      taintControlPlane = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to taint the control plane node so workloads only run on workers.";
      };

      tokenFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Path to file containing join token (required for worker role or multi-node controller).";
      };
    };

    config = mkIf cfg.enable {
      # Load required kernel modules for container runtimes & Kubernetes networking
      boot.kernelModules = [
        "br_netfilter"
        "overlay"
        "ip_vs"
        "ip_vs_rr"
        "ip_vs_wrr"
        "ip_vs_sh"
        "nf_conntrack"
      ];

      # Configure required sysctl parameters
      boot.kernel.sysctl = {
        "net.bridge.bridge-nf-call-iptables" = 1;
        "net.bridge.bridge-nf-call-ip6tables" = 1;
        "net.ipv4.ip_forward" = 1;
      };

      # Make the k0s CLI available globally for administration
      environment.systemPackages = [
        pkgs.k0s
      ];

      # Define systemd service for k0s
      systemd.services.k0s = {
        description = "k0s - Zero Friction Kubernetes";
        after = ["network-online.target"];
        wants = ["network-online.target"];
        wantedBy = ["multi-user.target"];

        # Ensure all helper utilities are available to k0s at runtime
        path = with pkgs; [
          kmod
          iptables
          iproute2
          util-linux
          ethtool
          socat
          conntrack-tools
          mount
        ];

        serviceConfig = let
          command =
            if cfg.role == "worker"
            then "worker"
            else "controller";
          args =
            [
              command
            ]
            ++ optionals (cfg.role == "single") [
              "--enable-worker"
            ]
            ++ optionals (cfg.role == "single" && !cfg.taintControlPlane) [
              "--no-taints"
            ]
            ++ optionals (cfg.role == "controller" || cfg.role == "single") [
              "--config=${configFile}"
            ]
            ++ optionals (cfg.tokenFile != null) [
              "--token-file=${cfg.tokenFile}"
            ]
            ++ cfg.extraArgs;
        in {
          Type = "simple";
          ExecStart = "${pkgs.k0s}/bin/k0s ${escapeShellArgs args}";

          Restart = "always";
          RestartSec = "10s";
          KillMode = "process";
          LimitNOFILE = 1048576;
          LimitNPROC = 1048576;
          LimitCORE = "infinity";
          TasksMax = "infinity";
          Delegate = "yes";
        };
      };
    };
  }
