{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.desktop;
in
  with lib; {
    imports = [
      ./window-managers
    ];

    options.desktop = {
      enable = mkEnableOption "Desktop environment support (core deps, XDG, portals)";

      sessionVariables = mkOption {
        type = with types; attrsOf str;
        default = {};
        description = "Session-wide environment variables for the desktop session.";
        example = {
          TERMINAL = "ghostty";
          BROWSER = "zen-twilight";
          FILE_BROWSER = "nautilus";
        };
      };

      xdg = {
        mimeApps = mkOption {
          type = types.bool;
          default = true;
          description = "Whether to enable XDG MIME application defaults for desktop environments.";
        };

        autostart = mkOption {
          type = with types;
            listOf (submodule {
              options = {
                name = mkOption {
                  type = str;
                  description = "Name of the autostart entry.";
                };
                command = mkOption {
                  type = str;
                  description = "Command to execute on desktop start.";
                };
                delay = mkOption {
                  type = nullOr str;
                  default = null;
                  description = "Delay before running (e.g. '5s' or a systemd timer expression).";
                };
                condition = mkOption {
                  type = nullOr str;
                  default = null;
                  description = "Condition for autostart (e.g. 'hyprland' to only run under Hyprland).";
                };
              };
            });
          default = [];
          description = "List of applications to autostart on desktop login.";
        };
      };
    };

    config = mkIf cfg.enable {
      # Core desktop packages that any graphical environment needs
      home.packages = with pkgs; [
        glib # GSettings schema tools
        shared-mime-info
        xdg-user-dirs
      ];

      # Ensure XDG user dirs are created
      xdg.userDirs = {
        enable = true;
        createDirectories = true;
      };

      # Set session variables with sensible defaults
      home.sessionVariables =
        {
          TERMINAL = mkDefault "ghostty";
          BROWSER = mkDefault "firefox";
          FILE_BROWSER = mkDefault "nautilus";
        }
        // cfg.sessionVariables;

      # XDG MIME apps
      xdg.mimeApps.enable = mkIf cfg.xdg.mimeApps true;
    };
  }
