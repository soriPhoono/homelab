{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.hosting.platforms.swarm;
  yamlFormat = pkgs.formats.yaml {};

  # ────────────────────────────────────────────────────────────────────────────
  # Bootstrap stack generation
  # ────────────────────────────────────────────────────────────────────────────
  # composeYaml is the docker-compose file deployed to the swarm after init.
  # It defines the swarm-cd management container plus optional infra services
  # (traefik) that form the cluster's control plane.
  # ────────────────────────────────────────────────────────────────────────────

  reposYaml = yamlFormat.generate "repos.yaml" {
    "${cfg.cluster.swarmCd.repoName}" = {
      url = cfg.cluster.swarmCd.repoUrl;
    };
  };

  stacksYaml = yamlFormat.generate "stacks.yaml" (
    lib.listToAttrs (map (stack: {
        inherit (stack) name;
        value = {
          repo = cfg.cluster.swarmCd.repoName;
          branch = cfg.cluster.swarmCd.branch;
          compose_file = stack.composeFile;
          sops_files = stack.sopsFiles;
        };
      })
      cfg.cluster.swarmCd.stacks)
  );

  swarmCdAgeKeyPath =
    lib.optionalString (cfg.cluster.swarmCd.ageKeySopsPath != null)
    "/run/secrets/swarm/${cfg.cluster.name}/${cfg.cluster.swarmCd.ageKeySopsPath}";

  bootstrapServices =
    {}
    // {
      swarm-cd = {
        image = cfg.cluster.swarmCd.image;
        hostname = "swarm-cd";
        environment =
          {
            TZ = config.core.timeZone or "UTC";
          }
          // lib.optionalAttrs (swarmCdAgeKeyPath != "") {
            SOPS_AGE_KEY_FILE = "/secrets/age.key";
          }
          // cfg.cluster.extraEnv;
        volumes =
          [
            "/var/run/docker.sock:/var/run/docker.sock:ro"
          ]
          ++ lib.optional (swarmCdAgeKeyPath != "")
          "${swarmCdAgeKeyPath}:/secrets/age.key:ro";
        configs = [
          {
            source = "repos";
            target = "/app/repos.yaml";
          }
          {
            source = "stacks";
            target = "/app/stacks.yaml";
          }
        ];
        deploy = {
          mode = "replicated";
          replicas = 1;
          placement = {
            constraints = ["node.role == manager"];
          };
        };
        networks =
          lib.optional cfg.cluster.traefik.enable cfg.cluster.traefik.network;
      };
    }
    // lib.optionalAttrs cfg.cluster.traefik.enable {
      traefik = {
        image = "traefik:v3.3";
        command =
          [
            "--providers.docker=true"
            "--providers.docker.swarmMode=true"
            "--providers.docker.exposedByDefault=false"
            "--providers.docker.network=${cfg.cluster.traefik.network}"
            "--entrypoints.web.address=:80"
            "--entrypoints.websecure.address=:443"
            "--entrypoints.web.http.redirections.entrypoint.to=websecure"
            "--entrypoints.web.http.redirections.entrypoint.scheme=https"
            "--certificatesresolvers.letsencrypt.acme.tlschallenge=false"
            "--certificatesresolvers.letsencrypt.acme.httpchallenge=true"
            "--certificatesresolvers.letsencrypt.acme.httpchallenge.entrypoint=web"
            "--certificatesresolvers.letsencrypt.acme.storage=/letsencrypt/acme.json"
            "--api.dashboard=true"
            "--log.level=INFO"
            "--accesslog=true"
          ]
          ++ lib.optionals (cfg.cluster.traefik.acmeEmail != null) [
            "--certificatesresolvers.letsencrypt.acme.email=${cfg.cluster.traefik.acmeEmail}"
          ];
        ports = [
          {
            mode = "host";
            target = 80;
            published = 80;
            protocol = "tcp";
          }
          {
            mode = "host";
            target = 443;
            published = 443;
            protocol = "tcp";
          }
        ];
        volumes = [
          "/var/run/docker.sock:/var/run/docker.sock:ro"
        ];
        deploy = {
          mode = "replicated";
          replicas = 1;
          placement.constraints = ["node.role == manager"];
          labels = {
            "traefik.enable" = "true";
          };
        };
        networks = [
          cfg.cluster.traefik.network
        ];
      };
    };
  bootstrapCompose = yamlFormat.generate "bootstrap.yaml" {
    services = bootstrapServices;
    networks =
      {}
      // lib.optionalAttrs cfg.cluster.traefik.enable {
        "${cfg.cluster.traefik.network}" = {
          driver = "overlay";
          attachable = true;
        };
      };
    volumes = {};
    configs = {
      repos = {
        file = "${reposYaml}";
      };
      stacks = {
        file = "${stacksYaml}";
      };
    };
  };
