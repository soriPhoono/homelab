{
  lib,
  config,
  ...
}: let
  cfg = config.hosting.single-node.features.sunshine;
in
  with lib; {
    options.hosting.single-node.features.sunshine = {
      enable = mkEnableOption "Enable sunshine remote desktop service";
    };

    config = mkIf cfg.enable {
      services.sunshine = {
        enable = true;
        capSysAdmin = true;
        openFirewall = true;
      };
    };
  }
