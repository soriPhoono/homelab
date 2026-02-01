{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.userapps.agents.claude;
in
  with lib; {
    options.userapps.agents.claude = {
      enable = mkEnableOption "Enable Claude AI agent";
    };

    config = mkIf cfg.enable {
      home.packages = with pkgs; [
        claude-code
      ];
    };
  }
