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
      ./animations.nix
      ./autostart.nix
      ./binds.nix
      ./monitors.nix
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

      autostart = mkOption {
        type = with types; listOf str;
        default = [];
        description = "Commands to run on Hyprland startup via exec-once (set per-system)";
      };
    };

    config = mkIf cfg.enable {
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
