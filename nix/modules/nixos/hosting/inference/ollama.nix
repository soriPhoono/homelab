{
  lib,
  pkgs,
  config,
  ...
}: let
  inherit (lib.homelab.containers) mkContainerOption mkContainer;

  cfg = config.hosting.inference.ollama;

  name = "ollama";
  configurationDirectory = "/var/lib/${name}";
in
  with lib; {
    options.hosting.inference.ollama = mkContainerOption {
      inherit name;
      description = "Enable Ollama container for local LLM inference";
      extraOptions = {
        container.publication = mkOption {
          type = types.listOf (types.enum ["tailscale"]);
          default = [];
          description = ''
            Determines where the container is published to. Defaults to [] (unpublished)
            so high-resource inference hardware is opt-in for network sharing.
          '';
        };

        acceleration = mkOption {
          type = types.nullOr (types.enum ["cuda" "rocm"]);
          default = null;
          example = "cuda";
          description = ''
            Hardware acceleration backend for the Ollama container (cuda, rocm, or null).
          '';
        };

        loadModels = mkOption {
          type = types.listOf types.str;
          apply = builtins.filter (model: model != "");
          default = [];
          example = [
            "llama3.2"
            "mistral"
          ];
          description = ''
            List of default admin-approved models to download automatically via HTTP API model loader.
          '';
        };

        port = mkOption {
          type = types.port;
          default = 11434;
          example = 11434;
          description = ''
            Host port for the Ollama server to listen on.
          '';
        };
      };
    };

    config = mkIf cfg.enable (mkMerge [
      {
        hosting.enable = true;

        systemd.tmpfiles.rules = [
          "d ${configurationDirectory} 0755 root root -"
        ];

        virtualisation.oci-containers.containers.${name} = mkMerge [
          (mkContainer {
            inherit name cfg config;
            image = "docker.io/ollama/ollama:latest";
            serviceName = "ollama";
            servicePort = cfg.port;
          })
          {
            volumes = [
              "${configurationDirectory}:/root/.ollama"
            ];

            ports = [
              "${toString cfg.port}:11434"
            ];

            environment = {
              OLLAMA_HOST = "0.0.0.0:11434";
            };
          }
        ];

        systemd.services.ollama-model-loader = mkIf (cfg.loadModels != []) {
          description = "Download Ollama models";
          wantedBy = ["multi-user.target"];
          wants = ["network-online.target"];
          after = ["network-online.target" "${config.virtualisation.oci-containers.backend}-${name}.service"];
          serviceConfig = {
            Type = "oneshot";
            Restart = "on-failure";
            RestartSec = "5s";
            ExecStart = let
              backendCmd = "${pkgs.${config.virtualisation.oci-containers.backend}}/bin/${config.virtualisation.oci-containers.backend}";
              curl = getExe pkgs.curl;

              pullScript = pkgs.writeShellScript "ollama-model-pull" ''
                set -euo pipefail
                echo "Waiting for Ollama container endpoint..."
                until ${curl} -sf http://127.0.0.1:${toString cfg.port}/ > /dev/null 2>&1; do
                  sleep 2
                done
                echo "Ollama container is ready."

                ${concatMapStrings (model: ''
                    echo "Pulling model: ${model}..."
                    ${backendCmd} exec ${name} ollama pull ${escapeShellArg model} || true
                  '')
                  cfg.loadModels}
              '';
            in "${pullScript}";
          };
        };

        home-manager.users =
          mapAttrs (_name: _user: {
            apps.development.inference.ollama.enable = mkForce false;
          })
          config.core.users;

        environment.variables = {
          OLLAMA_HOST = "127.0.0.1:${toString cfg.port}";
        };
      }

      # ── Hardware acceleration (CUDA / ROCm) ────────────────
      (mkIf (cfg.acceleration == "cuda") {
        virtualisation.oci-containers.containers.${name}.extraOptions = [
          "--device=nvidia.com/gpu=all"
        ];
      })

      (mkIf (cfg.acceleration == "rocm") {
        virtualisation.oci-containers.containers.${name}.extraOptions = [
          "--device=/dev/kfd"
          "--device=/dev/dri"
        ];
      })
    ]);
  }
