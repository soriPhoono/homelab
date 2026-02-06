{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.desktop.environments.hyprland;
in
  with lib; {
    imports = [
      ./default
    ];

    options.desktop.environments.hyprland = {
      enable = mkEnableOption "Enable hyprland core config, ENABLE THIS OPTION IN YOUR CONFIG";

      custom = mkEnableOption "Enable recognition for custom hyprland configurations, ENABLE THIS OPTION IN YOUR CONFIG";

      components = mkOption {
        type = with types;
          listOf (submodule {
            options = {
              name = mkOption {
                type = str;
                description = "Name of the component";
              };
              command = mkOption {
                type = str;
                description = "Command to execute";
              };
              type = mkOption {
                type = enum ["app" "service"];
                default = "app";
                description = "UWSM execution type";
              };
              background = mkOption {
                type = bool;
                default = false;
                description = "Whether to start in background";
              };
              reloadBehavior = mkOption {
                type = enum ["ignore" "restart"];
                default = "ignore";
                description = "Whether to restart the component on configuration reload. 'ignore' uses exec-once, 'restart' uses exec.";
              };
            };
          });
        default = [];
        description = "Extra components to start with the Hyprland session via UWSM";
      };

      binds = mkOption {
        type = with types;
          listOf (submodule {
            options = {
              mods = mkOption {
                type = listOf str;
                default = ["$mod"];
                description = "Modifier keys for the bind";
              };
              key = mkOption {
                type = nullOr str;
                default = null;
                description = "The key to bind";
              };
              dispatcher = mkOption {
                type = nullOr str;
                default = null;
                description = "Hyprland dispatcher to call";
              };
              params = mkOption {
                type = nullOr str;
                default = null;
                description = "Parameters for the dispatcher";
              };
              type = mkOption {
                type = enum ["bind" "binde" "bindm" "bindl" "bindle" "bindi" "bindt"];
                default = "bind";
                description = "Hyprland bind type";
              };
              description = mkOption {
                type = nullOr str;
                default = null;
                description = "Description of what this bind does";
              };
            };
          });
        default = [];
        description = "Structured list of keybindings for Hyprland";
      };

      mod = mkOption {
        type = types.str;
        default = "SUPER";
        description = "The modifier key to use for Hyprland bindings";
      };
    };

    config = mkIf cfg.enable {
      desktop.environments.enable = true;

      wayland.windowManager.hyprland = {
        enable = true;
        settings = let
          # Helper to format a component for uwsm
          mkUWSMApp = c:
            "${pkgs.uwsm}/bin/uwsm app "
            + (
              if c.type == "service"
              then "-t service "
              else ""
            )
            + (
              if c.background
              then "-s b "
              else ""
            )
            + "-- ${c.command}";

          # Split components based on reload behavior
          execOnceComponents = filter (c: c.reloadBehavior == "ignore") cfg.components;
          execComponents = filter (c: c.reloadBehavior == "restart") cfg.components;

          # Format binds into attribute sets per type
          groupedBinds = foldl' (acc: bind: let
            bindStr = "${
              if bind.mods != null
              then concatStringsSep " " bind.mods
              else " "
            }, ${bind.key}, ${bind.dispatcher}${
              if bind.params != null
              then ", ${bind.params}"
              else ""
            }";
          in
            acc // {${bind.type} = (acc.${bind.type} or []) ++ [bindStr];}) {}
          cfg.binds;
        in
          {
            "$mod" = cfg.mod;
            exec-once = map mkUWSMApp execOnceComponents;
            exec = map mkUWSMApp execComponents;
          }
          // groupedBinds;
      };
    };
  }
