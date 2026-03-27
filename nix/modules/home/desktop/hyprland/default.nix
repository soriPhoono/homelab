{
  lib,
  config,
  nixosConfig,
  ...
}: let
  cfg = config.desktop.hyprland;
in
  with lib; {
    imports = [
      ./default
    ];

    options.desktop.hyprland = {
      enable = mkEnableOption "Enable hyprland desktop environment.";

      hotkeys = mkOption {
        type = with types;
          attrsOf (submodule {
            options = {
              type = mkOption {
                type = enum ["bind"];
                default = "bind";
                description = "Kind of hyprland keybinding to set for this hotkey";
              };

              mods = mkOption {
                type = listOf (enum ["SUPER" "SHIFT"]);
                default = [];
                description = "The modifiers to press along with the hotkey to trigger the keybinding";
              };

              trigger = mkOption {
                type = str;
                default = null;
                description = "The keybinding to trigger the hotkey when pressed in conjunction with the modifier keys";
              };

              executor = mkOption {
                type = nullOr (enum ["exec" "workspace"]);
                default = null;
                description = "The dispatcher in hyprland to execute the command with (if any)";
              };

              command = mkOption {
                type = str;
                default = null;
                description = "The command to execute on keybind activation";
              };
            };
          });
        default = {};
        description = "Hyprland hotkeys for launching programs from keybinds";
      };
    };

    config = mkIf cfg.enable {
      xdg.configFile."uwsm/env".source = mkIf (nixosConfig != null && nixosConfig.programs.hyprland.withUWSM) "${config.home.sessionVariablesPackage}/etc/profile.d/hm-session-vars.sh";

      wayland.windowManager.hyprland = {
        enable = true;
        settings = {
          bind =
            mapAttrsToList
            (_: binding: "${concatStringsSep " " binding.mods}, ${binding.trigger}, ${binding.executor}, ${binding.command}")
            (filterAttrs (_: binding: binding.type == "bind") cfg.hotkeys);
        };
      };
    };
  }
