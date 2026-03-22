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
      ./disk_tools
    ];

    options.userapps.development = {
      enable = mkEnableOption "Development tools";
    };

    config = mkIf cfg.enable {
      home.sessionPath = [
        "${config.home.homeDirectory}/.npm/bin"
        "${config.home.homeDirectory}/.local/bin"
        "${config.home.homeDirectory}/.cargo/bin"
        "${config.home.homeDirectory}/go/bin"
      ];

      programs = { 
         npm.enable = true; 
         uv.enable = true; 
       };
    };
  }
