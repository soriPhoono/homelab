{
  lib,
  config,
  ...
}: let
  cfg = config.core.apps.development;
in
  with lib; {
    options.core.apps.development = {
      enable = mkEnableOption "Enable development apps";
    };

    # TODO: Improve this
    config = mkIf cfg.enable {
      home.shellAliases = {
        d = "docker";
        dc = "docker compose";
        lzd = "${config.programs.lazydocker.package}/bin/lazydocker";
        lsq = "${config.programs.lazysql.package}/bin/lazysql";
      };

      programs = {
        lazydocker.enable = true;
        lazysql.enable = true;
      };
    };
  }
