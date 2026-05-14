{
  inputs,
  lib,
  pkgs,
  config,
  nixosConfig ? null,
  ...
}: let
  cfg = config.personal.hyprland;
in
  with lib; {
    imports = [
      ./binds.nix
      ./theme.nix
    ];

    options.personal.hyprland = {
      enable = mkEnableOption "Enable Hyprland configuration";

      monitors = mkOption {
        type = with types;
          listOf (submodule {
            options = {
              name = mkOption {
                type = str;
                description = "The name of the monitor in both hyprland and noctalia shell";
              };

              primary = mkEnableOption "Set this monitor as the primary monitor for displaying notifications and osd in noctalia shell";

              modeline = mkOption {
                type = submodule {
                  options = {
                    width = mkOption {
                      type = int;
                      description = "The width of the monitor in pixels";
                    };

                    height = mkOption {
                      type = int;
                      description = "The height of the monitor in pixels";
                    };

                    refreshRate = mkOption {
                      type = int;
                      description = "The refresh rate of the monitor in Hz";
                    };
                  };
                };
              };

              position = mkOption {
                type = submodule {
                  options = {
                    x = mkOption {
                      type = int;
                      description = "The x position of the monitor in pixels";
                    };

                    y = mkOption {
                      type = int;
                      description = "The y position of the monitor in pixels";
                    };
                  };
                };
              };

              scale = mkOption {
                type = float;
                description = "The scale factor of the monitor (e.g. 1 for 100%, 2 for 200%)";
              };
            };
          });
      };

      extraSettings = mkOption {
        type = with types; attrs;
        default = {};
        description = "Additional settings for Hyprland";
      };
    };

    config = mkIf cfg.enable {
      personal.noctalia = {
        enable = true;
        monitors = mkDefault (map (monitor: monitor.name) (filter (monitor: monitor.primary) cfg.monitors));
      }; # TODO: Add monitor configuration for each monitor, or expose this better for system to system differences

      wayland.windowManager.hyprland = let
        hyprland = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system};
      in {
        enable = true;

        package =
          if nixosConfig != null
          then hyprland.hyprland
          else null;
        portalPackage =
          if nixosConfig != null
          then hyprland.xdg-desktop-portal-hyprland
          else null;

        settings =
          {
            monitor =
              map (monitor: {
                output = monitor.name;
                mode = "${toString monitor.modeline.width}x${toString monitor.modeline.height}@${toString monitor.modeline.refreshRate}";
                position = "${toString monitor.position.x}x${toString monitor.position.y}";
                inherit (monitor) scale;
              })
              cfg.monitors;

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

            config = {
              general = {
                border_size = 3;
                gaps_in = 4;
                gaps_out = 8;
                float_gaps = 8;

                snap.enabled = true;
              };

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
                repeat_rate = 30;
                repeat_delay = 200;

                accel_profile = "flat";
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

                mouse_move_enables_dpms = true;
                key_press_enables_dpms = true;

                animate_manual_resizes = true;
                animate_mouse_windowdragging = true;

                allow_session_lock_restore = true;

                initial_workspace_tracking = 1;

                vrr = 3;
              };
            };
          }
          // cfg.extraSettings;
      };
    };
  }
