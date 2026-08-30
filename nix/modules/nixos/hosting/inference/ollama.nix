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
      enable = mkEnableOption "Ollama inference server via nixpkgs";
      acceleration = mkOption {
        type = types.enum ["cpu" "cuda" "rocm"];
        default = "cpu";
        description = "Whether to use CPU or GPU acceleration for Ollama.";
      };
    };

    config = mkIf cfg.enable (mkMerge [
      {
        services.ollama = {
          enable = true;
          package =
            if cfg.acceleration == "cpu"
            then pkgs.ollama
            else if cfg.acceleration == "cuda"
            then pkgs.ollama-cuda
            else if cfg.acceleration == "rocm"
            then pkgs.ollama-rocm
            else throw "Invalid acceleration option: ${cfg.acceleration}";
        };
      }
    ]);
  }
