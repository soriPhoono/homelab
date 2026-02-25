{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.userapps.development.terminal.warp;
in
  with lib; {
    options.userapps.development.terminal.warp = {
      enable = mkEnableOption "Enable warp terminal";
      priority = mkOption {
        type = types.int;
        default = 30;
        description = "Priority for being the default terminal. Lower is higher priority.";
      };
    };

    config = mkIf cfg.enable {
      home.sessionVariables = {
        TERMINAL = mkOverride cfg.priority "warp-terminal";
      };

      xdg.mimeApps.defaultApplications = let
        terminal = ["dev.warp.Warp.desktop"];
      in
        mkOverride cfg.priority {
          "x-scheme-handler/terminal" = terminal;
          "application/x-terminal-emulator" = terminal;
        };

      home.packages = with pkgs; [
        warp-terminal
      ];
    };
  }
