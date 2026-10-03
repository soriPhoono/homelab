# Lua config

How Hyprland's Lua configuration is written through Home Manager, and the
call shapes used for binds, submaps and gestures.

## Home Manager rendering

Source:
`/nix/store/da7apr6rx9mpa0ljpircmwwsxnmrjb43-source/modules/services/window-managers/hyprland/lib.nix`.

- Each `settings.<name>` becomes `hl.<name>(...)`. A list value gives one call
  per element, and lists from several modules concatenate.
- `{ _args = [ a b ]; }` renders as a multi-argument call, `hl.bind(a, b)`.
- `lib.generators.mkLuaInline "..."` passes raw Lua, used for dispatchers.
- `settings.config` is the `hl.config({...})` table. The Stylix hyprland
  target writes its colours there, so it merges with ours.
- `submaps.<name>.settings.bind` renders inside
  `hl.define_submap(name, [onDispatch,] function() ... end)`. Hyprlang
  strings are skipped in Lua mode.

## Call shapes

From [dispatchers](../raw/dispatchers.md), [submaps](../raw/submaps.md),
[gestures](../raw/gestures.md), [mouse binds](../raw/mouse-binds.md) and
[dwindle](../raw/dwindle-layout.md):

```lua
hl.bind("SUPER + h", hl.dsp.focus({ direction = "l" }))
hl.bind("SUPER + SHIFT + 1",
  hl.dsp.window.move({ workspace = "1", follow = true }))
hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind("SUPER + R", hl.dsp.submap("resize"))
hl.define_submap("resize", function()
  hl.bind("l", hl.dsp.window.resize({ x = 20, y = 0, relative = true }),
    { repeating = true })
  hl.bind("catchall", hl.dsp.submap("reset"))
end)
hl.gesture({ fingers = 3, direction = "up", action = "special",
  workspace_name = "scratchpad" })
```

- `toggle_special("name")` takes a bare name, while `window.move` needs
  `special:name`.
- `hl.dsp.layout("togglesplit")` requires `dwindle.preserve_split = true`.
- A dispatcher must be passed to `hl.bind`, or wrapped in `hl.dispatch()`
  inside a function. Calling it on its own does nothing.

## Verifying

`Hyprland --verify-config --config <file>` loads the Lua without starting the
compositor. It reports unknown config keys and calls to nonexistent dispatchers.
Dispatcher argument tables are only checked when the bind fires. To check the
generated file, render `xdg.configFile."hypr/hyprland.lua".text` and verify
that.