in
  with lib; {
    options.hosting.platforms.swarm = {
      enable = mkEnableOption "Enable Docker Swarm orchestrator mode";

      role = mkOption {
        type = types.enum ["manager" "worker"];
        default = "manager";
        description = ''
          The role of this node in the Docker Swarm cluster:
          - `manager`: runs the swarm control plane; can schedule swarm init
          - `worker`: joins an existing swarm using a join token
        '';
      };

      advertiseAddr = mkOption {
        type = types.str;
        default = "";
        example = "192.168.1.10:2377";
        description = ''
          Advertise address for the swarm manager (IP or interface, optional port).
          If empty, Docker auto-detects the address.
        '';
      };

      autoInit = mkOption {
        type = types.bool;
        default = true;
        description = "Automatically initialise the swarm as a manager if not already part of one.";
      };

      tokenFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = ''
          Path to file containing the swarm join token. Required for worker nodes.
          On a manager node you can export tokens via
          `docker swarm join-token manager` or `docker swarm join-token worker`.
        '';
      };

      networks = mkOption {
        type = types.listOf types.str;
        default = [];
        example = ["traefik_public" "metrics"];
        description = ''
          Swarm-scoped overlay networks to create automatically.
          Created with `--driver overlay --attachable` so non-swarm
          containers can also attach when needed.
        '';
      };

      labels = mkOption {
        type = types.attrsOf types.str;
        default = {};
        example = {
          region = "us-central1";
          storage = "ssd";
        };
        description = ''
          Labels to apply to this swarm node after it joins the cluster.
          Useful for service placement constraints.
        '';
      };

      extraInitArgs = mkOption {
        type = types.listOf types.str;
        default = [];
        example = ["--availability" "drain"];
        description = "Extra arguments to pass to `docker swarm init`.";
      };

      extraJoinArgs = mkOption {
        type = types.listOf types.str;
        default = [];
        example = ["--availability" "drain"];
        description = "Extra arguments to pass to `docker swarm join`.";
      };

      cluster = {
        enable = mkEnableOption "Deploy cluster bootstrap stack after swarm init";

        name = mkOption {
          type = types.str;
          default = "default";
          description = "Cluster name — maps to docker/clusters/<name>/ in the repo.";
        };

        baseDomain = mkOption {
          type = types.str;
          default = "";
          example = "swarm.example.com";
          description = ''
            Base domain for Traefik routing.  Passed to swarm-cd as
            BASE_DOMAIN env var so downstream stacks can use it.
          '';
        };

        traefik = {
          enable = mkOption {
            type = types.bool;
            default = true;
            description = "Include Traefik reverse proxy in the bootstrap stack.";
          };

          acmeEmail = mkOption {
            type = types.nullOr types.str;
            default = null;
            example = "admin@example.com";
            description = ''
              Let's Encrypt registration email.  When set, injected into
              the Traefik static config.  Use a sops secret for this.
            '';
          };

          network = mkOption {
            type = types.str;
            default = "traefik_public";
            description = "Overlay network name for Traefik ingress.";
          };
        };

        swarmCd = {
          image = mkOption {
            type = types.str;
            default = "ghcr.io/m-adawi/swarm-cd:latest";
            description = "swarm-cd container image (m-adawi/swarm-cd GitOps operator).";
          };

          repoUrl = mkOption {
            type = types.str;
            default = "https://github.com/soriPhoono/homelab.git";
            description = ''Git repository URL that swarm-cd watches for stack definitions.'';
          };

          repoName = mkOption {
            type = types.str;
            default = "homelab";
            description = ''Short name for the repo (used in repos.yaml).'';
          };

          branch = mkOption {
            type = types.str;
            default = "main";
            description = ''Git branch for swarm-cd to track.'';
          };

          stacks = mkOption {
            type = types.listOf (types.submodule {
              options = {
                name = mkOption {
                  type = types.str;
                  description = "Stack name (must match the service name in compose.yaml).";
                };
                composeFile = mkOption {
                  type = types.str;
                  example = "docker/infra/traefik/compose.yaml";
                  description = ''Path to the compose file within the repo.'';
                };
                sopsFiles = mkOption {
                  type = types.listOf types.str;
                  default = [];
                  example = ["docker/infra/tailscale/secrets/tailscale_auth_key.enc"];
                  description = ''SOPS-encrypted files to decrypt before deploying the stack.'';
                };
              };
            });
            default = [];
            description = ''List of stacks for swarm-cd to manage.'';
          };

          ageKeySopsPath = mkOption {
            type = types.nullOr types.str;
            default = null;
            example = "age.key";
            description = ''
              Name of the sops secret that contains the age decryption key,
              relative to the cluster's secret prefix.
              Add the corresponding name to cluster.secrets to wire it up.
            '';
          };
        };

        extraEnv = mkOption {
          type = types.attrsOf types.str;
          default = {};
          example = {
            DASHBOARD_USERS = "\$2y\$05\$...";
          };
          description = "Extra environment variables for swarm-cd.";
        };

        secrets = mkOption {
          type = types.listOf types.str;
          default = [];
          example = ["tailscale_auth_key" "traefik_acme_email"];
          description = ''
            List of sops secret names to expose to the cluster.
            Each entry creates a sops secret at
              /run/secrets/swarm/<cluster-name>/<name>
            that swarm-cd and infra services can reference.
            Define the actual secret source in your system config:
              sops.secrets."swarm/<cluster-name>/<name>" = {
                sopsFile = <path>;
              };
          '';
        };
      };
    };

    config = mkIf cfg.enable (mkMerge [
      {
        assertions = [
          {
            assertion = implies (cfg.role == "worker") (cfg.tokenFile != null);
            message = ''
              hosting.platforms.swarm: `tokenFile` must be set when role = "worker".
              Create a token on the manager:
                docker swarm join-token worker
              Then store it in a sops secret or file and point tokenFile at it.
            '';
          }
        ];

        # Swarm overlay networks depend on the same kernel modules k0s needs
        boot.kernelModules = optionals (cfg.networks != []) [
          "br_netfilter"
          "overlay"
        ];

        systemd.services = {
          docker-swarm-init = mkIf (cfg.role == "manager" && cfg.autoInit) {
            description = "Docker Swarm — initialise manager node";
            after = ["docker.service"];
            requires = ["docker.service"];
            wantedBy = ["multi-user.target"];
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
              ExecStart = let
                initArgs =
                  (optional (cfg.advertiseAddr != "") "--advertise-addr ${cfg.advertiseAddr}")
                  ++ cfg.extraInitArgs;
              in "${pkgs.writeShellApplication {
                name = "docker-swarm-init";
                runtimeInputs = with pkgs; [docker];
                text = ''
                  STATE=$(docker info --format '{{.Swarm.LocalNodeState}}' 2>/dev/null)
                  if [ "$STATE" = "active" ]; then
                    echo "Node is already part of a swarm — skipping init."
                    exit 0
                  fi
                  echo "Initialising Docker Swarm as manager..."
                  docker swarm init ${escapeShellArgs initArgs}
                '';
              }}/bin/docker-swarm-init";
            };
          };

          docker-swarm-join = mkIf (cfg.role == "worker") {
            description = "Docker Swarm — join as worker node";
            after = ["docker.service"];
            requires = ["docker.service"];
            wantedBy = ["multi-user.target"];
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
              ExecStart = "${pkgs.writeShellApplication {
                name = "docker-swarm-join";
                runtimeInputs = with pkgs; [docker];
                text = ''
                  STATE=$(docker info --format '{{.Swarm.LocalNodeState}}' 2>/dev/null)
                  if [ "$STATE" = "active" ]; then
                    echo "Node is already part of a swarm — skipping join."
                    exit 0
                  fi
                  TOKEN_FILE="${cfg.tokenFile}"
                  if [ ! -f "$TOKEN_FILE" ]; then
                    echo "ERROR: swarm join token file missing: $TOKEN_FILE"
                    exit 1
                  fi
                  TOKEN=$(tr -d '[:space:]' < "$TOKEN_FILE")
                  echo "Joining Docker Swarm as worker..."
                  docker swarm join --token "$TOKEN" ${escapeShellArgs cfg.extraJoinArgs}
                '';
              }}/bin/docker-swarm-join";
            };
          };

          docker-swarm-networks = mkIf (cfg.networks != []) {
            description = "Docker Swarm — create overlay networks";
            after =
              ["docker.service"]
              ++ optional (cfg.role == "manager" && cfg.autoInit) "docker-swarm-init.service"
              ++ optional (cfg.role == "worker") "docker-swarm-join.service";
            requires = ["docker.service"];
            wantedBy = ["multi-user.target"];
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
              ExecStart = "${pkgs.writeShellApplication {
                name = "docker-swarm-networks";
                runtimeInputs = with pkgs; [docker gnugrep];
                text = ''
                  STATE=$(docker info --format '{{.Swarm.LocalNodeState}}' 2>/dev/null)
                  if [ "$STATE" != "active" ]; then
                    echo "Node is not in a swarm — skipping network creation."
                    exit 0
                  fi
                  ROLE=$(docker info --format '{{.Swarm.ControlAvailable}}' 2>/dev/null)
                  if [ "$ROLE" != "true" ]; then
                    echo "Not a swarm manager — skipping overlay network creation."
                    exit 0
                  fi
                  ${concatStringsSep "\n" (map (network: ''
                      if docker network ls --filter "scope=swarm" --format '{{.Name}}' 2>/dev/null | grep -Fxq "${network}"; then
                        echo "Overlay network '${network}' already exists — skipping."
                      else
                        echo "Creating overlay network '${network}'..."
                        docker network create --driver overlay --attachable "${network}"
                      fi
                    '')
                    cfg.networks)}
                '';
              }}/bin/docker-swarm-networks";
            };
          };

          docker-swarm-labels = mkIf (cfg.labels != {}) {
            description = "Docker Swarm — apply node labels";
            after =
              ["docker.service"]
              ++ optional (cfg.role == "manager" && cfg.autoInit) "docker-swarm-init.service"
              ++ optional (cfg.role == "worker") "docker-swarm-join.service";
            requires = ["docker.service"];
            wantedBy = ["multi-user.target"];
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
              ExecStart = "${pkgs.writeShellApplication {
                name = "docker-swarm-labels";
                runtimeInputs = with pkgs; [docker gnugrep];
                text = ''
                  STATE=$(docker info --format '{{.Swarm.LocalNodeState}}' 2>/dev/null)
                  if [ "$STATE" != "active" ]; then
                    echo "Node is not in a swarm — skipping label application."
                    exit 0
                  fi
                  NODE_ID=$(docker info --format '{{.Swarm.NodeID}}' 2>/dev/null)
                  ${concatStringsSep "\n" (
                    mapAttrsToList (key: value: ''
                      CURRENT=$(docker node inspect "$NODE_ID" --format '{{.Spec.Labels}}' 2>/dev/null || echo "")
                      LABEL_ENTRY="${key}=${value}"
                      if echo "$CURRENT" | grep -q "${key}"; then
                        EXISTING=$(docker node inspect "$NODE_ID" --format "{{index .Spec.Labels \"${key}\"}}" 2>/dev/null)
                        if [ "$EXISTING" = "${value}" ]; then
                          echo "Node label '${key}' is already '${value}' — skipping."
                        else
                          echo "Updating node label '${key}' → '${value}'..."
                          docker node update --label-add "${key}=${value}" "$NODE_ID"
                        fi
                      else
                        echo "Adding node label '${key}' → '${value}'..."
                        docker node update --label-add "${key}=${value}" "$NODE_ID"
                      fi
                    '')
                    cfg.labels
                  )}
                '';
              }}/bin/docker-swarm-labels";
            };
          };

          docker-swarm-cluster-bootstrap = mkIf (cfg.cluster.enable && cfg.role == "manager") {
            description = "Docker Swarm — deploy cluster bootstrap stack";
            after =
              ["docker.service"]
              ++ optional cfg.autoInit "docker-swarm-init.service"
              ++ optional (cfg.networks != []) "docker-swarm-networks.service";
            requires = ["docker.service"];
            wantedBy = ["multi-user.target"];
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
              ExecStart = "${pkgs.writeShellApplication {
                name = "docker-swarm-cluster-bootstrap";
                runtimeInputs = with pkgs; [docker gnugrep];
                text = ''
                  STATE=$(docker info --format '{{.Swarm.LocalNodeState}}' 2>/dev/null)
                  if [ "$STATE" != "active" ]; then
                    echo "Node is not in a swarm — skipping cluster bootstrap."
                    exit 0
                  fi
                  ROLE=$(docker info --format '{{.Swarm.ControlAvailable}}' 2>/dev/null)
                  if [ "$ROLE" != "true" ]; then
                    echo "Not a swarm manager — skipping cluster bootstrap."
                    exit 0
                  fi

                  STACK_NAME="cluster-${cfg.cluster.name}"

                  # Check if stack is already deployed
                  if docker stack ls --format '{{.Name}}' 2>/dev/null | grep -Fxq "$STACK_NAME"; then
                    echo "Bootstrap stack '$STACK_NAME' is already deployed — redeploying."
                    docker stack deploy -c "${bootstrapCompose}" "$STACK_NAME"
                  else
                    echo "Deploying bootstrap stack '$STACK_NAME'..."
                    docker stack deploy -c "${bootstrapCompose}" "$STACK_NAME"
                    echo "Bootstrap stack deployed."
                    echo ""
                    echo "  swarm-cd manager:  docker exec -it \$(docker ps --filter name=${STACK_NAME}_swarm-cd --format '{{.ID}}') sh"
                    echo "  traefik dashboard: http://localhost:8080  (if enabled)"
                  fi
                '';
              }}/bin/docker-swarm-cluster-bootstrap";
            };
          };
        };

        # ── Cluster sops secrets ─────────────────────────────────────────────
        # Wire sops-nix secrets into paths that swarm-cd and infra services
        # expect inside containers (/run/secrets/<name>).
        # Define secrets in your system config as:
        #   sops.secrets."swarm/<cluster-name>/<name>" = { ... };
        # Then reference them inside swarm-cd or infra compose files.
        sops.secrets = lib.listToAttrs (map (
            name:
              nameValuePair "swarm/${cfg.cluster.name}/${name}" {}
          )
          cfg.cluster.secrets);

        users.extraUsers = mapAttrs (_name: _user: {
          extraGroups = ["docker"];
        }) (filterAttrs (_name: user: user.admin) config.core.users);

        home-manager.users =
          mapAttrs (_: _: {
            programs.lazydocker.enable = true;
          })
          config.core.users;
      }
    ]);
  }
