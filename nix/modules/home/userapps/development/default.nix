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
    ];

    options.userapps.development = {
      enable = mkEnableOption "Development tools";
    };

    config = mkIf cfg.enable {
      home.sessionPath = [
        "${config.home.homeDirectory}/.local/bin"
        "${config.home.homeDirectory}/.npm/bin"
        "${config.home.homeDirectory}/.cargo/bin"
        "${config.home.homeDirectory}/go/bin"
      ];

      programs = {
        uv.enable = true;
        cargo.enable = true;
        npm.enable = true;
        go.enable = true;
      };
    };
  }
