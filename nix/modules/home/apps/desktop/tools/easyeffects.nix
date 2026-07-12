{
  lib,
  config,
  ...
}: let
  cfg = config.apps.desktop.tools.easyeffects;
in
  with lib; {
    options.apps.desktop.tools.easyeffects = {
      enable = mkEnableOption "Enable EasyEffects for audio processing";
    };

    config = mkIf cfg.enable {
      services.easyeffects.enable = true;
    };
  }
