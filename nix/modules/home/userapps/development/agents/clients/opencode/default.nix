# TODO: Finish opencode configuration
{
  lib,
  config,
  ...
}: let
  cfg = config.userapps.development.agents.opencode;
in
  with lib; {
    options.userapps.development.agents.opencode = {
      enable = mkEnableOption "Enable OpenCode AI agent";
    };

    config = mkIf cfg.enable {
      programs.opencode = {
        enable = true;
        enableMcpIntegration = true;
      };
    };
  }
