{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.hosting.inference.ollama;
in
  with lib; {
    options.hosting.inference.ollama = {
      enable = mkEnableOption "the Ollama local LLM execution engine and server";

      acceleration = mkOption {
        type = types.nullOr (types.enum ["cuda" "rocm" "vulkan" "cpu"]);
        default = null;
        example = "cuda";
        description = ''
          Hardware acceleration backend to use for Ollama.
          Maps to the appropriate nixpkgs package (`ollama-cuda`, `ollama-rocm`, `ollama-vulkan`, `ollama-cpu`, or default `ollama`).
        '';
      };

      rocmOverrideGfx = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "10.3.0";
        description = ''
          Override GPU architecture for ROCm (`HSA_OVERRIDE_GFX_VERSION`).
        '';
      };

      loadModels = mkOption {
        type = types.listOf types.str;
        apply = builtins.filter (model: model != "");
        default = [
          "llama3.2"
          "qwen2.5-coder"
        ];
        example = [
          "llama3.2"
          "mistral"
        ];
        description = ''
          List of default admin-approved models to download automatically via systemd `ollama-model-loader`.
        '';
      };

      syncModels = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Synchronize installed models with declared `loadModels` list,
          removing any models that are installed but not currently declared there.
        '';
      };

      host = mkOption {
        type = types.str;
        default = "127.0.0.1";
        example = "0.0.0.0";
        description = ''
          Host address for the Ollama server to listen on.
        '';
      };

      port = mkOption {
        type = types.port;
        default = 11434;
        example = 11434;
        description = ''
          Port for the Ollama server to listen on.
        '';
      };

      openFirewall = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to open the firewall port for Ollama.
        '';
      };

      environmentVariables = mkOption {
        type = types.attrsOf types.str;
        default = {};
        example = {
          OLLAMA_LLM_LIBRARY = "cpu";
        };
        description = ''
          Extra environment variables for the systemd Ollama service.
        '';
      };
    };

    config = mkIf cfg.enable (mkMerge [
      {
        services.ollama = {
          enable = true;
          inherit (cfg) host;
          inherit (cfg) port;
          inherit (cfg) openFirewall;
          inherit (cfg) loadModels;
          inherit (cfg) syncModels;
          inherit (cfg) rocmOverrideGfx;
          inherit (cfg) environmentVariables;
          package =
            if cfg.acceleration == "cuda"
            then pkgs.ollama-cuda
            else if cfg.acceleration == "rocm"
            then pkgs.ollama-rocm
            else if cfg.acceleration == "vulkan"
            then pkgs.ollama-vulkan
            else if cfg.acceleration == "cpu"
            then pkgs.ollama-cpu
            else pkgs.ollama;
        };

        home-manager.users =
          mapAttrs (_name: _user: {
            apps.development.inference.ollama.enable = mkForce false;
          })
          config.core.users;

        environment.variables = {
          OLLAMA_HOST = "${cfg.host}:${toString cfg.port}";
        };
      }
    ]);
  }
