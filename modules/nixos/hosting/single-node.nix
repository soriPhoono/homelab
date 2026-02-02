{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.hosting.configuration.single-node;
in
  with lib; {
    imports = [
      ./backends/docker.nix
      ./backends/podman.nix
    ];

    options.hosting.configuration.single-node = {
      networks = mkOption {
        type = with types; listOf str;
        description = "The networks to create in the docker environment being created by this module";
        default = [];
        example = [
          "admin_traefik-public"
        ];
      };

      domainName = mkOption {
        type = types.str;
        description = "The domain name of this service runner, for creating primary service applications with which to build further infrastructure";
        default = null;
        example = "example.com";
      };

      portainerMode = mkOption {
        type = with types; nullOr (enum ["server" "agent" "edge-agent" "edge-agent-async"]);
        default = null;
        description = "The mode to deploy portainer agent/edge-agent, and a possible portainer server";
        example = "server";
      };
    };

    config = mkIf (config.hosting.mode == "single-node") {
      hosting.backends.docker.enable = true;

      sops = mkIf (cfg.domainName != null) {
        secrets."hosting/admin/cf_api_token" = {};
        templates."docker_traefik.env".content = ''
          CLOUDFLARE_DNS_API_TOKEN=${config.sops.placeholder."hosting/admin/cf_api_token"}
        '';
      };

      systemd.services = let
        allNetworks = unique (
          flatten (mapAttrsToList (_: c: c.networks or []) config.virtualisation.oci-containers.containers)
          ++ cfg.networks
        );
      in
        {
          docker-create-networks = {
            description = "Create networks required by core docker service layer";
            after = ["docker.service"];
            wantedBy = ["multi-user.target"];
            serviceConfig = {
              Type = "oneshot";
              ExecStart = "${pkgs.writeShellScriptBin "docker-create-networks" ''
                ${lib.concatStringsSep "\n" (map (network: ''
                    if ! ${pkgs.docker}/bin/docker network ls --format '{{.Name}}' | grep -q "^${network}$"; then
                      ${pkgs.docker}/bin/docker network create ${network}
                    fi
                  '')
                  allNetworks)}
              ''}/bin/docker-create-networks";
            };
          };
        }
        // (lib.genAttrs
          (lib.mapAttrsToList (_: c: c.serviceName) config.virtualisation.oci-containers.containers)
          (_: {
            after = ["docker-create-networks.service"];
            bindsTo = ["docker-create-networks.service"];
          }));

      virtualisation.oci-containers.containers = let
        traefikLabels = {
          name,
          host,
          port,
          extraLabels ? {},
        }:
          {
            "traefik.enable" = "true";
            "traefik.http.routers.${name}.rule" = "Host(`${host}`)";
            "traefik.http.routers.${name}.entrypoints" = "websecure";
            "traefik.http.routers.${name}.tls" = "true";
            "traefik.http.routers.${name}.tls.certresolver" = "cf-ts";
            "traefik.http.services.${name}.loadbalancer.server.port" = toString port;
          }
          // extraLabels;
      in {
        admin_portainer-agent = mkMerge [
          (mkIf (builtins.elem cfg.portainerMode ["agent" "server"]) {
            image = "portainer/agent:lts";
            volumes = ["/var/run/docker.sock:/var/run/docker.sock"];
            networks = ["admin_portainer-agent"];
          })
          (mkIf (builtins.elem cfg.portainerMode ["edge-agent" "edge-agent-async"]) {
            image = "portainer/agent:lts";
            volumes = [
              "/var/run/docker.sock:/var/run/docker.sock"
              "/var/lib/docker/volumes:/var/lib/docker/volumes"
              "/:/host"
            ];
            networks = ["admin_portainer-agent"];
            environment = {
              EDGE = "1";
              EDGE_ID = "";
              EDGE_KEY = "";
              EDGE_INSECURE_POLL = "0";
            };
          })
        ];

        admin_portainer-server = mkIf (cfg.portainerMode == "server") {
          image = "portainer/portainer-ee:latest";
          dependsOn = ["admin_portainer-agent"];
          cmd = ["-H" "tcp://admin_portainer-agent:9001" "--tlsskipverify"];
          volumes = ["admin_portainer-data:/data"];
          networks = ["admin_portainer-agent" "admin_traefik-public"];
          labels = traefikLabels {
            name = "portainer";
            host = "admin.ts.${cfg.domainName}";
            port = 9000;
          };
        };

        admin_traefik-proxy = mkIf (cfg.domainName != null) {
          image = "traefik:latest";
          cmd = [
            "--entrypoints.web.address=:80"
            "--entrypoints.websecure.address=:443"
            "--entrypoints.websecure.http.tls=true"
            "--entrypoints.traefik.address=:8080"
            "--providers.docker=true"
            "--providers.docker.exposedbydefault=false"
            "--providers.docker.network=admin_traefik-public"
            "--api.dashboard=true"
            "--api.insecure=false"
            "--certificatesresolvers.cf-ts.acme.email=admin@${cfg.domainName}"
            "--certificatesresolvers.cf-ts.acme.storage=/acme/acme.json"
            "--certificatesresolvers.cf-ts.acme.dnschallenge=true"
            "--certificatesresolvers.cf-ts.acme.dnschallenge.provider=cloudflare"
            "--log.level=INFO"
            "--accesslog=true"
            "--metrics.prometheus=true"
            "--entrypoints.web.http.redirections.entrypoint.to=websecure"
            "--entrypoints.web.http.redirections.entrypoint.scheme=https"
            "--entrypoints.web.http.redirections.entrypoint.permanent=true"
          ];
          environmentFiles = [config.sops.templates."docker_traefik.env".path];
          volumes = [
            "/var/run/docker.sock:/var/run/docker.sock:ro"
            "admin_traefik-certs:/acme"
          ];
          networks = ["admin_traefik-public"];
          ports = ["80:80" "443:443"];
        };
      };
    };
  }
