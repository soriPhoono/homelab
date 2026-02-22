{
  lib,
  config,
  ...
}: let
  cfg = config.hosting.blocks.backends.podman;
in
  with lib; {
    options.hosting.blocks.backends.podman = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable podman backend";
      };
    };

    config = mkIf cfg.enable {
      virtualisation.podman = {
        enable = true;
        dockerSocket.enable = true;
        dockerCompat = true;
        autoPrune = {
          enable = true;
          dates = "daily";
          flags = [
            "--all"
          ];
        };
      };

      home-manager.users =
        lib.mapAttrs (_name: _value: {
          services.podman.enable = true;
        })
        config.core.users;
    };
  }
