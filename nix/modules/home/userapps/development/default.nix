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
      home.sessionPath = [
        "${config.home.homeDirectory}/.npm/bin"
        "${config.home.homeDirectory}/.local/bin"
        "${config.home.homeDirectory}/.cargo/bin"
        "${config.home.homeDirectory}/go/bin"
      ];
    };
  }
