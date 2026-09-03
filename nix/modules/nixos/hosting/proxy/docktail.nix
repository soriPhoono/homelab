{
  lib,
  config,
  options,
  pkgs,
  ...
}: let
  inherit (lib.homelab.containers) mkContainer mkContainerOption mkDockerImage;

  proxyCfg = config.hosting.proxy;
  cfg = proxyCfg.docktail;
  caddyCfg = proxyCfg.caddy;
  autheliaCfg = proxyCfg.authelia;

  name = "docktail";
  caddyName = "caddy";
  autheliaName = "authelia";
  hostname = config.networking.hostName;
  autheliaHostname = "${hostname}-auth.xerus-augmented.ts.net";

  dockerSocket =
    if config.virtualisation.oci-containers.backend == "podman"
    then "/run/podman/podman.sock"
    else "/var/run/docker.sock";

  autheliaRoute = {
    name = "${hostname}-auth";
    host = autheliaHostname;
    port = 9091;
    policy = "bypass";
  };

  caddyWithPlugins = pkgs.caddy.withPlugins {
    plugins = [
      "github.com/lucaslorentz/caddy-docker-proxy/v2@v2.10.0"
    ];
    hash = "sha256-I8XozRMSzpHREhJ6YbSnJDUCx41cUe4ehQPQyyIz4aQ=";
  };

  caddyImage = mkDockerImage {
    name = "homelab-caddy";
    inherit pkgs;
    package = caddyWithPlugins;
    config = {
      Cmd = [
        "/bin/caddy"
        "docker-proxy"
      ];
      ExposedPorts = {
        "80/tcp" = {};
      };
    };
  };

  routes =
    caddyCfg.routes
    // lib.optionalAttrs autheliaCfg.enable {
      ${autheliaName} = autheliaRoute;
    };

  docktailLabels =
    lib.foldl'
    (labels: indexedRoute: let
      inherit (indexedRoute) index;
      inherit (indexedRoute) route;
      serviceIndex = index * 2;
      prefix =
        if serviceIndex == 0
        then "docktail.service"
        else "docktail.service.${toString serviceIndex}";
      httpsPrefix = "docktail.service.${toString (serviceIndex + 1)}";
    in
      labels
      // {
        "${prefix}.enable" = "true";
        "${prefix}.name" = route.name;
        "${prefix}.network" = "tailscale";
        "${prefix}.port" = "80";
        "${prefix}.protocol" = "http";
        "${prefix}.service-port" = "80";
        "${prefix}.service-protocol" = "http";
        "${httpsPrefix}.enable" = "true";
        "${httpsPrefix}.name" = route.name;
        "${httpsPrefix}.network" = "tailscale";
        "${httpsPrefix}.port" = "80";
        "${httpsPrefix}.protocol" = "http";
        "${httpsPrefix}.service-port" = "443";
        "${httpsPrefix}.service-protocol" = "https";
      })
    {}
    (lib.imap0 (index: route: {inherit index route;}) (lib.attrValues routes));

  autheliaRules = lib.concatMapStrings (route: "    - domain: ${route.host}\n      policy: ${route.policy}\n") (lib.attrValues routes);

  caddyConfiguration = pkgs.writeText "caddy-Caddyfile" ''
    {
      auto_https off
    }

    (authelia-auth) {
      forward_auth authelia:9091 {
        uri /api/authz/forward-auth
        header_up X-Forwarded-Proto https
        copy_headers Remote-User Remote-Groups Remote-Name Remote-Email
      }
    }
  '';
