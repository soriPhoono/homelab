{
  lib,
  config,
  ...
}: let
  cfg = config.desktop.window-managers.hyprland;
in
  with lib; {
    options.desktop.window-managers.hyprland.animations = {
      curves = mkOption {
        type = with types;
          attrsOf (submodule {
            options = {
              type = mkOption {
                type = str;
                description = ''
                  Type of curve to create
                '';
                default = "bezier";
              };
              # See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Animations/
              x1 = mkOption {
                type = float;
              };
              x2 = mkOption {
                type = float;
              };
              y1 = mkOption {
                type = float;
              };
              y2 = mkOption {
                type = float;
              };
            };
          });
      };

      registry = mkOption {
        type = with types;
          attrsOf (submodule {
            options = {
              style = mkOption {
                type = str;
                default = "";
                description = ''
                  The style of this animation
                '';
              };

              speed = mkOption {
                type = int;
                description = ''
                  The speed of this animation
                '';
              };

              curve = {
                type = mkOption {
                  type = str;
                  description = ''
                    The curve type to use
                  '';
                };
                name = mkOption {
                  type = str;
                  description = ''
                    The name of the curve to use from registered curves of the given type
                  '';
                };
              };
            };
          });
      };
    };

    config = mkIf cfg.enable (mkMerge [
      {
        wayland.windowManager.hyprland.settings = {
          animation =
            mapAttrsToList (name: animation: {
              enabled = true;
              leaf = name;
              inherit (animation) speed style;
              ${animation.curve.type} = animation.curve.name;
            })
            cfg.animations.registry;

          curve =
            mapAttrsToList (
              name: curve: {
                _args = [
                  name
                  {
                    inherit (curve) type;
                    points = [
                      [
                        curve.x1
                        curve.y1
                      ]
                      [
                        curve.x2
                        curve.y2
                      ]
                    ];
                  }
                ];
              }
            )
            cfg.animations.curves;
        };
      }
    ]);
  }
