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
  rootLocalDomain =
    if dnsConfig.localSubdomain != ""
    then "${dnsConfig.localSubdomain}.${dnsConfig.baseDomain}"
    else dnsConfig.baseDomain;
  wildcardDomain =
    if dnsConfig.localSubdomain != ""
    then "*.${dnsConfig.localSubdomain}.${dnsConfig.baseDomain}"
    else "*.${dnsConfig.baseDomain}";
  defaultService = proxyConfig.services.default or null;
  nonDefaultServices = lib.filterAttrs (name: _: name != "default") proxyConfig.services;
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
            hash = "sha256-bzMqxWTqrJ1skZmRTXyEMCKStXpljbqe5r0Ve2cnBfM=";
          };

          extraConfig = ''
            (wildcard_tls) {
              tls {
                ${optionalString (dnsConfig.provider == "cloudflare") ''
              issuer acme {
                dns cloudflare {env.CLOUDFLARE_API_TOKEN}
                resolvers 1.1.1.1 1.0.0.1
                propagation_delay 30s
                propagation_timeout 5m
              }
            ''}
              }
            }

            ${rootLocalDomain}, ${wildcardDomain} {
              bind 127.0.0.1 ::1

              import wildcard_tls

              ${optionalString (defaultService != null) ''
              @root host ${rootLocalDomain}
              handle @root {
                reverse_proxy 127.0.0.1:${toString defaultService.proxyPort}
              }

            ''}
              abort
            }
          '';

          virtualHosts =
            mapAttrs' (
              name: service: let
                subdomain =
                  if dnsConfig.localSubdomain != ""
                  then "${dnsConfig.localSubdomain}."
                  else "";
                fullHost = "${name}.${subdomain}${dnsConfig.baseDomain}";
              in
                nameValuePair fullHost {
                  extraConfig = ''
                    bind 127.0.0.1 ::1

                    ${concatStringsSep "\n" (
                      mapAttrsToList (
                        path: target: let
                          proxyBlock = ''
                            reverse_proxy 127.0.0.1:${toString target.proxyPort} ${
                              optionalString (target.extraConfig != null) ''
                                {
                                  ${target.extraConfig}
                                }
                              ''
                            }
                          '';
                        in
                          if target.handlePath
                          then ''
                            handle_path ${path}* {
                              ${proxyBlock}
                            }
                          ''
                          else ''
                            handle ${path}* {
                              ${proxyBlock}
                            }
                          ''
                      )
                      service.extraPaths
                    )}

                    reverse_proxy 127.0.0.1:${toString service.proxyPort} ${
                      optionalString (service.extraConfig != null) ''
                        {
                          ${service.extraConfig}
                        }
                      ''
                    }
                  '';
                }
            )
            nonDefaultServices;
        };
      }
      (mkIf (options ? sops && dnsConfig.provider == "cloudflare") {
        sops = {
          secrets."api/cloudflare-${dnsConfig.baseDomain}-token" = {};
          templates."hosting/caddy-${dnsConfig.baseDomain}.env" = {
            inherit (config.services.caddy) group;

            owner = config.services.caddy.user;
            mode = "0400";

            content = ''
              CLOUDFLARE_API_TOKEN="${config.sops.placeholder."api/cloudflare-${dnsConfig.baseDomain}-token"}"
            '';
          };
        };

        services.caddy.environmentFile =
          config.sops.templates."hosting/caddy-${dnsConfig.baseDomain}.env".path;
      })
    ]);
  }
