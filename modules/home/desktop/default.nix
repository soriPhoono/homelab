{
  lib,
  config,
  ...
}: let
  cfg = config.desktop;
in
  with lib; {
    imports = [
      ./environments
    ];

    options.desktop = {
      enable = mkEnableOption "Enable desktop per-user configuration";
    };

    config = mkIf cfg.enable {
      fonts.fontconfig.enable = true;

      systemd.user.services."create-font-directory" = {
        Unit = {
          Description = "Create font directory for user fonts";
          X-SwitchMethod = "restart";
        };
        Service = {
          Type = "oneshot";
          ExecStart = "mkdir -p ${config.home.homeDirectory}/.local/share/fonts";
        };
      };
    };
  }
