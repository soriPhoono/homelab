{
  lib,
  config,
  ...
}: let
  cfg = config.desktop.environments.display_managers.greetd;
in
  with lib; {
    options.desktop.environments.display_managers.greetd = {
      enable = mkEnableOption "Enable greetd display manager.";

      configurationName = mkOption {
        type = with types; nullOr (enum ["tuigreet"]);
        default = null;
        description = "The greetd greeter configuration to use.";
        example = "tuigreet";
      };
    };

    config = mkIf cfg.enable {
      services = {
        greetd = {
          enable = true;

          useTextGreeter = cfg.configurationName == null;

          settings = mkIf (cfg.configurationName == null) {
            terminal.vt = 1;

            default_session = {
              command = "${pkgs.tuigreet}/bin/tuigreet --time --greeting 'Welcome to Project Chimera'";
              user = "greeter";
            };
          };
        };
      };
    };
  }
