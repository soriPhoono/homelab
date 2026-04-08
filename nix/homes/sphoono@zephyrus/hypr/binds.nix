{
  pkgs,
  config,
  ...
}: {
  config = {
    wayland.windowManager.hyprland.settings = {
      bind =
        [
          # Window Control
          "SUPER, Q, killactive"

          "SUPER, T, togglefloating"
          "SUPER SHIFT, T, fullscreen, 0"

          "SUPER, G, togglegroup"
          "SUPER SHIFT, G, moveoutofgroup"

          # Scratching
          "SUPER, grave, togglespecialworkspace, scratchpad"
          "SUPER SHIFT, grave, movetoworkspace, special:scratchpad"

          # Screenshots using grimblast
          ", Print, exec, ${pkgs.grimblast}/bin/grimblast --notify copy output"
          "SUPER, Print, exec, ${pkgs.grimblast}/bin/grimblast --notify copy area"
          "SUPER SHIFT, Print, exec, ${pkgs.grimblast}/bin/grimblast --notify copy active"

          # Focus navigation with arrows
          "SUPER, left, movefocus, l"
          "SUPER, right, movefocus, r"
          "SUPER, up, movefocus, u"
          "SUPER, down, movefocus, d"

          "SUPER SHIFT, left, swapwindow, l"
          "SUPER SHIFT, right, swapwindow, r"
          "SUPER SHIFT, up, swapwindow, u"
          "SUPER SHIFT, down, swapwindow, d"

          "SUPER, Return, exec, ${config.home.sessionVariables.TERMINAL}"
          "SUPER, E, exec, ${config.home.sessionVariables.FILE_BROWSER}"
          "SUPER, B, exec, ${config.home.sessionVariables.BROWSER}"
        ]
        ++ (builtins.concatLists (
          builtins.genList (
            i: let
              ws = toString (i + 1);
            in [
              "SUPER, ${toString ws}, workspace, ${toString ws}"
              "SUPER SHIFT, ${toString ws}, movetoworkspace, ${toString ws}"
            ]
          )
          9
        ));

      binde = [
        # Keyboard Brightness
        ", XF86KbdBrightnessDown, exec, ${pkgs.brightnessctl}/bin/brightnessctl -d asus::kbd_backlight set 33%-"
        ", XF86KbdBrightnessUp, exec, ${pkgs.brightnessctl}/bin/brightnessctl -d asus::kbd_backlight set 33%+"
      ];

      bindm = [
        "SUPER, Control_L, movewindow"
        "SUPER, ALT_L, resizewindow"
      ];
    };
  };
}
