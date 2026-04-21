{
  lib,
  config,
  ...
}: let
  cfg = config.hosting;
in
  with lib; {
    imports = [
      ./proxy
      ./media
    ];

    options.hosting.enable = mkEnableOption "Enable hosting services";

    config = mkIf cfg.enable {
      systemd.tmpfiles.rules = [
        "d /mnt/local 0775 - - -"
      ];
    };
  }
