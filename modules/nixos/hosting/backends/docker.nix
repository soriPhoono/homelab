{
  lib,
  config,
  ...
}: let
  cfg = config.hosting.backends.docker;
in
  with lib; {
    options.hosting.backends.docker = {
      enable = mkEnableOption "Enable Docker hosting support.";
    };

    config = {
      virtualisation.docker = mkIf cfg.enable {
        enable = true;
        autoPrune.enable = true;
      };

      users.extraUsers =
        lib.mapAttrs (_name: _user: {
          extraGroups = ["docker"];
        })
        (lib.filterAttrs (_name: user: user.admin) config.core.users);
    };
  }
