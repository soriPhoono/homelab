{
  config,
  lib,
  ...
}: let
  cfg = config.userapps.desktop.environments.window-managers.hyprland;
  colors = config.lib.stylix.colors or {};
in
  with lib; {
    config = mkIf (cfg.enable && colors != {}) {
      # Let Stylix manage cursor and general theming on its own terms
      stylix.targets.hyprland.enable = false;

      wayland.windowManager.hyprland.settings.config = {
        general = {
          "col.active_border" = "rgb(${colors.base0D})";
          "col.inactive_border" = "rgb(${colors.base03})";
        };

        decoration = {
          shadow.color = "rgba(${colors.base00}99)";
        };

        group = {
          "col.border_active" = "rgb(${colors.base0D})";
          "col.border_inactive" = "rgb(${colors.base03})";
          "col.border_locked_active" = "rgb(${colors.base0C})";

          groupbar = {
            "col.active" = "rgb(${colors.base0D})";
            "col.inactive" = "rgb(${colors.base03})";
            "text_color" = "rgb(${colors.base05})";
          };
        };

        misc = {
          "background_color" = "rgb(${colors.base00})";
        };
      };
    };
  }
