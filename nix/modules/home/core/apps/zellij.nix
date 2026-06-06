{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.core.apps.zellij;
in
  with lib; {
    options.core.apps.zellij = {
      enable = mkEnableOption "Enable zellij terminal multiplexer";

      configFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Path to a custom zellij config.kdl file";
        example = literalExpression ./zellij-config.kdl;
      };
    };

    config = mkIf cfg.enable {
      home.packages = [pkgs.zellij];

      xdg.configFile."zellij/config.kdl" = mkIf (cfg.configFile != null) {
        source = cfg.configFile;
      };
    };
  }
