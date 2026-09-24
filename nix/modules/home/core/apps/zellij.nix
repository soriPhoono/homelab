{
  lib,
  config,
  ...
}: let
  cfg = config.core.apps.zellij;
in
  with lib; {
    options.core.apps.zellij = {
      enable = mkEnableOption "Enable zellij terminal multiplexer";
    };

    config = mkIf cfg.enable {
      programs.zellij = {
        enable = true;
      };
    };
  }
