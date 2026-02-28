# TODO: look into selinux support for public facing environments
{
  lib,
  config,
  ...
}: let
  cfg = config.hosting.clustering.backends.k3s;
in
  with lib; {
    options.hosting.clustering.backends.k3s = {
      enable = mkEnableOption "k3s backend";

      mode = mkOption {
        type = with types; oneOf ["leader" "server" "agent"];
        default = "leader";
        description = "The mode of the k3s backend.";
      };

      leaderIP = mkOption {
        type = with types; nullOr str;
        default = null;
        description = "The IP address of the k3s leader node.";
      };

      nodeIP = mkOption {
        type = with types; nullOr str;
        default = null;
        description = "The IP address of the k3s node.";
      };
    };

    config = mkIf cfg.enable (mkMerge [
      {
        sops.secrets."hosting/k3s/token" = {
          path = "/var/lib/rancher/k3s/server/node-token";
          mode = "0600";
          owner = "root";
          group = "root";
        };

        networking.firewall = {
          allowedTCPPorts = [
            6443 # k3s: required so that pods can reach the API server (running on port 6443 by default)
            2379 # k3s, etcd clients: required if using a "High Availability Embedded etcd" configuration
            2380 # k3s, etcd peers: required if using a "High Availability Embedded etcd" configuration
          ];
          allowedUDPPorts = [
            8472 # k3s, flannel: required if using multi-node for inter-node networking
          ];
        };

        services.k3s = {
          enable = true;
          tokenFile = config.sops.secrets."hosting/k3s/token".path;
          gracefulNodeShutdown.enable = true;
        };
      }
      (mkIf (cfg.mode == "leader") {
        services.k3s = {
          inherit (cfg) nodeIP;

          role = "server";
          clusterInit = true;
        };
      })
      (mkIf (cfg.mode != "leader") {
        services.k3s = {
          inherit (cfg) nodeIP;

          role = cfg.mode;
          serverAddr = cfg.leaderIP;
        };
      })
    ]);
  }
