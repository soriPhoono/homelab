{
  lib,
  config,
  ...
}: let
  cfg = config.apps.development.terminal.kitty;
in
  with lib; {
    options.apps.development.terminal.kitty = {
      enable = mkEnableOption "Enable kitty terminal emulator application customisation";
      priority = mkOption {
        type = types.int;
        default = 20;
        description = "Priority for being the default terminal. Lower is higher priority.";
      };
    };

    config = mkIf cfg.enable {
      home.sessionVariables.TERMINAL = mkOverride cfg.priority "kitty";

      xdg.mimeApps.defaultApplications = lib.mkIf config.apps.defaultApplications.enable (let
        terminal = ["kitty.desktop"];
      in
        mkOverride cfg.priority {
          "x-scheme-handler/terminal" = terminal;
          "application/x-terminal-emulator" = terminal;
        });

      programs.kitty.enable = true;
    };
  }
