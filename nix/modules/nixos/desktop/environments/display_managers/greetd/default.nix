{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.desktop.environments.display_managers.greetd;
in
  with lib; {
    imports = [
      ./regreet.nix
    ];

    options.desktop.environments.display_managers.greetd = {
      enable = mkEnableOption "Enable greetd display manager.";

      variant = mkOption {
        type = with types; nullOr (enum ["tuigreet" "regreet"]);
        default = null;
        description = "The greetd greeter variant to use.";
        example = "tuigreet";
      };
    };

    config = mkIf cfg.enable {
      services = {
        greetd = {
          enable = true;

          useTextGreeter = cfg.variant == null;

          settings = mkIf (cfg.variant == null) {
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
