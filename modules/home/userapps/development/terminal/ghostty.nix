{
  lib,
  config,
  ...
}: let
  cfg = config.userapps.development.terminal.ghostty;
in
  with lib; {
    options.userapps.development.terminal.ghostty = {
      enable = mkEnableOption "Enable ghostty terminal emulator application customisation";
      priority = mkOption {
        type = types.int;
        default = 10;
        description = "Priority for being the default terminal. Lower is higher priority.";
      };
    };

    config = mkIf cfg.enable {
      home.sessionVariables = {
        TERMINAL = mkOverride cfg.priority "ghostty";
      };

      xdg.mimeApps.defaultApplications = let
        terminal = ["com.mitchellh.ghostty.desktop"];
      in
        mkOverride cfg.priority {
          "x-scheme-handler/terminal" = terminal;
          "application/x-terminal-emulator" = terminal;
        };

      programs.ghostty = {
        enable = true;
        settings = {
          theme = "dark:catppuccin-frappe,light:catppuccin-latte";
          font-family = "SauceCodePro Nerd Font";
          font-size = 12;
          window-decoration = false;
          window-padding-x = 8;
          window-padding-y = 8;
          confirm-close-surface = false;
        };
      };
    };
  }
