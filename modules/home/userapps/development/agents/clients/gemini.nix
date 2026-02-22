{
  lib,
  config,
  ...
}: let
  cfg = config.userapps.development.agents.gemini;
in
  with lib; {
    options.userapps.development.agents.gemini = {
      enable = mkEnableOption "Enable Gemini AI agent";
    };

    config = mkIf cfg.enable {
      programs.gemini-cli.enable = true;
    };
  }
