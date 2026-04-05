{
  lib,
  config,
  ...
}: let
  cfg = config.core.android;
in
  with lib; {
    options.core.android = {
      enable = mkEnableOption "Enable Android support";
    };

    config = mkIf cfg.enable {
      android-integration = {
        am.enable = true;
        termux-open-url.enable = true;
        termux-reload-settings.enable = true;
      };
    };
  }
