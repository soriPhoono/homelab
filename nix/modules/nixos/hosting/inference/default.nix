{
  lib,
  config,
  ...
}: let
  cfg = config.hosting.inference;
in
  with lib; {
    imports = [
      ./ollama.nix
    ];

    options.hosting.inference = {
      enable = mkEnableOption "Enable LLM inference services on device";
    };

    config = mkIf cfg.enable {
      hosting.inference.ollama.enable = mkDefault true;
    };
  }
