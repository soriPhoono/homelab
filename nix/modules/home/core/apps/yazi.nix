{
  lib,
  config,
  ...
}: let
  cfg = config.core.apps.yazi;
in
  with lib; {
    options.core.apps.yazi.enable = mkEnableOption "Enable yazi terminal file browser";

    config = mkIf cfg.enable {
      programs.yazi.enable = true;
    };
  }
