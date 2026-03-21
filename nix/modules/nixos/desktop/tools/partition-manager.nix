{
  lib,
  config,
  ...
}: let
  cfg = config.desktop.tools.partition-manager;
in
  with lib; {
    options.desktop.tools.partition-manager.enable = mkEnableOption "Enable partition-manager";

    config = mkIf cfg.enable {
      programs.partition-manager.enable = true;
    };
  }
