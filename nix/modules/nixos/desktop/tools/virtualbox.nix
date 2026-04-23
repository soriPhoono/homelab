{
  lib,
  config,
  ...
}: let
  cfg = config.desktop.tools.virtualbox;
in
  with lib; {
    options.desktop.tools.virtualbox = {
      enable = mkEnableOption "Enable VirtualBox hosting";
    };

    config = mkIf cfg.enable {
      virtualisation.virtualbox.host = {
        enable = true;
        # enableExtensionPack = true;
      };

      users.extraUsers =
        mapAttrs (_name: _user: {
          extraGroups = ["vboxusers"];
        })
        (filterAttrs (_name: user: user.admin) config.core.users);
    };
  }
