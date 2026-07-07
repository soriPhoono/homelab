{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (builtins) mapAttrs;
  inherit (lib) mkIf mkEnableOption mkOption mkDefault types optionalAttrs toString unique flatten mapAttrsToList concatStringsSep literalExpression;

  cfg = config.hosting.inference.ollama;

  # GPU device paths — consistent with gaming/wolf.nix layout
  gpuDevices = {
    integrated = {
      render = "/dev/dri/renderD128";
      card = "/dev/dri/card1";
    };
    dedicated = {
      render = "/dev/dri/renderD129";
      card = "/dev/dri/card2";
    };
  };

  selectedGpu =
    if cfg.gpu == null
    then null
    else gpuDevices.${cfg.gpu};

  # Auto-discover models from agent configs
  defaultModels = unique (flatten (
    (mapAttrsToList (_user: config: config.apps.development.agents.opencode.providers.ollama.models or []) config.home-manager.users)
    ++ (mapAttrsToList (_user: config: config.apps.development.agents.hermes.providers.ollama.models or []) config.home-manager.users)
  ));

  portString = toString cfg.port;
in
  with lib; {
    options.hosting.inference.ollama = {
      enable = mkEnableOption "Enable Ollama local LLM inference server";

      gpu = mkOption {
        type = types.nullOr (types.enum ["integrated" "dedicated"]);
        default = null;
        description = ''
          GPU to use for model inference acceleration.

          - `null` (default): CPU-only inference (no GPU acceleration).
          - `"integrated"`: use integrated GPU (Intel UHD via CPU fallback).
            Low power, limited VRAM. Suitable for small models.
          - `"dedicated"`: use dedicated GPU (AMD RX 7900 XTX via ROCm).
            Full GPU acceleration for large models.

          The correct Docker image tag and device passthrough are
          selected automatically based on this value.
        '';
      };

      port = mkOption {
        type = types.port;
        default = 11434;
        description = "Port for the Ollama HTTP API";
      };

      host = mkOption {
        type = types.str;
        default = "0.0.0.0";
        description = ''
          Host address to bind the published Docker port.
          Set to "0.0.0.0" (default) for LAN/Tailscale access;
          set to "127.0.0.1" for local-only access.
        '';
      };

      image = mkOption {
        type = types.str;
        default =
          if cfg.gpu == "dedicated"
          then "ollama/ollama:rocm"
          else "ollama/ollama";
        defaultText = literalExpression ''
          if gpu == "dedicated" then "ollama/ollama:rocm" else "ollama/ollama"
        '';
        description = "Docker image for the Ollama container";
      };

      modelsDir = mkOption {
        type = types.str;
        default = "/var/lib/ollama/models";
        description = "Host directory where Ollama stores models (mounted to /root/.ollama)";
      };

      loadModels = mkOption {
        type = types.listOf types.str;
        default = defaultModels;
        example = ["llama3.2:3b" "codellama:13b-instruct"];
        description = ''
          Model tags to pre-download at startup.
          Models are pulled on first boot via a oneshot systemd service.
        '';
      };

      synchronizeModels = mkOption {
        type = types.bool;
        default = true;
        description = ''
          When true, models listed in loadModels are pulled on service start.
          When false, no automatic model pulling occurs.
        '';
      };

      openFirewall = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Open the firewall for the Ollama API port.
          Docker port mappings typically bypass the host firewall,
          so this is a safety net for strict nftables configurations.
        '';
      };

      extraOptions = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "Extra Docker options passed directly to the container runtime.";
      };

      environmentVariables = mkOption {
        type = types.attrsOf types.str;
        default = {};
        description = "Additional environment variables for the Ollama container";
      };

      numCtx = mkOption {
        type = types.int;
        default = 8192;
        description = ''
          Context window size (num_ctx) applied to loaded models.
          Ollama's default is 2048, which is too small for agent
          conversations — the system prompt alone often consumes half
          of that, leaving no room for output.
          Raise to 8192+ for agent use; 32768 for models that support it.
        '';
      };

      numPredict = mkOption {
        type = types.int;
        default = -1;
        description = ''
          Maximum tokens to predict (-1 = unlimited / generate until EOS).
          Set to a positive value (e.g. 4096) to cap response length.
        '';
      };
    };

    config = mkIf cfg.enable {
      # Auto-enable the Docker container hosting platform
      hosting.platforms.docker.enable = mkDefault true;

      # Firewall — Docker manages its own rules, but provide the option
      networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [cfg.port];

      # Ensure model storage directory exists
      systemd.tmpfiles.rules = [
        "d ${cfg.modelsDir} 0755 - - -"
      ];

      # Ollama Docker container — single definition with conditional GPU config
      virtualisation.oci-containers.containers.ollama = {
        inherit (cfg) image;
        autoStart = true;

        ports =
          if cfg.host == "0.0.0.0"
          then ["${portString}:${portString}"]
          else ["${cfg.host}:${portString}:${portString}"];

        volumes = [
          "${cfg.modelsDir}:/root/.ollama"
        ];

        environment =
          {OLLAMA_HOST = "0.0.0.0";}
          // optionalAttrs (cfg.gpu == "dedicated") {
            HSA_OVERRIDE_GFX_VERSION = "11.0.0";
          }
          // cfg.environmentVariables;

        extraOptions =
          ["--init"]
          ++ (
            if cfg.gpu == "dedicated"
            then [
              "--device=/dev/kfd"
              "--device=/dev/dri"
              "--group-add=video"
            ]
            else if cfg.gpu == "integrated"
            then [
              "--device=${selectedGpu.render}"
              "--device=${selectedGpu.card}"
            ]
            else []
          )
          ++ cfg.extraOptions;
      };

      # ── Home environment ──────────────────────
      # Auto-enable ollama as an LLM provider for AI agents so they
      # point at the local instance (localhost:11434 via Docker port mapping).
      home-manager.users =
        mapAttrs (_: _: {
          apps.development.agents.hermes.providers.ollama.enable = mkDefault true;
          apps.development.agents.opencode.providers.ollama.enable = mkDefault true;
          apps.development.editors.vscode.common.extensions = [
            (pkgs.vscode-utils.buildVscodeMarketplaceExtension {
              mktplcRef = {
                publisher = "ollama";
                name = "ollama";
                version = "0.0.2";
                sha256 = "sha256-s0umMpHqjJvDNaqloCN0zUr1XCXlRHxUzhCgNwlBhXo=";
              };
            })
          ];
        })
        config.core.users;

      # Model loading service — pulls declared models after container starts
      systemd.services.ollama-pull-models = mkIf (cfg.synchronizeModels && cfg.loadModels != []) {
        after = ["docker-ollama.service"];
        wants = ["docker-ollama.service"];
        wantedBy = ["multi-user.target"];
        path = with pkgs; [docker curl];
        script = ''
          # Wait for ollama to be ready
          for i in $(seq 1 30); do
            if docker exec ollama ollama list >/dev/null 2>&1; then
              break
            fi
            sleep 2
          done
          ${concatStringsSep "\n" (map (model: ''
              echo "Pulling model: ${model}..."
              docker exec ollama ollama pull ${model}
              echo "Applying settings (num_ctx=${toString cfg.numCtx}, num_predict=${toString cfg.numPredict}) to ${model}..."
              curl -s -X POST http://localhost:${portString}/api/create \
                -H "Content-Type: application/json" \
                -d '{
                  "model": "${model}",
                  "from": "${model}",
                  "stream": false,
                  "parameters": {
                    "num_ctx": ${toString cfg.numCtx},
                    "num_predict": ${toString cfg.numPredict}
                  }
                }'
            '')
            cfg.loadModels)}
        '';
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
      };
    };
  }
