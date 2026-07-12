{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.apps.development.inference.lmstudio;
in
  with lib; {
    options.apps.development.inference.lmstudio = {
      enable = mkEnableOption "Enable LM Studio for local LLM deployment";
    };

    config = mkIf cfg.enable {
      home.packages = with pkgs; [
        lmstudio
      ];
    };
  }
