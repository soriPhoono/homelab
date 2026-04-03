# TODO: Add binds for core hyprland features and other user applications.
{
  config,
  nixosConfig,
  ...
}: {
  config = {
    wayland.windowManager.hyprland.settings = let
      launcherPrefix =
        if (nixosConfig != null && nixosConfig.programs.hyprland.withUWSM)
        then "uwsm app -s a "
        else "";
    in {
      bind =
        [
          "SUPER, Q, killactive, "

          "SUPER, grave, togglespecialworkspace, scratchpad"
          "SUPER SHIFT, grave, movetoworkspace, special:scratchpad"

          "SUPER, F, togglefloating, "
          "SUPER CTRL, F, fullscreen, 0"

          "SUPER, Return, exec, ${launcherPrefix}-T"
          "SUPER, E, exec, ${launcherPrefix}-T ${config.programs.yazi.package}/bin/yazi"

          "SUPER, B, exec, ${launcherPrefix}google-chrome"
          "SUPER, C, exec, ${launcherPrefix}antigravity"
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
