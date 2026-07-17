{
  lib,
  config,
  ...
}: let
  cfg = config.hosting;
in
  with lib; {
    imports = [
      ./platforms
      ./gaming
      ./proxy
      ./media
    ];

    options.hosting = {
      enable = mkEnableOption "Enable hosting on this machine";
    };

    config = mkIf cfg.enable {
      users = {
        users.microserver = {
          isSystemUser = true;

          home = "/var/lib/microserver";
          createHome = true;

          uid = 900;
          group = "microserver";

          subUidRanges = [
            {
              startUid = 100000;
              count = 65536;
            }
          ];

          subGidRanges = [
            {
              startGid = 100000;
              count = 65536;
            }
          ];

          linger = true;
        };

        groups = {
          microserver = {
            gid = 900;
            members = mapAttrsToList (name: _user: name) (filterAttrs (_name: user: user.admin) config.core.users);
          };
        };
      };
    };
  }
