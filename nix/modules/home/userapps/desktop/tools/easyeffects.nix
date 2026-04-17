{
  lib,
  config,
  ...
}: let
  cfg = config.userapps.desktop.tools.easyeffects;
in
  with lib; {
    options.userapps.desktop.tools.easyeffects = {
      enable = mkEnableOption "Enable EasyEffects for audio processing";
    };

    config = mkIf cfg.enable {
      services.easyeffects.enable = true;
    };
  }
