/**
  Microservers: containers published to the tailnet through docktail.

  The base aspect runs the docktail proxy and its Tailscale sidecar; each
  sub-aspect adds a group of services that publish through it.
*/
{ den, ... }:
{
  den.aspects.hosting.microserver = {
    includes = [
      den.aspects.hosting.docker
    ];

    nixos =
      { config, ... }:
      {
        sops = {
          secrets = {
            "microserver/tailscale-sidecar-authkey" = { };
            "microserver/tailscale-oauth-client-id" = { };
            "microserver/tailscale-oauth-client-secret" = { };
          };
          templates = {
            "docktail/tailscale-oauth".content = ''
              TAILSCALE_OAUTH_CLIENT_ID=${config.sops.placeholder."microserver/tailscale-oauth-client-id"}
              TAILSCALE_OAUTH_CLIENT_SECRET=${config.sops.placeholder."microserver/tailscale-oauth-client-secret"}
            '';
            "docktail/tailscale-sidecar-authkey".content = ''
              TS_AUTHKEY=${config.sops.placeholder."microserver/tailscale-sidecar-authkey"}
            '';
          };
        };

        virtualisation.oci-containers.containers = {
          tailscale-sidecar = {
            image = "tailscale/tailscale:v1.102.3";
            capabilities.NET_ADMIN = true;
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

          docktail = {
            image = "ghcr.io/marvinvr/docktail:1.3.0";
            dependsOn = [
              "tailscale-sidecar"
            ];
            extraOptions = [
              "--network=container:tailscale-sidecar"
            ];
            volumes = [
              "/var/run/docker.sock:/var/run/docker.sock:ro"
              "tailscale-socket:/var/run/tailscale"
            ];
            environment = {
              DEFAULT_SERVICE_TAGS = "tag:microservice";
            };
            environmentFiles = [
              config.sops.templates."docktail/tailscale-oauth".path
            ];
          };
        };
      };

  };
}
