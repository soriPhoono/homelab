{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.desktop.environments.uwsm;
in
  with lib; {
    options.desktop.environments.uwsm = {
      enable = mkEnableOption "Enable uwsm";

      environments = mkOption {
        type = with types;
          attrsOf (submodule {
            options = {
              name = mkOption {
                type = str;
                description = "Renderable name of this desktop environment";
                example = "Hyprland";
              };
              description = mkOption {
                type = str;
                description = "Renderable description of this desktop environment";
                example = "A tiling window manager with pretty animations";
              };
              execPath = mkOption {
                type = path;
                description = "Final executable path of the compositor's executable";
                example = "${pkgs.hyprland}/bin/Hyprland";
              };
              extraArgs = mkOption {
                type = listOf str;
                default = [];
                description = "Extra program arguments to pass to the compositor's executable";
                example = ["--config=~/.config/hypr/hyprland.conf"];
              };
            };
          });
        default = {};
        description = "Attribute set of wayland compositors to be integrated with uwsm";
        example = {
          hyprland = {
            name = "Hyprland";
            description = "A tiling window manager with pretty animations";
            execPath = "${pkgs.hyprland}/bin/Hyprland";
          };
        };
      };
    };

    config = mkIf cfg.enable {
      desktop = {
        enable = true;
      };

      programs.uwsm = {
        enable = true;
        waylandCompositors =
          lib.mapAttrs (_name: value: {
            prettyName = value.name;
            comment = value.description;
            binPath = value.execPath;
          })
          cfg.environments;
      };
    };
  }
