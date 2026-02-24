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
      programs = {
        npm.enable = true;
        uv.enable = true;
      };
    };
  }
