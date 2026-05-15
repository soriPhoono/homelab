{
  lib,
  config,
  ...
}: let
  cfg = config.personal.hyprland;
in
  with lib; {
    config = mkIf cfg.enable {
      wayland.windowManager.hyprland.settings = {
        curve = [
          {
            _args = [
              "overshot"
              {
                type = "bezier";
                points = [
                  [
                    0.05
                    0.9
                  ]
                  [
                    0.1
                    1.05
                  ]
                ];
              }
            ];
          }
          {
            _args = [
              "smoothOut"
              {
                type = "bezier";
                points = [
                  [
                    0.5
                    0
                  ]
                  [
                    0.99
                    0.99
                  ]
                ];
              }
            ];
          }
          {
            _args = [
              "smoothIn"
              {
                type = "bezier";
                points = [
                  [
                    0.5
                    (-0.5)
                  ]
                  [
                    0.68
                    1.5
                  ]
                ];
              }
            ];
          }
        ];

        animation = [
          {
            leaf = "windows";
            enabled = true;
            speed = 5;
            bezier = "overshot";
            style = "slide";
          }
          {
            leaf = "windowsOut";
            enabled = true;
            speed = 3;
            bezier = "smoothOut";
          }
          {
            leaf = "windowsIn";
            enabled = true;
            speed = 3;
            bezier = "smoothOut";
          }
          {
            leaf = "windowsMove";
            enabled = true;
            speed = 4;
            bezier = "smoothIn";
            style = "slide";
          }
          {
            leaf = "border";
            enabled = true;
            speed = 5;
            bezier = "default";
          }
          {
            leaf = "fade";
            enabled = true;
            speed = 5;
            bezier = "smoothIn";
          }
          {
            leaf = "fadeDim";
            enabled = true;
            speed = 5;
            bezier = "smoothIn";
          }
          {
            leaf = "workspaces";
            enabled = true;
            speed = 6;
            bezier = "default";
          }
        ];
      };
    };
  }
