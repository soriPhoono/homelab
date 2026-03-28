{
  lib,
  config,
  ...
}: let
  cfg = config.desktop.hyprland.default;
in
  with lib; {
    imports = [
      ./kitty.nix
    ];

    config = mkIf cfg.enable {
      wayland.windowManager.hyprland.settings.bind = builtins.concatLists (builtins.genList (
          i: let
            ws = toString (i + 1);
          in [
            "SUPER, ${toString ws}, workspace, ${toString ws}"
            "SUPER SHIFT, ${toString ws}, movetoworkspace, ${toString ws}"
          ]
        )
        9);
    };
  }
