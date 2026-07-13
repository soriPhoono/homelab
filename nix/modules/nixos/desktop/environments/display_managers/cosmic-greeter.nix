{
  lib,
  config,
  ...
}: let
  modulePath = "desktop.environments.display-managers.cosmic-greeter";
  cfg = config.${modulePath};
in
  with lib; {
    options.${modulePath} = {
      enable =
        mkEnableOption "Enable cosmic greeter display manager";
    };

    config = mkIf cfg.enable (mkMerge [
      {
        services.displayManager.cosmic-greeter.enable = true;
      }
    ]);
  }
