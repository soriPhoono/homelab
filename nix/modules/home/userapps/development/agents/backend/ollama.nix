{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.userapps.development.agents.backend.ollama;
in
  with lib; {
    options.userapps.development.agents.backend.ollama = {
      enable = mkEnableOption "Enable ollama for local LLM deployment";
      acceleration = mkOption {
        type = types.nullOr (types.enum ["cpu" "rocm" "cuda" "vulkan"]);
        default = null;
        description = "Hardware acceleration to use for ollama";
      };
    };

    config = mkIf cfg.enable {
      home.packages = [
        (
          if cfg.acceleration == null
          then pkgs.ollama
          else pkgs."ollama-${cfg.acceleration}"
        )
      ];
    };
  }
