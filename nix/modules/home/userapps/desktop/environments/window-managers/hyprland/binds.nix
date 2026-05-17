{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.userapps.desktop.environments.window-managers.hyprland;
  wmCfg = config.userapps.desktop.environments.window-managers;
in
  with lib; {
    config = mkIf cfg.enable {
      wayland.windowManager.hyprland.settings = {
        bind =
          [
            # ── Window Control ──────────────────────────────────────────
            {
              _args = [
                "${wmCfg.common.mod} + Q"
                (lib.generators.mkLuaInline "hl.dsp.window.close()")
              ];
            }
            {
              _args = [
                "${wmCfg.common.mod} + T"
                (lib.generators.mkLuaInline "hl.dsp.window.float()")
              ];
            }
            {
              _args = [
                "${wmCfg.common.mod} + SHIFT + T"
                (lib.generators.mkLuaInline "hl.dsp.window.fullscreen()")
              ];
            }

            # ── Scratchpad / Special Workspace ─────────────────────────
            {
              _args = [
                "${wmCfg.common.mod} + grave"
                (lib.generators.mkLuaInline "hl.dsp.workspace.toggle_special('scratchpad')")
              ];
            }
            {
              _args = [
                "${wmCfg.common.mod} + SHIFT + grave"
                (lib.generators.mkLuaInline "hl.dsp.window.move({workspace = 'special:scratchpad'})")
              ];
            }

            # ── Screenshots ────────────────────────────────────────────
            {
              _args = [
                "Print"
                (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"${pkgs.grimblast}/bin/grimblast --notify copy output\")")
              ];
            }
            {
              _args = [
                "${wmCfg.common.mod} + Print"
                (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"${pkgs.grimblast}/bin/grimblast --notify copy area\")")
              ];
            }
            {
              _args = [
                "${wmCfg.common.mod} + SHIFT + Print"
                (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"${pkgs.grimblast}/bin/grimblast --notify copy active\")")
              ];
            }

            # ── Focus Navigation ───────────────────────────────────────
            {
              _args = [
                "${wmCfg.common.mod} + left"
                (lib.generators.mkLuaInline "hl.dsp.focus({direction = 'l'})")
              ];
            }
            {
              _args = [
                "${wmCfg.common.mod} + right"
                (lib.generators.mkLuaInline "hl.dsp.focus({direction = 'r'})")
              ];
            }
            {
              _args = [
                "${wmCfg.common.mod} + up"
                (lib.generators.mkLuaInline "hl.dsp.focus({direction = 'u'})")
              ];
            }
            {
              _args = [
                "${wmCfg.common.mod} + down"
                (lib.generators.mkLuaInline "hl.dsp.focus({direction = 'd'})")
              ];
            }

            # ── Window Swapping ────────────────────────────────────────
            {
              _args = [
                "${wmCfg.common.mod} + SHIFT + left"
                (lib.generators.mkLuaInline "hl.dsp.window.swap({direction = 'l'})")
              ];
            }
            {
              _args = [
                "${wmCfg.common.mod} + SHIFT + right"
                (lib.generators.mkLuaInline "hl.dsp.window.swap({direction = 'r'})")
              ];
            }
            {
              _args = [
                "${wmCfg.common.mod} + SHIFT + up"
                (lib.generators.mkLuaInline "hl.dsp.window.swap({direction = 'u'})")
              ];
            }
            {
              _args = [
                "${wmCfg.common.mod} + SHIFT + down"
                (lib.generators.mkLuaInline "hl.dsp.window.swap({direction = 'd'})")
              ];
            }

            # ── Launch Shortcuts ───────────────────────────────────────
            {
              _args = [
                "${wmCfg.common.mod} + Return"
                (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"${pkgs.run-application}/bin/run-application ${config.home.sessionVariables.TERMINAL}\")")
              ];
            }
            {
              _args = [
                "${wmCfg.common.mod} + E"
                (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"${pkgs.run-application}/bin/run-application ${config.home.sessionVariables.FILE_BROWSER}\")")
              ];
            }
            {
              _args = [
                "${wmCfg.common.mod} + B"
                (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"${pkgs.run-application}/bin/run-application ${config.home.sessionVariables.BROWSER}\")")
              ];
            }

            # ── Mouse Binds ────────────────────────────────────────────
            {
              _args = [
                "${wmCfg.common.mod} + Control_L"
                (lib.generators.mkLuaInline "hl.dsp.window.drag()")
                {mouse = true;}
              ];
            }
            {
              _args = [
                "${wmCfg.common.mod} + ALT_L"
                (lib.generators.mkLuaInline "hl.dsp.window.resize()")
                {mouse = true;}
              ];
            }
          ]
          # ── Workspace Switcher (works 1-9) ─────────────────────────
          ++ (builtins.concatLists (
            builtins.genList (
              i: let
                ws = toString (i + 1);
              in [
                {
                  _args = [
                    "${wmCfg.common.mod} + ${ws}"
                    (lib.generators.mkLuaInline "hl.dsp.focus({workspace = '${ws}'})")
                  ];
                }
                {
                  _args = [
                    "${wmCfg.common.mod} + SHIFT + ${ws}"
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
