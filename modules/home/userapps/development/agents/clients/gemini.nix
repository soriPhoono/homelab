{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.userapps.development.agents.gemini;
in
  with lib; {
    options.userapps.development.agents.gemini = {
      enable = mkEnableOption "Enable Gemini AI agent";
      enableJules = mkEnableOption "Enable Jules CLI";
    };

    config = mkIf cfg.enable {
      programs.gemini-cli.enable = true;
      home.packages = mkIf cfg.enableJules [ pkgs.jules-cli ];
    };
  }
