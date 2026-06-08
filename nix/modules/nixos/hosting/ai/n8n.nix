{
  lib,
  pkgs,
  config,
  ...
}: let
  uids = import ../uids.nix;
  cfg = config.hosting.ai.n8n;

  # Generate the task runners launcher configuration JSON
  launcherConfig = pkgs.writeText "n8n-task-runners.json" (builtins.toJSON {
    "task-runners" =
      [
        {
          "runner-type" = "javascript";
          "env-overrides" =
            {}
            // lib.optionalAttrs (cfg.runners.launcherConfig.javascript.allowBuiltin != []) {
              NODE_FUNCTION_ALLOW_BUILTIN = lib.concatStringsSep "," cfg.runners.launcherConfig.javascript.allowBuiltin;
            }
            // lib.optionalAttrs (cfg.runners.launcherConfig.javascript.allowExternal != []) {
              NODE_FUNCTION_ALLOW_EXTERNAL = lib.concatStringsSep "," cfg.runners.launcherConfig.javascript.allowExternal;
            };
        }
      ]
      ++ lib.optionals cfg.runners.launcherConfig.python.enable [
        {
          "runner-type" = "python";
          "env-overrides" =
            {
              PYTHONPATH = "/opt/runners/task-runner-python";
            }
            // lib.optionalAttrs (cfg.runners.launcherConfig.python.stdlibAllow != []) {
              N8N_RUNNERS_STDLIB_ALLOW = lib.concatStringsSep "," cfg.runners.launcherConfig.python.stdlibAllow;
            }
            // lib.optionalAttrs (cfg.runners.launcherConfig.python.externalAllow != []) {
              N8N_RUNNERS_EXTERNAL_ALLOW = lib.concatStringsSep "," cfg.runners.launcherConfig.python.externalAllow;
            };
        }
      ];
  });
