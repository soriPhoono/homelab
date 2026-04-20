{
  lib,
  pkgs,
  options,
  config,
  ...
}: let
  proxyConfig = config.hosting.proxy;
  dnsConfig = proxyConfig.dns;
  cfg = proxyConfig.caddy;
  # Custom caddy with cloudflare DNS plugin
  # Note: Standard nixpkgs caddy doesn't have withPlugins in a simple way
  # unless using an overlay. We'll use a more standard buildGoModule approach
  # if needed, but first let's try the common 'caddy.withPlugins' pattern
  # assuming it's available or we provide it.
  # For now, I'll use a generic placeholder or the buildGoModule if I'm not sure.
  # Actually, soriPhoono/homelab might have specific needs.
in
  with lib; {
    options.hosting.proxy.caddy = {
      enable = mkEnableOption "Enable Caddy reverse proxy with Cloudflare DNS";
    };

    config = mkIf cfg.enable (mkMerge [
      {
        services.caddy = {
          inherit (dnsConfig) email;

          enable = true;
          # We assume the user or an overlay provides a caddy with the cloudflare plugin
          # Or we can build it here. Building it here is safer for a drop-in module.
          package = pkgs.caddy.withPlugins {
            plugins = ["github.com/caddy-dns/cloudflare@v0.2.4"];
            hash = "sha256-Olz4W84Kiyldy+JtbIicVCL7dAYl4zq+2rxEOUTObxA=";
          };

          virtualHosts = mapAttrs' (name: service: let
            subdomain =
              if dnsConfig.localSubdomain != ""
              then "${dnsConfig.localSubdomain}."
              else "";
            fullHost = "${name}.${subdomain}${dnsConfig.baseDomain}";
          in
            nameValuePair fullHost {
              extraConfig = ''
                bind 127.0.0.1 ::1

                tls {
                  ${optionalString (dnsConfig.provider == "cloudflare") "dns cloudflare {env.CLOUDFLARE_API_TOKEN}"}
                }

                ${concatStringsSep "\n" (mapAttrsToList (path: target: ''
                    handle ${path}* {
                      reverse_proxy 127.0.0.1:${toString target}
                    }
                  '')
                  service.extraPaths)}

                reverse_proxy 127.0.0.1:${toString service.proxyPort}
              '';
            })
          proxyConfig.services;
        };
      }
      (mkIf (options ? sops && dnsConfig.provider == "cloudflare") {
        sops = {
          secrets."api/cloudflare-${dnsConfig.baseDomain}-token" = {};
          templates."hosting/caddy-${dnsConfig.baseDomain}.env" = {
            inherit (config.services.caddy) group;

            owner = config.services.caddy.user;

            content = ''
              CLOUDFLARE_API_TOKEN="${config.sops.placeholder."api/cloudflare-${dnsConfig.baseDomain}-token"}"
            '';
          };
        };

        services.caddy.environmentFile = config.sops.templates."hosting/caddy-${dnsConfig.baseDomain}.env".path;
      })
    ]);
  }
