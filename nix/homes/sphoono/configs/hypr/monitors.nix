{
  lib,
  config,
  ...
}: let
  cfg = config.personal.hyprland;
in
  with lib; {
    config = mkIf cfg.enable {
      wayland.windowManager.hyprland.settings.monitor =
        map (monitor: {
          output = monitor.name;
          mode = "${toString monitor.modeline.width}x${toString monitor.modeline.height}@${toString monitor.modeline.refreshRate}";
          position = "${toString monitor.position.x}x${toString monitor.position.y}";
          inherit (monitor) scale;
        })
        cfg.monitors;
    };
  }