in
  with lib; {
    options.hosting.ai.n8n = {
      enable = mkEnableOption "n8n workflow automation with AI/LLM capabilities";

      port = mkOption {
        type = types.port;
        default = 5678;
        description = "Port for the n8n web interface";
      };

      image = mkOption {
        type = types.str;
        default = "docker.n8n.io/n8nio/n8n";
        description = ''
          Docker image for n8n.
          Uses the official image from Docker Hub.
        '';
      };

      configDir = mkOption {
        type = types.str;
        default = "/var/lib/n8n";
        description = "Host directory for n8n configuration and data";
      };

      domain = mkOption {
        type = types.str;
        default = "ai.${config.hosting.proxy.dns.localSubdomain}.${config.hosting.proxy.dns.baseDomain}";
        defaultText = literalExpression ''"ai.&{localSubdomain}.&{baseDomain}"'';
        description = ''
          The external domain for the n8n web interface (used for Traefik routing).
        '';
      };

      userUid = mkOption {
        type = types.int;
        default = uids.ai.n8n.uid;
        description = "UID for the n8n container process";
      };

      userGid = mkOption {
        type = types.int;
        default = uids.ai.n8n.gid;
        description = "GID for the n8n container process";
      };

      extraVolumes = mkOption {
        type = types.listOf types.str;
        default = [];
        description = ''
          Additional volume mounts for the main container.
          Each entry should be in Docker volume format: "/host/path:/container/path[:mode]"
        '';
      };

      extraLabels = mkOption {
        type = types.attrsOf types.str;
        default = {};
        description = "Additional Docker labels for the main container (e.g., Traefik middleware).";
      };

      extraOptions = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "Extra Docker options passed directly to the main container runtime.";
      };

      environment = mkOption {
        type = types.attrsOf types.str;
        default = {};
        example = {
          N8N_ENCRYPTION_KEY = "your-encryption-key";
          N8N_USER_MANAGEMENT_JWT_SECRET = "your-jwt-secret";
        };
        description = ''
          Additional environment variables passed to the n8n container.
          Useful for setting secrets like N8N_ENCRYPTION_KEY and
          N8N_USER_MANAGEMENT_JWT_SECRET.
        '';
      };

      runners = {
        enable = mkEnableOption "n8n task runners for isolated code execution (JavaScript + Python)";

        image = mkOption {
          type = types.str;
          default = lib.replaceStrings ["n8nio/n8n"] ["n8nio/runners"] cfg.image;
          defaultText = literalExpression ''
            lib.replaceStrings ["n8nio/n8n"] ["n8nio/runners"] config.hosting.ai.n8n.image
          '';
          description = ''
            Docker image for n8n task runners. Must match the main n8n image tag.
            Defaults to n8nio/runners with the same tag as the main image.
          '';
        };

        authTokenFile = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = ''
            Path to a file containing N8N_RUNNERS_AUTH_TOKEN=... for runner authentication.
            This shared secret is mounted into both the main n8n container and runners.
            Use with sops.templates for secure secret management.

            Example with sops:
              sops.secrets."ai/n8n-runners-token" = { };
              sops.templates."n8n-runners.env" = {
                content = "N8N_RUNNERS_AUTH_TOKEN=my-secret-token";
              };
              hosting.ai.n8n.runners.authTokenFile = config.sops.templates."n8n-runners.env".path;
          '';
        };

        launcherConfig = {
          javascript = {
            allowBuiltin = mkOption {
              type = types.listOf types.str;
              default = [];
              example = ["crypto"];
              description = ''
                Node.js builtin modules to allowlist for JavaScript code execution.
                Set to ["*"] to allow all builtins.
              '';
            };
            allowExternal = mkOption {
              type = types.listOf types.str;
              default = [];
              example = ["moment" "uuid"];
              description = ''
                Third-party npm packages to allowlist for JavaScript code execution.
                These must be pre-installed in the runners image.
              '';
            };
          };

          python = {
            enable = mkEnableOption "Python code execution in n8n Code nodes";

            stdlibAllow = mkOption {
              type = types.listOf types.str;
              default = [];
              example = ["json" "math" "os"];
              description = ''
                Python standard library modules to allowlist for Python code execution.
                Set to ["*"] to allow all stdlib modules.
              '';
            };
            externalAllow = mkOption {
              type = types.listOf types.str;
              default = [];
              example = ["numpy" "pandas"];
              description = ''
                Third-party Python packages to allowlist for Python code execution.
                These must be pre-installed in the runners image.
              '';
            };
          };
        };
      };
    };

    config = mkIf cfg.enable (mkMerge [
      # ── Base n8n container ──────────────────────────────────
      {
        users = {
          users.n8n = {
            isSystemUser = true;
            uid = mkDefault cfg.userUid;
            group = config.users.groups.n8n.name;
          };
          groups.n8n = {
            gid = mkDefault cfg.userGid;
          };
        };

        hosting.platforms.docker.enable = mkDefault true;

        systemd.tmpfiles.rules = [
          "d ${cfg.configDir} 0755 ${toString cfg.userUid} ${toString cfg.userGid} -"
          "d ${cfg.configDir}/data 0755 ${toString cfg.userUid} ${toString cfg.userGid} -"
        ];

        virtualisation.oci-containers.containers.n8n = {
          inherit (cfg) image;
          autoStart = true;
          networks = ["proxy"];

          volumes =
            [
              "${cfg.configDir}/data:/home/node/.n8n"
            ]
            ++ cfg.extraVolumes;

          environment =
            {
              TZ = config.time.timeZone;
              GENERIC_TIMEZONE = config.time.timeZone;
              N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS = "true";
              N8N_PORT = toString cfg.port;
              N8N_PROTOCOL = "https";
              N8N_HOST = cfg.domain;
              WEBHOOK_URL = "https://${cfg.domain}/";
              NODE_ENV = "production";
            }
            // optionalAttrs cfg.runners.enable {
              N8N_RUNNERS_ENABLED = "true";
              N8N_RUNNERS_MODE = "external";
              N8N_RUNNERS_BROKER_LISTEN_ADDRESS = "0.0.0.0";
              N8N_NATIVE_PYTHON_RUNNER = boolToString cfg.runners.launcherConfig.python.enable;
            }
            // cfg.environment;

          environmentFiles = optionals (cfg.runners.enable && cfg.runners.authTokenFile != null) [
            cfg.runners.authTokenFile
          ];

          labels =
            {
              "traefik.enable" = "true";
              "traefik.http.routers.n8n.rule" = "Host(`${cfg.domain}`)";
              "traefik.http.routers.n8n.entrypoints" = "websecure";
              "traefik.http.routers.n8n.tls" = "true";
              "traefik.http.routers.n8n.tls.certresolver" = "le";
              "traefik.http.services.n8n.loadbalancer.server.port" = toString cfg.port;
            }
            // cfg.extraLabels;

          inherit (cfg) extraOptions;
        };
      }

      # ── Task runners container ─────────────────────────────
      (mkIf cfg.runners.enable {
        assertions = [
          {
            assertion = cfg.runners.authTokenFile != null;
            message = ''
              hosting.ai.n8n.runners.authTokenFile must be set when runners are enabled.
              Use sops.templates to create an env file containing N8N_RUNNERS_AUTH_TOKEN.
              See the option description for an example.
            '';
          }
        ];

        virtualisation.oci-containers.containers.n8n-runners = {
          image = cfg.runners.image;
          autoStart = true;
          networks = ["proxy"];

          environment = {
            N8N_RUNNERS_TASK_BROKER_URI = "http://n8n:5679";
            N8N_RUNNERS_LAUNCHER_LOG_LEVEL = "info";
          };

          environmentFiles = optionals (cfg.runners.authTokenFile != null) [
            cfg.runners.authTokenFile
          ];

          volumes = [
            "${launcherConfig}:/etc/n8n-task-runners.json:ro"
          ];
        };
      })
    ]);
  }
