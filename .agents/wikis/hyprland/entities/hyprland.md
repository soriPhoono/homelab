# Hyprland

Hyprland is a dynamic tiling Wayland compositor, configured in Lua
(`hyprland.lua`) or in the older hyprlang (`hyprland.conf`).

## In this repo

- Version: 0.56.2 (nixpkgs pin at the time of writing).
- NixOS: `den.aspects.desktop.managers.hyprland` enables
  `programs.hyprland` with `withUWSM = true`.
- Home Manager: `den.aspects.sphoono.desktop.wm.hypr` writes the user config
  with `configType = "lua"`. That is already the default for
  `home.stateVersion` 26.05 and later, but it is set explicitly. HM reuses the
  NixOS module's `package` and `portalPackage`. Setting `portalPackage = null`
  would make HM set `xdg.portal.enable = false` and drop xdph from the user
  portal set.
- Lua API stubs ship with the package at `share/hypr/stubs/hl.meta.lua`.

## Related

- [Lua config](../concepts/lua-config.md)
