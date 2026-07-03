{
  lib,
  pkgs,
  config,
  ...
}: let
  inherit (builtins) mapAttrs;
  inherit (lib) mkIf mkEnableOption mkOption mkDefault mkMerge types optionalAttrs toString;

  cfg = config.hosting.inference.ollama;

  # GPU acceleration mapping
  # On ares: integrated = Intel UHD, dedicated = AMD RX 7900 XTX (gfx1100)
  gpuPackage = {
    integrated = pkgs.ollama; # no ROCm/CUDA for Intel integrated
    dedicated = pkgs.ollama-rocm;
  };

  gpuRocmGfx = {
    integrated = null;
    dedicated = "11.0.0"; # gfx1100 → ROCm 11.0.0 (RX 7900 XTX)
  };

  selectedPackage =
    if cfg.gpu == null
    then pkgs.ollama
    else gpuPackage.${cfg.gpu};
  selectedRocmGfx =
    if cfg.gpu == null
    then null
    else gpuRocmGfx.${cfg.gpu};
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
          - `"integrated"`: use integrated GPU (Intel UHD via Vulkan or CPU fallback).
            Low power, limited VRAM. Suitable for small models.
          - `"dedicated"`: use dedicated GPU (AMD RX 7900 XTX via ROCm).
            Full GPU acceleration for large models.

          The correct ollama package and ROCm GFX version override are
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
          Host address to bind the Ollama API server.
          Set to "0.0.0.0" to allow LAN access; use "127.0.0.1" for local only.
        '';
      };

      modelsDir = mkOption {
        type = types.str;
        default = "/var/lib/ollama/models";
        description = "Directory where Ollama downloads and stores models";
      };

      loadModels = mkOption {
        type = types.listOf types.str;
        default = [];
        example = ["llama3.2:3b" "codellama:13b-instruct"];
        description = ''
          Model tags to pre-download at startup.
          Models are pulled on first boot and whenever the list changes.
        '';
      };

      synchronizeModels = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Automatically install models declared in loadModels and remove
          models that are not in the list. When false, loadModels only
          ensures the listed models are present but never removes any.
          Maps to `services.ollama.syncModels`.
        '';
      };

      openFirewall = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Open the firewall for the Ollama API port.
          Disable this if you use a reverse proxy (e.g., Traefik).
        '';
      };

      # ── Extra ─────────────────────────────────
      environmentVariables = mkOption {
        type = types.attrsOf types.str;
        default = {};
        description = "Additional environment variables for the ollama service";
      };
    };

    config = mkIf cfg.enable (mkMerge [
      {
        # Auto-enable the Docker container hosting platform
        # (Open WebUI may use Docker internally)
        hosting.platforms.docker.enable = mkDefault true;

        # Ensure model storage directory exists
        systemd.tmpfiles.rules = [
          "d ${cfg.modelsDir} 0755 ollama ollama -"
        ];

        # ── Native ollama service ────────────────
        services.ollama =
          {
            enable = true;
            package = selectedPackage;
            inherit (cfg) host;
            inherit (cfg) port;
            inherit (cfg) openFirewall;
            models = cfg.modelsDir;
            inherit (cfg) loadModels;
            syncModels = cfg.synchronizeModels;
            inherit (cfg) environmentVariables;
          }
          # ROCm GFX version override for dedicated AMD GPU
          // optionalAttrs (selectedRocmGfx != null) {
            rocmOverrideGfx = selectedRocmGfx;
          };

        # ── Home environment ──────────────────────
        # Expose OLLAMA_HOST to all users so `ollama run ...` works, and
        # auto-enable ollama as an LLM provider for AI agents (Hermes,
        # OpenCode) so they point at this local instance by default.
        home-manager.users =
          mapAttrs (_: _: {
            home.sessionVariables.OLLAMA_HOST = mkDefault "http://0.0.0.0:${toString cfg.port}";

            # Auto-enable ollama providers for AI agents
            userapps.development.agents.hermes.providers.ollama.enable = mkDefault true;
            userapps.development.agents.opencode.ollama.enable = mkDefault true;
            userapps.development.editors.vscode.common.extensions = [
              # Ollama VS Code extension — not in nixpkgs, fetched from marketplace
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
      }
    ]);
  }
