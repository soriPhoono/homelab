{
  lib,
  config,
  ...
}: let
  cfg = config.userapps.desktop.environments.window-managers.hyprland;
in
  with lib; {
    imports = [
      ./binds.nix
      ./monitors.nix
      ./theme.nix
      ./shells
    ];

    options.userapps.desktop.environments.window-managers.hyprland = {
      enable = mkEnableOption "Hyprland Wayland compositor configuration";

      package = mkOption {
        type = with types; nullOr package;
        default = null;
        description = "Hyprland package to use. Auto-resolves from flake input when null and run under NixOS.";
      };

      portalPackage = mkOption {
        type = with types; nullOr package;
        default = null;
        description = "XDG Desktop Portal Hyprland package. Auto-resolves from flake input when null.";
      };

      monitors = mkOption {
        type = with types;
          listOf (submodule {
            options = {
              name = mkOption {
                type = str;
                description = "Display connector name (e.g. eDP-1, HDMI-A-1).";
              };

              primary = mkEnableOption "Mark this monitor as primary";

              modeline = mkOption {
                type = submodule {
                  options = {
                    width = mkOption {
                      type = int;
                      description = "Horizontal resolution in pixels.";
                    };
                    height = mkOption {
                      type = int;
                      description = "Vertical resolution in pixels.";
                    };
                    refreshRate = mkOption {
                      type = int;
                      description = "Refresh rate in Hz.";
                    };
                  };
                };
              };

              position = mkOption {
                type = submodule {
                  options = {
                    x = mkOption {
                      type = int;
                      default = 0;
                      description = "Horizontal position.";
                    };
                    y = mkOption {
                      type = int;
                      default = 0;
                      description = "Vertical position.";
                    };
                  };
                };
              };

              scale = mkOption {
                type = float;
                default = 1.0;
                description = "Display scale factor (1.0 = 100%).";
              };
            };
          });
        default = [];
        description = "Monitor configuration list.";
      };

      settings = mkOption {
        type = with types; attrs;
        default = {};
        description = "Additional raw Hyprland settings merged into the config block.";
      };

      extraConfig = mkOption {
        type = with types; nullOr str;
        default = null;
        description = "Extra raw Hyprland config appended to the generated config file.";
      };
    };

    config = mkIf cfg.enable (mkMerge [
      {
        wayland.windowManager.hyprland = {
          enable = true;
          systemdIntegration = true;
          xwayland = {
            enable = true;
            forceZeroScaling = true;
          };

          settings =
            {
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
            // cfg.settings;
        };
      }
      (mkIf (cfg.package != null) {
        wayland.windowManager.hyprland.package = cfg.package;
      })
      (mkIf (cfg.portalPackage != null) {
        wayland.windowManager.hyprland.portalPackage = cfg.portalPackage;
      })
      (mkIf (cfg.extraConfig != null) {
        wayland.windowManager.hyprland.extraConfig = cfg.extraConfig;
      })
    ]);
  }
