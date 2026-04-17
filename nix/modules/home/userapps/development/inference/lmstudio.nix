{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.userapps.development.inference.lmstudio;
in
  with lib; {
    options.userapps.development.inference.lmstudio = {
      enable = mkEnableOption "Enable LM Studio for local LLM deployment";
    };

    config = mkIf cfg.enable {
      home.packages = with pkgs; [
        lmstudio
      ];
    };
  }
