{
  lib,
  config,
  ...
}: let
  cfg = config.userapps.development;
in
  with lib; {
    imports = [
      ./agentics
      ./agents
      ./appliances
      ./editors
      ./inference
      ./infrastructure
      ./terminal
    ];

    options.userapps.development = {
      enable = mkEnableOption "Enable core developer systems/tools";
    };

    config = mkIf cfg.enable {
      programs = {
        npm.enable = true;
        uv.enable = true;
        cargo.enable = true;
        go.enable = true;
      };
    };
  }
