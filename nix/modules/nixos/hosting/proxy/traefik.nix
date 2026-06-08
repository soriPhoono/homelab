{
  lib,
  config,
  options,
  ...
}: let
  proxyCfg = config.hosting.proxy;
  dnsCfg = proxyCfg.dns;
  cfg = proxyCfg.traefik;

  rootDomain =
    if dnsCfg.localSubdomain != ""
    then "${dnsCfg.localSubdomain}.${dnsCfg.baseDomain}"
    else dnsCfg.baseDomain;

  inherit
    (lib)
    mkIf
    mkEnableOption
    mkOption
    mkMerge
    types
    optional
    optionals
    boolToString
    literalExpression
    flatten
    mapAttrsToList
    concatStringsSep
    ;
in {
  options.hosting.proxy.traefik = {
    enable = mkEnableOption "Enable Traefik reverse proxy via Docker";

    image = mkOption {
      type = types.str;
      default = "traefik:v3.7";
      description = "Traefik Docker image tag";
    };

    dashboard = {
      enable = mkEnableOption "the Traefik dashboard";
      domain = mkOption {
        type = types.str;
        default = "proxy.${rootDomain}";
        defaultText = literalExpression ''"proxy.&{rootDomain}"'';
        description = "Domain for the Traefik dashboard";
      };
    };

    acme = {
      enable =
        mkEnableOption "ACME (Let's Encrypt) certificate management"
        // {
          default = true;
        };
      email = mkOption {
        type = types.str;
        default = dnsCfg.email;
        defaultText = literalExpression "config.hosting.proxy.dns.email";
        description = "Email for Let's Encrypt certificate registration";
      };
      challenge = mkOption {
        type = types.enum [
          "dns"
          "http"
        ];
        default = "dns";
        description = ''
          ACME challenge type. Use 'dns' for wildcard certificates via
          Cloudflare DNS. Use 'http' for simpler setups with port 80 reachable.
        '';
      };
      storage = mkOption {
        type = types.str;
        default = "/letsencrypt/acme.json";
        description = "Path to ACME certificate storage file inside the container";
      };
      caServer = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          ACME CA server URL. Defaults to Let's Encrypt production.
          Use "https://acme-staging-v02.api.letsencrypt.org/directory" for testing.
        '';
      };
    };

    providers = {
      file = {
        enable =
          mkEnableOption "the Traefik file provider for dynamic configuration"
          // {
            default = true;
          };
        directory = mkOption {
          type = types.str;
          default = "/dynamic";
          description = "Directory inside the container for dynamic config files (YAML/TOML)";
        };
      };
    };

    configDir = mkOption {
      type = types.str;
      default = "/var/lib/traefik";
      description = "Host directory for Traefik configuration, certificates, and dynamic config";
    };

    logLevel = mkOption {
      type = types.enum [
        "DEBUG"
        "INFO"
        "WARN"
        "ERROR"
      ];
      default = "INFO";
      description = "Traefik log level";
    };

    accessLog =
      mkEnableOption "Traefik access logging"
      // {
        default = true;
      };

    entryPoints = mkOption {
      type = types.attrsOf (
        types.submodule {
          options = {
            address = mkOption {
              type = types.str;
              description = "Entrypoint address (e.g., ':8080')";
              example = ":8080";
            };
            description = mkOption {
              type = types.str;
              default = "";
              description = "Description for this entrypoint";
            };
            forwardedHeaders = mkOption {
              type = types.submodule {
                options = {
                  trustedIPs = mkOption {
                    type = types.listOf types.str;
                    default = [];
                    description = "Trusted IPs for forwarded headers (e.g., Cloudflare IP ranges)";
                  };
                };
              };
              default = {};
              description = "Forwarded headers configuration";
            };
            proxyProtocol = mkOption {
              type = types.nullOr (
                types.submodule {
                  options = {
                    trustedIPs = mkOption {
                      type = types.listOf types.str;
                      default = [];
                      description = "Trusted IPs for proxy protocol";
                    };
                  };
                }
              );
              default = null;
              description = "Proxy protocol configuration";
            };
          };
        }
      );
      default = {};
      description = "Additional entry points beyond web (80) and websecure (443)";
    };

    extraLabels = mkOption {
      type = types.attrsOf types.str;
      default = {};
      description = "Additional Docker labels for the Traefik container";
    };

    extraArgs = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Additional CLI arguments passed directly to the Traefik binary";
    };

    extraVolumes = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Additional volume mounts for the container";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    # ── Base container configuration ──────────────────────────
    {
      systemd.tmpfiles.rules =
        [
          "d ${cfg.configDir} 0755 root root -"
        ]
        ++ optional cfg.providers.file.enable "d ${cfg.configDir}/dynamic 0755 root root -";

      virtualisation.oci-containers.containers.traefik = {
        inherit (cfg) image;
        autoStart = true;
        networks = ["proxy"];

        ports = [
          "80:80"
          "443:443"
        ];

        volumes =
          [
            # Docker socket for the Docker provider (auto-discovers containers)
            "/var/run/docker.sock:/var/run/docker.sock:ro"

            # Static config directory (for future traefik.yml additions)
            "${cfg.configDir}:/etc/traefik:rw"

            # ACME certificate storage
            "${cfg.configDir}/letsencrypt:/letsencrypt:rw"
          ]
          ++ optional cfg.providers.file.enable "${cfg.configDir}/dynamic:${cfg.providers.file.directory}:ro"
          ++ cfg.extraVolumes;

        # Traefik's entrypoint is `traefik`; cmd is passed as CLI args
        cmd =
          [
            # ── EntryPoints ──────────────────────────────────────
            "--entrypoints.web.address=:80"
            "--entrypoints.web.http.redirections.entrypoint.to=websecure"
            "--entrypoints.web.http.redirections.entrypoint.scheme=https"
            "--entrypoints.web.http.redirections.entrypoint.permanent=true"
            "--entrypoints.websecure.address=:443"

            # ── ACME / Let's Encrypt ─────────────────────────────
            "--entrypoints.websecure.http.tls.certresolver=le"
            "--certificatesresolvers.le.acme.email=${cfg.acme.email}"
            "--certificatesresolvers.le.acme.storage=${cfg.acme.storage}"
          ]
          ++ optionals cfg.acme.enable (
            if cfg.acme.challenge == "dns"
            then [
              "--certificatesresolvers.le.acme.dnschallenge.provider=cloudflare"
            ]
            else [
              "--certificatesresolvers.le.acme.httpchallenge.entrypoint=web"
            ]
          )
          ++ optional (
            cfg.acme.caServer != null
          ) "--certificatesresolvers.le.acme.caServer=${cfg.acme.caServer}"
          ++ [
            # ── Docker Provider ──────────────────────────────────
            "--providers.docker=true"
            "--providers.docker.exposedbydefault=false"
            "--providers.docker.network=proxy"
          ]
          ++ optional cfg.providers.file.enable "--providers.file.directory=${cfg.providers.file.directory}"
          ++ optional cfg.providers.file.enable "--providers.file.watch=true"
          ++ [
            # ── Dashboard / API ──────────────────────────────────
            "--api.dashboard=${boolToString cfg.dashboard.enable}"

            # ── Logging ──────────────────────────────────────────
            "--log.level=${cfg.logLevel}"
          ]
          ++ optional cfg.accessLog "--accesslog=true"
          ++ (
            # ── Additional EntryPoints ───────────────────────────
            flatten (
              mapAttrsToList (
                name: ep:
                  [
                    "--entrypoints.${name}.address=${ep.address}"
                  ]
                  ++ optional (ep.description != "") "--entrypoints.${name}.description=${ep.description}"
                  ++ optionals (ep.forwardedHeaders.trustedIPs != []) [
                    "--entrypoints.${name}.forwardedHeaders.trustedIPs=${concatStringsSep "," ep.forwardedHeaders.trustedIPs}"
                  ]
                  ++ optionals (ep.proxyProtocol != null && ep.proxyProtocol.trustedIPs != []) [
                    "--entrypoints.${name}.proxyProtocol.trustedIPs=${concatStringsSep "," ep.proxyProtocol.trustedIPs}"
                  ]
              )
              cfg.entryPoints
            )
          )
          ++ cfg.extraArgs;

        # Docker labels for the Traefik container itself
        labels =
          mkMerge [
            (mkIf cfg.dashboard.enable {
              "traefik.enable" = "true";
              "traefik.http.routers.dashboard.rule" = "Host(`${cfg.dashboard.domain}`)";
              "traefik.http.routers.dashboard.entrypoints" = "websecure";
              "traefik.http.routers.dashboard.service" = "api@internal";
              "traefik.http.routers.dashboard.tls" = "true";
              "traefik.http.routers.dashboard.tls.certresolver" = "le";
            })
          ]
          // cfg.extraLabels;
      };
    }

    # ── Cloudflare DNS API token via sops ──────────────────
    (
      mkIf
      (
        options ? sops && dnsCfg.provider == "cloudflare" && cfg.acme.enable && cfg.acme.challenge == "dns"
      )
      {
        sops.secrets."api/cloudflare-${dnsCfg.baseDomain}-token" = {};

        sops.templates."hosting/traefik-${dnsCfg.baseDomain}.env" = {
          owner = "root";
          group = "root";
          mode = "0400";
          content = ''
            CF_DNS_API_TOKEN=${config.sops.placeholder."api/cloudflare-${dnsCfg.baseDomain}-token"}
          '';
        };

        virtualisation.oci-containers.containers.traefik.environmentFiles = [
          config.sops.templates."hosting/traefik-${dnsCfg.baseDomain}.env".path
        ];
      }
    )
  ]);
}
