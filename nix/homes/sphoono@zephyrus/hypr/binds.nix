{config, ...}: {
  config = {
    wayland.windowManager.hyprland.settings = {
      bind =
        [
          "SUPER, Q, killactive, "

          "SUPER, grave, togglespecialworkspace, scratchpad"
          "SUPER SHIFT, grave, movetoworkspace, special:scratchpad"

          "SUPER, F, togglefloating, "
          "SUPER CTRL, F, fullscreen, 0"

          "SUPER, Return, exec, ${config.programs.ghostty.package}/bin/ghostty"
          "SUPER, E, exec, ${config.programs.ghostty.package}/bin/ghostty -e ${config.programs.yazi.package}/bin/yazi"

          "SUPER, B, exec, uwsm app -s a google-chrome"
          "SUPER, C, exec, uwsm app -s a antigravity"
        ]
        ++ (builtins.concatLists (builtins.genList (
            i: let
              ws = toString (i + 1);
            in [
              "SUPER, ${toString ws}, workspace, ${toString ws}"
              "SUPER SHIFT, ${toString ws}, movetoworkspace, ${toString ws}"
            ]
          )
          9));

      bindm = [
        "ALT, mouse:272, movewindow"
        "SUPER, Control_L, movewindow"
        "ALT, mouse:273, resizewindow"
        "SUPER, ALT_L, resizewindow"
      ];

      bindc = [
        "ALT, mouse:272, togglefloating"
      ];
    };
  };
}