in
  with lib; {
    options.hosting.proxy.${name} = mkContainerOption {
      inherit name;
      description = "Docktail, used for reverse proxying over tailscale.";
    };

    options.hosting.proxy.authelia = {
      enable = mkEnableOption "Enable Authelia authentication for hosted services";
    };

    options.hosting.proxy.caddy = {
      enable = mkEnableOption "Enable the Caddy authentication gateway";

      routes = mkOption {
        type = types.attrsOf (types.submodule {
          options = {
            name = mkOption {
              type = types.str;
              description = "Tailscale service name published by Docktail.";
            };

            host = mkOption {
              type = types.str;
              description = "Hostname used by Caddy and Authelia for this route.";
            };

            port = mkOption {
              type = types.port;
              description = "Backend container port discovered by Caddy.";
            };

            policy = mkOption {
              type = types.enum ["bypass" "one_factor" "two_factor"];
              default = "one_factor";
              description = "Authelia access policy for this route.";
            };
          };
        });
        default = {};
        description = "Caddy routes published through the authenticated gateway.";
      };
    };

    config = mkIf cfg.enable (mkMerge [
      {
        hosting.enable = true;

        assertions = [
          {
            message = "Docktail requires Tailscale to be enabled.";
            assertion = config.services.tailscale.enable;
          }
          {
            message = "Caddy requires Authelia to be enabled.";
            assertion = !caddyCfg.enable || autheliaCfg.enable;
          }
          {
            message = "Authelia requires the sops module.";
            assertion = !autheliaCfg.enable || options ? sops;
          }
        ];

        sops = mkIf (options ? sops) {
          secrets = {
            "api/tailscale-sidecar-authkey" = {};
            "api/tailscale-oauth-client-id" = {};
            "api/tailscale-oauth-client-secret" = {};
            "api/authelia-jwt-secret" = {};
            "api/authelia-session-secret" = {};
            "api/authelia-storage-encryption-key" = {};
            "api/authelia-users" = {};
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
            "authelia/configuration.yml" = {
              content = ''
                theme: dark

                server:
                  address: tcp://0.0.0.0:9091
                  endpoints:
                    authz:
                      forward-auth:
                        implementation: ForwardAuth

                log:
                  level: info

                identity_validation:
                  reset_password:
                    jwt_secret: ${config.sops.placeholder."api/authelia-jwt-secret"}

                authentication_backend:
                  file:
                    path: /config/users_database.yml

                access_control:
                  default_policy: deny
                  rules:
                ${autheliaRules}

                session:
                  secret: ${config.sops.placeholder."api/authelia-session-secret"}
                  cookies:
                    - name: authelia_session
                      domain: xerus-augmented.ts.net
                      authelia_url: https://${autheliaHostname}
                      default_redirection_url: https://${hostname}-homepage.xerus-augmented.ts.net

                storage:
                  encryption_key: ${config.sops.placeholder."api/authelia-storage-encryption-key"}
                  local:
                    path: /var/lib/authelia/db.sqlite3

                notifier:
                  filesystem:
                    filename: /var/lib/authelia/notifications.txt

                ntp:
                  address: udp://time.cloudflare.com:123
              '';
            };
          };
        };

        services.chrony = mkIf autheliaCfg.enable {
          enable = true;
          servers = ["time.cloudflare.com"];
        };

        systemd.services.docker-authelia = mkIf autheliaCfg.enable {
          after = ["chronyd.service"];
          requires = ["chronyd.service"];
          preStart = ''
            ${pkgs.chrony}/bin/chronyc waitsync 0 0.1 0 1
          '';
        };

        hosting.proxy.caddy.routes = mkIf autheliaCfg.enable {
          ${autheliaName} = autheliaRoute;
        };

        virtualisation.oci-containers.containers = {
          ${autheliaName} = mkIf autheliaCfg.enable (mkMerge [
            (mkContainer {
              name = autheliaName;
              inherit config;
              cfg = {container.publication = ["caddy"];};
              image = "authelia/authelia:4.39.20";
              caddy = autheliaRoute;
            })
            {
              networks = ["caddy"];
              volumes = [
                "authelia-data:/var/lib/authelia"
                "${config.sops.secrets."api/authelia-users".path}:/config/users_database.yml:ro"
                "${config.sops.templates."authelia/configuration.yml".path}:/config/configuration.yml:ro"
              ];
            }
          ]);

          ${caddyName} = mkIf caddyCfg.enable (mkMerge [
            (mkContainer {
              name = caddyName;
              inherit config;
              cfg = {container.publication = [];};
              image = "${caddyImage.imageName}:${caddyImage.imageTag}";
            })
            {
              imageFile = caddyImage;
              pull = "never";
              dependsOn = optional autheliaCfg.enable autheliaName;
              networks = [
                "tailscale"
                "caddy"
              ];
              environment = {
                CADDY_DOCKER_CADDYFILE_PATH = "/etc/caddy/Caddyfile";
                CADDY_DOCKER_PROXY_CONTAINER = caddyName;
              };
              labels = docktailLabels;
              volumes = [
                "${dockerSocket}:/var/run/docker.sock:ro"
                "caddy-data:/data"
                "caddy-config:/config"
                "${caddyConfiguration}:/etc/caddy/Caddyfile:ro"
              ];
            }
          ]);

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
