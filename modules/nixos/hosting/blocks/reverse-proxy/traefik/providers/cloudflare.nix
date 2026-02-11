{
  lib,
  config,
  ...
}: let
  cfg = config.hosting.blocks.reverse-proxy.domain.provider;
in
  with lib; {
    config = mkIf (cfg.type == "cloudflare") {
      sops = {
        secrets."hosting/admin/cf_api_token" = {};
        templates."docker_traefik.env".content = concatStringsSep "\n" [
          ''
            CLOUDFLARE_DNS_API_TOKEN=${config.sops.placeholder."hosting/admin/cf_api_token"}
          ''
        ];
      };

      virtualisation.oci-containers.containers.traefik. environmentFiles = [config.sops.templates."docker_traefik.env".path];
    };
  }
