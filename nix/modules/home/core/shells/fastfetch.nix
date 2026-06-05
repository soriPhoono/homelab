{
  lib,
  config,
  ...
}: let
  cfg = config.core.shells.fastfetch;
in
  with lib; {
    options.core.shells.fastfetch = {
      enable =
        mkEnableOption "fastfetch"
        // {
          default = true;
        };

      settings = mkOption {
        type = with types; attrs;
        default = {};
        description = "Settings for fastfetch";
      };
    };

    config = lib.mkIf cfg.enable {
      programs.fastfetch = {
        enable = true;

        inherit (cfg) settings;
      };
    };
  }
