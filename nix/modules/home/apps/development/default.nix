{
  lib,
  config,
  ...
}: let
  cfg = config.apps.development;
in
  with lib; {
    imports = [
      ./agents
      ./appliances
      ./editors
      ./inference
      ./infrastructure
      ./terminal
    ];

    options.apps.development = {
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
