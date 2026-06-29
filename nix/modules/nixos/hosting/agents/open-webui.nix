{
  lib,
  config,
  ...
}: let
  cfg = config.hosting.agents.open-webui;
in
  with lib; {
    options.hosting.agents.open-webui = {
      enable = mkEnableOption "Open WebUI frontend for AI agents";

      port = mkOption {
        type = types.port;
        default = 3000;
        description = "Host port for the Open WebUI web interface.";
      };

      image = mkOption {
        type = types.str;
        default = "ghcr.io/open-webui/open-webui:main";
        description = "Docker image for Open WebUI.";
      };

      apiBaseUrl = mkOption {
        type = types.str;
        default = "http://host.docker.internal:8642/v1";
        description = ''
          Base URL for the OpenAI-compatible API server. Points to the Hermes
          Agent API server running on the host (accessible via the Docker
          host gateway).
        '';
      };

      apiKey = mkOption {
        type = types.str;
        default = "";
        description = ''
          API key for the Hermes API server (matches API_SERVER_KEY in
          the Hermes agent config). Leave empty if the API server has no
          authentication configured.
        '';
      };

      apiKeyFile = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          Path to a file containing OPENAI_API_KEY=value. Alternative to
          apiKey for loading the key from a sops template or other secret
          file. The file must be in KEY=value format (one variable per line).
          Takes precedence over apiKey when set.
        '';
      };
    };

    config = mkIf cfg.enable {
      # Auto-enable the Docker container hosting platform
      hosting.platforms.docker.enable = mkDefault true;

      virtualisation.oci-containers.containers.open-webui = {
        inherit (cfg) image;
        autoStart = true;
        ports = ["${toString cfg.port}:8080"];
        volumes = ["open-webui:/app/backend/data"];
        environment =
          {
            OPENAI_API_BASE_URL = cfg.apiBaseUrl;
            ENABLE_OLLAMA_API = "false";
          }
          // optionalAttrs (cfg.apiKey != "") {
            OPENAI_API_KEY = cfg.apiKey;
          };
        environmentFiles = optionals (cfg.apiKeyFile != null) [cfg.apiKeyFile];
        extraOptions = [
          # Add host.docker.internal resolution so the container can reach
          # the Hermes API server running on the host
          "--add-host=host.docker.internal:host-gateway"
        ];
      };
    };
  }
