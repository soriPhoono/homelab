# Compositor settings carried over from v1. Colours are left to the Stylix
# hyprland target, which writes into the same `config` table.
_: {
  wayland.windowManager.hyprland.settings = {
    config = {
      general = {
        layout = "dwindle";
        border_size = 3;
        gaps_in = 4;
        gaps_out = 8;
        float_gaps = 8;
        resize_on_border = true;
        resize_corner = 2;
        snap.enabled = true;
      };

      # The window submap's split toggle only works with preserved splits.
      dwindle.preserve_split = true;

      decoration = {
        rounding = 10;
        active_opacity = 0.9;
        inactive_opacity = 0.9;
        shadow.sharp = true;
      };

      binds = {
        hide_special_on_workspace_change = true;
        workspace_center_on = 1;
        drag_threshold = 10;
      };

      input = {
        kb_layout = "us";
        repeat_rate = 30;
        repeat_delay = 200;
        accel_profile = "flat";
        touchpad = {
          natural_scroll = true;
          tap_to_click = true;
          clickfinger_behavior = true;
        };
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
        disable_splash_rendering = true;
        mouse_move_enables_dpms = true;
        key_press_enables_dpms = true;
        animate_manual_resizes = true;
        animate_mouse_windowdragging = true;
        allow_session_lock_restore = true;
        initial_workspace_tracking = 1;
        vrr = 3;
      };
    };

    gesture = [
      {
        fingers = 3;
        direction = "horizontal";
        action = "workspace";
      }
      {
        fingers = 3;
        direction = "up";
        action = "special";
        workspace_name = "scratchpad";
      }
    ];
  };
}
