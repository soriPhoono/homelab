{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.personal.hyprland;
in
  with lib; {
    config = mkIf cfg.enable {
      wayland.windowManager.hyprland.settings = {
        bind =
          [
            # Window Control
            {
              _args = [
                "SUPER + Q"
                (lib.generators.mkLuaInline "hl.dsp.window.close()")
              ];
            }

            {
              _args = [
                "SUPER + T"
                (lib.generators.mkLuaInline "hl.dsp.window.float()")
              ];
            }
            {
              _args = [
                "SUPER + SHIFT + T"
                (lib.generators.mkLuaInline "hl.dsp.window.fullscreen()")
              ];
            }

            # Scratching
            {
              _args = [
                "SUPER + grave"
                (lib.generators.mkLuaInline "hl.dsp.workspace.toggle_special('scratchpad')")
              ];
            }
            {
              _args = [
                "SUPER + SHIFT + grave"
                (lib.generators.mkLuaInline "hl.dsp.window.move({workspace = 'special:scratchpad'})")
              ];
            }

            # Screenshots using grimblast
            {
              _args = [
                "Print"
                (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"${pkgs.grimblast}/bin/grimblast --notify copy output\")")
              ];
            }
            {
              _args = [
                "SUPER + Print"
                (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"${pkgs.grimblast}/bin/grimblast --notify copy area\")")
              ];
            }
            {
              _args = [
                "SUPER + SHIFT + Print"
                (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"${pkgs.grimblast}/bin/grimblast --notify copy active\")")
              ];
            }

            # Focus navigation with arrows
            {
              _args = [
                "SUPER + left"
                (lib.generators.mkLuaInline "hl.dsp.focus({direction = 'l'})")
              ];
            }
            {
              _args = [
                "SUPER + right"
                (lib.generators.mkLuaInline "hl.dsp.focus({direction = 'r'})")
              ];
            }
            {
              _args = [
                "SUPER + up"
                (lib.generators.mkLuaInline "hl.dsp.focus({direction = 'u'})")
              ];
            }
            {
              _args = [
                "SUPER + down"
                (lib.generators.mkLuaInline "hl.dsp.focus({direction = 'd'})")
              ];
            }

            {
              _args = [
                "SUPER + SHIFT + left"
                (lib.generators.mkLuaInline "hl.dsp.window.swap({direction = 'l'})")
              ];
            }
            {
              _args = [
                "SUPER + SHIFT + right"
                (lib.generators.mkLuaInline "hl.dsp.window.swap({direction = 'r'})")
              ];
            }
            {
              _args = [
                "SUPER + SHIFT + up"
                (lib.generators.mkLuaInline "hl.dsp.window.swap({direction = 'u'})")
              ];
            }
            {
              _args = [
                "SUPER + SHIFT + down"
                (lib.generators.mkLuaInline "hl.dsp.window.swap({direction = 'd'})")
              ];
            }

            {
              _args = [
                "SUPER + Return"
                (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"${pkgs.runapp}/bin/runapp -- ${config.home.sessionVariables.TERMINAL}\")")
              ];
            }
            {
              _args = [
                "SUPER + E"
                (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"${pkgs.runapp}/bin/runapp -- ${config.home.sessionVariables.FILE_BROWSER}\")")
              ];
            }
            {
              _args = [
                "SUPER + B"
                (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"${pkgs.runapp}/bin/runapp -- ${config.home.sessionVariables.BROWSER}\")")
              ];
            }

            # Mouse binds
            {
              _args = [
                "SUPER + Control_L"
                (lib.generators.mkLuaInline "hl.dsp.window.drag()")
                {mouse = true;}
              ];
            }
            {
              _args = [
                "SUPER + ALT_L"
                (lib.generators.mkLuaInline "hl.dsp.window.resize()")
                {mouse = true;}
              ];
            }
          ]
          ++ (builtins.concatLists (
            builtins.genList (
              i: let
                ws = toString (i + 1);
              in [
                {
                  _args = [
                    "SUPER + ${ws}"
                    (lib.generators.mkLuaInline "hl.dsp.focus({workspace = '${ws}'})")
                  ];
                }
                {
                  _args = [
                    "SUPER + SHIFT + ${ws}"
                    (lib.generators.mkLuaInline "hl.dsp.window.move({workspace = '${ws}'})")
                  ];
                }
              ]
            )
            9
          ));
      };
    };
  }
