{
  lib,
  config,
  ...
}: let
  inherit (lib.homelab.containers) mkContainerOption mkContainer;

  proxyCfg = config.hosting.proxy;
  cfg = proxyCfg.docktail;

  name = "docktail";
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

        sops = {
          secrets = {
            "api/tailscale-sidecar-authkey" = {};
            "api/tailscale-oauth-client-id" = {};
            "api/tailscale-oauth-client-secret" = {};
          };
          templates = {
            "docktail/tailscale-oauth" = {
              owner = "microserver";
              content = ''
                TAILSCALE_OAUTH_CLIENT_ID=${config.sops.placeholder."api/tailscale-oauth-client-id"}
                TAILSCALE_OAUTH_CLIENT_SECRET=${config.sops.placeholder."api/tailscale-oauth-client-secret"}
              '';
            };
            "docktail/tailscale-sidecar-authkey" = {
              owner = "microserver";
              content = ''
                TS_AUTHKEY=${config.sops.placeholder."api/tailscale-sidecar-authkey"}
              '';
            };
          };
        };

        virtualisation.oci-containers.containers = {
          tailscale-sidecar = {
            image = "tailscale/tailscale:latest";
            capabilities = {
              NET_ADMIN = true;
            };
            environment = {
              TS_HOSTNAME = "${config.networking.hostName}-microserver";
              TS_SOCKET = "/var/run/tailscale/tailscaled.sock";
              TS_STATE_DIR = "/var/lib/tailscale";
              TS_EXTRA_ARGS = "--advertise-tags=tag:microserver";
              TS_USERSPACE = "true";
            };
            environmentFiles = [
              config.sops.templates."docktail/tailscale-sidecar-authkey".path
            ];
            volumes = [
              "tailscale-state:/var/lib/tailscale"
              "tailscale-socket:/var/run/tailscale"
            ];
            extraOptions = [
              "--network=tailscale"
            ];
            ports = [
              "41642:41641/udp"
            ];
            podman = {
              sdnotify = "conmon";
              user = "microserver";
            };
          };
          ${name} = mkMerge [
            (mkContainer {
              inherit name config;
              cfg = cfg // {container = cfg.container // {publication = [];};};
              image = "ghcr.io/marvinvr/docktail:1.5";
            })
            {
              dependsOn = [
                "tailscale-sidecar"
              ];

              extraOptions = [
                "--network=container:tailscale-sidecar"
              ];

              volumes = [
                (
                  if config.virtualisation.oci-containers.backend == "podman"
                  then "/run/user/${toString config.users.users.microserver.uid}/podman/podman.sock:/var/run/docker.sock:ro"
                  else "/var/run/docker.sock:/var/run/docker.sock:ro"
                )
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
