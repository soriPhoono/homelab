{
  lib,
  config,
  ...
}: let
  modulePath = "Your module path here as an attrset";
  cfg = config.${modulePath};
in
  with lib; {
    options.${modulePath} = {
      enable = mkEnableOption "Enable this module";
    };

    config = mkIf cfg.enable (mkMerge [
      {
      }
    ]);
  }
