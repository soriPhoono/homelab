{
  lib,
  pkgs,
  config,
  ...
}: let
  themeCfg = config.themes;
in
  with lib; {
    options.themes.qt = {
    };

    config = mkIf themeCfg.enable {
      home.sessionVariables = {
        QT_QPA_PLATFORMTHEME = "qt6ct";
      };

      qt = let
        qtctSettings = {
          Appearance = {
            style = "kvantum";
            icon_theme = "Papirus-Dark";
            standard_dialogs = "xdgdesktopportal";
          };

          Fonts = {
            fixed = "JetBrainsMono Nerd Font Mono 14";
            general = "JetBrainsMono Nerd Font Mono 14";
            monospace = "JetBrainsMono Nerd Font Mono 14";
            small = "JetBrainsMono Nerd Font Mono 14";
            title = "JetBrainsMono Nerd Font Mono 14";
          };
        };
      in {
        enable = true;

        kvantum = {
          enable = true;

          themes = with pkgs; [
            catppuccin-kvantum
          ];

          settings.General.theme = "catppuccin-frappe";
        };

        qt5ctSettings = qtctSettings;
        qt6ctSettings = qtctSettings;

        style.name = "kvantum";

        platformTheme = "qtct";
      };
    };
  }
