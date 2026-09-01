{
  lib,
  config,
  options,
  ...
}: let
  inherit (lib.homelab.containers) mkContainerOption mkContainer;

  proxyCfg = config.hosting.proxy;
  cfg = proxyCfg.docktail;

  name = "docktail";

  dockerSocket =
    if config.virtualisation.oci-containers.backend == "podman"
    then "/run/podman/podman.sock"
    else "/var/run/docker.sock";
in
  with lib; {
    options.hosting.proxy.${name} = mkContainerOption {
      inherit name;
      description = "Docktail, used for reverse proxying over tailscale.";
    };

    config = mkIf cfg.enable (mkMerge [
      {
        assertions = [
          {
            message = "Docktail requires Tailscale to be enabled.";
            assertion = config.services.tailscale.enable;
          }
        ];

        sops = mkIf (options ? sops) {
          secrets = {
            "api/tailscale-sidecar-authkey" = {};
            "api/tailscale-oauth-client-id" = {};
            "api/tailscale-oauth-client-secret" = {};
          };
          templates = {
            "docktail/tailscale-oauth" = {
              content = ''
                TAILSCALE_OAUTH_CLIENT_ID=${config.sops.placeholder."api/tailscale-oauth-client-id"}
                TAILSCALE_OAUTH_CLIENT_SECRET=${config.sops.placeholder."api/tailscale-oauth-client-secret"}
              '';
            };
            "docktail/tailscale-sidecar-authkey" = {
              content = ''
                TS_AUTHKEY=${config.sops.placeholder."api/tailscale-sidecar-authkey"}
              '';
            };
          };
        };

        virtualisation.oci-containers.containers = {
          tailscale-sidecar = {
            image = "tailscale/tailscale:v1.102.3";
            capabilities = {
              NET_ADMIN = true;
            };
            environment = {
              TS_HOSTNAME = "${config.networking.hostName}-microserver";
              TS_SOCKET = "/var/run/tailscale/tailscaled.sock";
              TS_STATE_DIR = "/var/lib/tailscale";
              TS_EXTRA_ARGS = "--advertise-tags=tag:microserver";
              TS_USERSPACE = "false";
            };
            environmentFiles = [
              config.sops.templates."docktail/tailscale-sidecar-authkey".path
            ];
            volumes = [
              "tailscale-state:/var/lib/tailscale"
              "tailscale-socket:/var/run/tailscale"
            ];
            networks = [
              "tailscale"
            ];
            extraOptions = [
              "--device=/dev/net/tun:/dev/net/tun"
            ];
            ports = [
              "41642:41641/udp"
            ];
          };
          ${name} = mkMerge [
            (mkContainer {
              inherit name config;
              cfg = cfg // {container = cfg.container // {publication = [];};};
              image = "ghcr.io/marvinvr/docktail:1.3.0";
            })
            {
              dependsOn = [
                "tailscale-sidecar"
              ];

              extraOptions = [
                "--network=container:tailscale-sidecar"
              ];

              volumes = [
                "${dockerSocket}:/var/run/docker.sock:ro"
                "tailscale-socket:/var/run/tailscale"
              ];

              environment = {
                DEFAULT_SERVICE_TAGS = "tag:microservice";
              };

              environmentFiles = [
                config.sops.templates."docktail/tailscale-oauth".path
              ];
            }
          ];
        };
      }
    ]);
  }
