{
  lib,
  config,
  ...
}: let
  hyprCfg = config.desktop.window-managers.hyprland;
in
  with lib; {
    config = mkIf hyprCfg.enable {
      desktop.window-managers.hyprland.animations = {
        curves = {
          overshot = {
            x1 = 0.05;
            y1 = 0.9;

            x2 = 0.1;
            y2 = 1.05;
          };
          smoothOut = {
            x1 = 0.5;
            y1 = 0.0;

            x2 = 0.99;
            y2 = 0.99;
          };
          smoothIn = {
            x1 = 0.5;
            y1 = -0.5;

            x2 = 0.68;
            y2 = 1.5;
          };
          default = {
            x1 = 0.0;
            y1 = 0.0;

            x2 = 1.0;
            y2 = 1.0;
          };
        };
        registry = {
          windows = {
            speed = 4;
            style = "slide";
            curve = {
              name = "overshot";
              type = "bezier";
            };
          };
          windowsOut = {
            speed = 4;
            curve = {
              name = "smoothOut";
              type = "bezier";
            };
          };
          windowsIn = {
            speed = 4;
            curve = {
              name = "smoothOut";
              type = "bezier";
            };
          };
          windowsMove = {
            speed = 4;
            style = "slide";
            curve = {
              name = "smoothIn";
              type = "bezier";
            };
          };
          border = {
            speed = 5;
            curve = {
              name = "smoothIn";
              type = "bezier";
            };
          };
          fade = {
            speed = 5;
            curve = {
              name = "smoothIn";
              type = "bezier";
            };
          };
          fadeDim = {
            speed = 5;
            curve = {
              name = "smoothIn";
              type = "bezier";
            };
          };
          workspaces = {
            speed = 3;
            curve = {
              name = "overshot";
              type = "bezier";
            };
          };
        };
      };
    };
  }
