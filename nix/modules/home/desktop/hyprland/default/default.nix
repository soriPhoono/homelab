{
  lib,
  config,
  ...
}: let
  cfg = config.desktop.hyprland.default;
in
  with lib; {
    imports = [
      ./binds
      ./services
    ];

    options.desktop.hyprland.default = {
      enable =
        (mkEnableOption "Enable default hyprland desktop customizations")
        // {
          default = config.desktop.hyprland.enable;
        };
    };

    config = mkIf cfg.enable {
      wayland.windowManager.hyprland.settings = {
        bezier = [
          "overshot, 0.05, 0.9, 0.1, 1.05"
          "smoothOut, 0.5, 0, 0.99, 0.99"
          "smoothIn, 0.5, -0.5, 0.68, 1.5"
        ];

        animation = [
          "windows, 1, 5, overshot, slide"
          "windowsOut, 1, 3, smoothOut"
          "windowsIn, 1, 3, smoothOut"
          "windowsMove, 1, 4, smoothIn, slide"
          "border, 1, 5, default"
          "fade, 1, 5, smoothIn"
          "fadeDim, 1, 5, smoothIn"
          "workspaces, 1, 6, default"
        ];

        general = {
          border_size = 3;
          gaps_in = 4;
          gaps_out = 8;
          float_gaps = 8;

          snap.enabled = true;
        };

        decoration = {
          rounding = 10;

          active_opacity = 0.8;
          inactive_opacity = 0.8;

          shadow.sharp = true;
        };

        binds = {
          hide_special_on_workspace_change = true;

          workspace_center_on = 1;
        };

        input = {
          repeat_rate = 30;
          repeat_delay = 200;

          accel_profile = "flat";

          touchpad.middle_button_emulation = true;
        };

        xwayland = {
          force_zero_scaling = true;
          create_abstract_socket = true;
        };

        render.direct_scanout = 2;

        ecosystem = {
          no_update_news = true;
          no_donation_nag = true;
        };

        misc = {
          disable_hyprland_logo = true;

          mouse_move_enables_dpms = true;
          key_press_enables_dpms = true;

          animate_manual_resizes = true;
          animate_mouse_windowdragging = true;

          allow_session_lock_restore = true;

          initial_workspace_tracking = 1;

          vrr = 3;
        };
      };
    };
  }
