{
  lib,
  config,
  ...
}: let
  cfg = config.hosting.platforms.podman;
in
  with lib; {
    options.hosting.platforms.podman = {
      enable = mkEnableOption "Enable podman containerization platform";
    };

    config = mkIf cfg.enable (mkMerge [
      {
        virtualization.podman = {
          enable = true;

          autoPrune = {
            enable = true;
            dates = "daily";
          };

          dockerSocket.enable = true;
        };
      }
    ]);
  }
