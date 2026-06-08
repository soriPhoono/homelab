{
  lib,
  pkgs,
  config,
  options,
  ...
}: let
  uids = import ../uids.nix;
  cfg = config.hosting.ai.n8n;

  # Generate the task runners launcher configuration JSON
  launcherConfig = pkgs.writeText "n8n-task-runners.json" (
    builtins.toJSON {
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
    }
  );

  # Common environment shared between main n8n and workers
  commonEnv =
    {
      TZ = config.time.timeZone;
      GENERIC_TIMEZONE = config.time.timeZone;
      N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS = "true";
      NODE_ENV = "production";
    }
    // lib.optionalAttrs cfg.workers.enable {
      EXECUTIONS_MODE = "queue";
      QUEUE_BULL_REDIS_HOST = "n8n-redis";
      QUEUE_BULL_REDIS_PORT = toString cfg.redis.port;
      QUEUE_BULL_REDIS_DB = "0";
    }
    // cfg.environment;

  # Common volumes shared between main n8n and workers
  commonVolumes = [
    "${cfg.configDir}/data:/home/node/.n8n"
  ];

  authFile = config.sops.templates."n8n-auth.env".path;

  # Common environment files shared between main n8n and workers
  commonEnvFiles = lib.optionals (cfg.runners.enable && options ? sops) [
    authFile
  ];
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
          Additional volume mounts for all n8n containers (main + workers).
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
          Environment variables passed to the main n8n container and all
          worker containers. Use for secrets that need to be shared across
          instances, such as N8N_ENCRYPTION_KEY and
          N8N_USER_MANAGEMENT_JWT_SECRET.
        '';
      };

      # ── Tier 1: Redis queue backend ───────────────────────────
      redis = {
        enable = mkEnableOption "Redis queue backend for n8n workers (required for queue mode)";

        port = mkOption {
          type = types.port;
          default = 6379;
          description = "Redis port";
        };

        image = mkOption {
          type = types.str;
          default = "redis:7-alpine";
          description = "Docker image for Redis";
        };
      };

      # ── Tier 2: Workers ───────────────────────────────────────
      workers = {
        enable = mkEnableOption "n8n worker instances for parallel workflow execution via Redis queue";

        count = mkOption {
          type = types.int;
          default = 1;
          description = "Number of n8n worker replicas to run";
        };
      };

      # ── Tier 3: Code runners ──────────────────────────────────
      runners = {
        enable = mkEnableOption "n8n task runners for isolated code execution (JavaScript + Python)";

        image = mkOption {
          type = types.str;
          default = "n8nio/runners";
          defaultText = literalExpression ''"n8nio/runners"'';
          description = ''
            Docker image for n8n task runners. Must match the main n8n image tag.
            Defaults to n8nio/runners from Docker Hub. Note that this image is
            NOT available on the docker.n8n.io registry (only on Docker Hub and GHCR).
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
              example = [
                "moment"
                "uuid"
              ];
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
              example = [
                "json"
                "math"
                "os"
              ];
              description = ''
                Python standard library modules to allowlist for Python code execution.
                Set to ["*"] to allow all stdlib modules.
              '';
            };
            externalAllow = mkOption {
              type = types.listOf types.str;
              default = [];
              example = [
                "numpy"
                "pandas"
              ];
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
      # ═══════════════════════════════════════════════════════════
      # Tier 1: Main n8n server (web UI + trigger orchestrator)
      # ═══════════════════════════════════════════════════════════
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
          networks = [
            "proxy"
            "n8n"
          ];

          volumes = commonVolumes ++ cfg.extraVolumes;

          environment =
            commonEnv
            // {
              N8N_PORT = toString cfg.port;
              N8N_PROTOCOL = "https";
              N8N_HOST = cfg.domain;
              WEBHOOK_URL = "https://${cfg.domain}/";
            }
            // optionalAttrs cfg.runners.enable {
              N8N_RUNNERS_ENABLED = "true";
              N8N_RUNNERS_MODE = "external";
              N8N_RUNNERS_BROKER_LISTEN_ADDRESS = "0.0.0.0";
              N8N_NATIVE_PYTHON_RUNNER = boolToString cfg.runners.launcherConfig.python.enable;
            };

          environmentFiles = commonEnvFiles;

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

      # ═══════════════════════════════════════════════════════════
      # Tier 2: Redis queue backend
      # ═══════════════════════════════════════════════════════════
      (mkIf cfg.redis.enable {
        virtualisation.oci-containers.containers.n8n-redis = {
          image = cfg.redis.image;
          autoStart = true;
          networks = ["n8n"];

          cmd = [
            "redis-server"
            "--port"
            (toString cfg.redis.port)
            "--save"
            "60"
            "1000"
            "--appendonly"
            "yes"
          ];

          volumes = [
            "${cfg.configDir}/redis:/data"
          ];
        };
      })

      # ═══════════════════════════════════════════════════════════
      # Tier 3: Worker containers
      # ═══════════════════════════════════════════════════════════
      (mkIf cfg.workers.enable {
        assertions = [
          {
            assertion = cfg.redis.enable;
            message = "hosting.ai.n8n.redis.enable must be true when workers are enabled.";
          }
        ];

        virtualisation.oci-containers.containers = listToAttrs (
          flip map (genList (i: i) cfg.workers.count) (i: {
            name = "n8n-worker-${toString i}";
            value = {
              inherit (cfg) image;
              autoStart = true;
              networks = ["n8n"];

              cmd = ["worker"];

              volumes = commonVolumes ++ cfg.extraVolumes;

              environment = commonEnv;

              environmentFiles = commonEnvFiles;
            };
          })
        );
      })

      # ═══════════════════════════════════════════════════════════
      # Tier 4: Code execution runners
      # ═══════════════════════════════════════════════════════════
      (mkIf cfg.runners.enable {
        assertions = [
          {
            assertion = options ? sops;
            message = ''
              hosting.ai.n8n.runners.enable requires the sops dependency to be enabled for this module
            '';
          }
        ];

        virtualisation.oci-containers.containers.n8n-runners = {
          image = cfg.runners.image;
          autoStart = true;
          networks = ["n8n"];

          environment = {
            N8N_RUNNERS_TASK_BROKER_URI = "http://n8n:5679";
            N8N_RUNNERS_LAUNCHER_LOG_LEVEL = "info";
          };

          environmentFiles = commonEnvFiles;

          volumes = [
            "${launcherConfig}:/etc/n8n-task-runners.json:ro"
          ];
        };
      })

      (mkIf (cfg.runners.enable && options ? sops) {
        # n8n secrets declared via sops
        sops = {
          secrets = {
            "hosting/ai/n8n_runners-token" = {};
            "hosting/ai/n8n_encryption-key" = {};
            "hosting/ai/n8n_jwt-secret" = {};
          };

          templates = {
            "n8n-auth.env" = {
              content = ''
                N8N_RUNNERS_AUTH_TOKEN=${config.sops.placeholder."hosting/ai/n8n_runners-token"}
                N8N_ENCRYPTION_KEY=${config.sops.placeholder."hosting/ai/n8n_encryption-key"}
                N8N_USER_MANAGEMENT_JWT_SECRET=${config.sops.placeholder."hosting/ai/n8n_jwt-secret"}
              '';
            };
          };
        };
      })
    ]);
  }
