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
      ./domain_specific
      ./terminal
      ./knowledge-management
    ];

    options.userapps.development = {
      enable = mkEnableOption "Development tools";
    };

    config = mkIf cfg.enable {
      home.sessionPath = [
        "${config.home.homeDirectory}/.npm/bin"
      ];

      programs = {
        npm.enable = true;
        uv.enable = true;
      };
    };
  }
