{
  lib,
  config,
  ...
}: let
  cfg =
    config.themes;
in
  with lib; {
    options.themes = {
      enable = mkEnableOption "themes";

      base16Scheme = mkOption {
        type = with types; nullOr str;
        default = null;
        description = "Base16 scheme to use";
      };
    };

    config = mkIf cfg.enable {
      stylix = {
        enable = true;
        homeManagerIntegration.followSystem = false;
        homeManagerIntegration.autoImport = false;

        base16Scheme = mkIf (cfg.base16Scheme != null) cfg.base16Scheme;
      };
    };
  }
