# Global keybinds. Hyprland owns its keymap; only the noctalia shell adds its
# own binds, from its aspect. Modal actions live in ./submaps.nix.
{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (import ./lib.nix { inherit lib; })
    bind
    bindWith
    exec
    forDirections
    ;

  uwsm = lib.getExe pkgs.uwsm;
  app = command: exec "${uwsm} app -- ${command}";
  terminal = lib.getExe config.programs.ghostty.package;

  # SUPER+1..9 map to workspaces 1..9 and SUPER+0 to workspace 10.
  workspaces = map (n: {
    key = toString (lib.mod n 10);
    ws = toString n;
  }) (lib.range 1 10);
in
{
  wayland.windowManager.hyprland.settings.bind = [
    # -- Window state --
    (bind "SUPER + Q" "hl.dsp.window.close()")
    (bind "SUPER + T" "hl.dsp.window.float()")
    (bind "SUPER + SHIFT + T" "hl.dsp.window.fullscreen()")
    (bind "SUPER + P" "hl.dsp.window.pin()")

    # -- Submaps (./submaps.nix) --
    (bind "SUPER + R" "hl.dsp.submap('resize')")
    (bind "SUPER + G" "hl.dsp.submap('group')")
    (bind "SUPER + W" "hl.dsp.submap('window')")

    # -- Scratchpad --
    (bind "SUPER + grave" "hl.dsp.workspace.toggle_special('scratchpad')")
    (bind "SUPER + SHIFT + grave" "hl.dsp.window.move({workspace = 'special:scratchpad'})")

    # -- Workspace cycling --
    (bind "SUPER + mouse_down" "hl.dsp.focus({workspace = 'e+1'})")
    (bind "SUPER + mouse_up" "hl.dsp.focus({workspace = 'e-1'})")

    # -- Mouse move and resize --
    (bindWith "SUPER + mouse:272" "hl.dsp.window.drag()" { mouse = true; })
    (bindWith "SUPER + mouse:273" "hl.dsp.window.resize()" { mouse = true; })

    # -- Applications --
    (bind "SUPER + Return" (app terminal))
    (bind "SUPER + E" (app "${terminal} -e ${lib.getExe config.programs.yazi.package}"))
    (bind "SUPER + C" (app "${terminal} -e nvim"))

    # -- Session --
    (bind "SUPER + SHIFT + Escape" (exec "${uwsm} stop"))
  ]
  # The browser module only exists when sphoono.desktop is included.
  ++ lib.optional (config.programs ? zen-browser) (
    bind "SUPER + B" (app (lib.getExe config.programs.zen-browser.package))
  )
  # -- Focus and swap, on both vim keys and arrows --
  ++ forDirections (d: key: bind "SUPER + ${key}" "hl.dsp.focus({direction = '${d.dir}'})")
  ++ forDirections (
    d: key: bind "SUPER + SHIFT + ${key}" "hl.dsp.window.swap({direction = '${d.dir}'})"
  )
  # -- Workspaces: switch, move and follow, move silently --
  ++ lib.concatMap (w: [
    (bind "SUPER + ${w.key}" "hl.dsp.focus({workspace = '${w.ws}'})")
    (bind "SUPER + SHIFT + ${w.key}" "hl.dsp.window.move({workspace = '${w.ws}', follow = true})")
    (bind "SUPER + CTRL + ${w.key}" "hl.dsp.window.move({workspace = '${w.ws}', follow = false})")
  ]) workspaces;
}
