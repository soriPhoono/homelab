{
  lib,
  config,
  ...
}: let
  cfg = config.userapps.development;
in
  with lib; {
    imports = [
      ./agents
      ./editors
      ./terminal
      ./knowledge-management
    ];

    options.userapps.development = {
      enable = mkEnableOption "Development tools";
    };

    config = mkIf cfg.enable {
      home.sessionVariables = {
        PATH = "$PATH:${config.home.homeDirectory}/.npm";
      };

      programs = {
        npm.enable = true;
        uv.enable = true;
      };
    };
  }
