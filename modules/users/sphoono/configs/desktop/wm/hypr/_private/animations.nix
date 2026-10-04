# Bezier curves and animation leaves carried over from v1.
{ lib, ... }:
let
  curve = name: x1: y1: x2: y2: {
    _args = [
      name
      {
        type = "bezier";
        points = [
          [
            x1
            y1
          ]
          [
            x2
            y2
          ]
        ];
      }
    ];
  };

  animation = leaf: bezier: speed: style: {
    inherit
      leaf
      bezier
      speed
      style
      ;
    enabled = true;
  };
in
{
  wayland.windowManager.hyprland.settings = {
    curve = [
      (curve "default" 0.0 0.0 1.0 1.0)
      (curve "overshot" 0.05 0.9 0.1 1.05)
      (curve "smoothIn" 0.5 (-0.5) 0.68 1.5)
      (curve "smoothOut" 0.5 0.0 0.99 0.99)
    ];

    animation = lib.mapAttrsToList (leaf: a: animation leaf a.bezier a.speed a.style) {
      border = {
        bezier = "smoothIn";
        speed = 5;
        style = "";
      };
      fade = {
        bezier = "smoothIn";
        speed = 5;
        style = "";
      };
      fadeDim = {
        bezier = "smoothIn";
        speed = 5;
        style = "";
      };
      windows = {
        bezier = "overshot";
        speed = 4;
        style = "slide";
      };
      windowsIn = {
        bezier = "smoothOut";
        speed = 4;
        style = "";
      };
      windowsMove = {
        bezier = "smoothIn";
        speed = 4;
        style = "slide";
      };
      windowsOut = {
        bezier = "smoothOut";
        speed = 4;
        style = "";
      };
      workspaces = {
        bezier = "overshot";
        speed = 3;
        style = "";
      };
    };
  };
}
