# Modal keymaps, entered from ./binds.nix. Every submap leaves on Escape or
# Return, and a trailing catch-all resets on any other key so it can never
# trap the keyboard.
{ lib, ... }:
let
  inherit (import ./lib.nix { inherit lib; })
    bind
    bindWith
    forDirections
    ;

  step = 20;
  repeating = {
    repeating = true;
  };

  leave = [
    (bind "escape" "hl.dsp.submap('reset')")
    (bind "Return" "hl.dsp.submap('reset')")
    (bind "catchall" "hl.dsp.submap('reset')")
  ];
in
{
  wayland.windowManager.hyprland.submaps = {
    # Resize the active window; SHIFT moves a floating one instead.
    resize.settings.bind =
      forDirections (
        d: key:
        bindWith key
          "hl.dsp.window.resize({x = ${toString (d.x * step)}, y = ${toString (d.y * step)}, relative = true})"
          repeating
      )
      ++ forDirections (
        d: key:
        bindWith "SHIFT + ${key}"
          "hl.dsp.window.move({x = ${toString (d.x * step)}, y = ${toString (d.y * step)}, relative = true})"
          repeating
      )
      ++ leave;

    # Tabbed groups: G toggles, a direction joins the neighbouring group,
    # SHIFT+direction leaves it, Tab cycles and X locks.
    group.settings.bind = [
      (bind "g" "hl.dsp.group.toggle()")
      (bind "Tab" "hl.dsp.group.next()")
      (bind "SHIFT + Tab" "hl.dsp.group.prev()")
      (bind "x" "hl.dsp.group.lock_active({action = 'toggle'})")
    ]
    ++ forDirections (d: key: bind key "hl.dsp.window.move({into_group = '${d.dir}'})")
    ++ forDirections (d: key: bind "SHIFT + ${key}" "hl.dsp.window.move({out_of_group = '${d.dir}'})")
    ++ leave;

    # One-shot window and layout actions; the submap closes after each.
    window = {
      onDispatch = "reset";
      settings.bind = [
        (bind "c" "hl.dsp.window.center()")
        (bind "s" "hl.dsp.layout('togglesplit')")
        (bind "p" "hl.dsp.window.pseudo()")
        (bind "o" "hl.dsp.window.set_prop({prop = 'opaque', value = 'toggle'})")
      ]
      ++ leave;
    };
  };
}
