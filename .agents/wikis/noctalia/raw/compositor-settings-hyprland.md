# Hyprland compositor settings for Noctalia v5+

Source: <https://docs.noctalia.dev/noctalia/compositor-settings/hyprland/>

<!-- Verbatim upstream page: long code lines and site anchors are kept as-is. -->
<!-- markdownlint-disable MD001 MD013 MD025 MD051 -->

Retrieved: 2026-10-02

Add the following settings to your Hyprland Lua configuration file (usually
found at `~/.config/hypr/hyprland.lua`).

## Autostart Noctalia

Add this to your `hyprland.start` event hook:

```text
hl.on("hyprland.start", function()
  hl.exec_cmd("noctalia")
end)
```

## Compositor Settings

Add the following to your existing `hl.config({})` block. These settings are for
general window appearance and functionality.

```text
hl.config({
  general = {
    gaps_in = 5,
    gaps_out = 10,
  },


  decoration = {
    rounding = 20,
    rounding_power = 2,


    shadow = {
      enabled = true,
      range = 4,
      render_power = 3,
      color = 0xee1a1a1a,
    },


    blur = {
      enabled = true,
      size = 3,
      passes = 2,
      vibrancy = 0.1696,
    },
  },
})
```

## Persistent Workspaces

For the best workspace indicator behavior, make your regular Hyprland workspaces
persistent. This keeps empty workspaces visible in Noctalia instead of only
showing workspaces that currently contain windows.

Update the monitor name and workspace list to match your setup. You can find
more syntax and examples in the official [Workspace
Rules](https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/)
documentation.

```text
hl.workspace_rule({ workspace = "1", monitor = "DP-1", persistent = true, default_name = "web" })
hl.workspace_rule({ workspace = "2", monitor = "DP-1", persistent = true, default_name = "code" })
hl.workspace_rule({ workspace = "3", monitor = "DP-1", persistent = true, default_name = "chat" })
hl.workspace_rule({ workspace = "4", monitor = "DP-1", persistent = true, default_name = "game" })
hl.workspace_rule({ workspace = "5", monitor = "DP-1", persistent = true, default_name = "design" })
```

## IPC Keybinds

Add these binds to your `hyprland.lua`:

```text
local mainMod = "SUPER"
local ipc = "noctalia msg "


-- Core binds
hl.bind(mainMod .. "+Space", hl.dsp.exec_cmd(ipc .. "panel-toggle launcher"))
hl.bind(mainMod .. "+S", hl.dsp.exec_cmd(ipc .. "panel-toggle control-center"))
hl.bind(mainMod .. "+comma", hl.dsp.exec_cmd(ipc .. "settings-toggle"))
hl.bind("ALT + Tab", hl.dsp.exec_cmd(ipc .. "window-switcher hold"))


-- Media keys
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd(ipc .. "volume-up"))
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd(ipc .. "volume-down"))
hl.bind("XF86AudioMute", hl.dsp.exec_cmd(ipc .. "volume-mute"))
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd(ipc .. "brightness-up"))
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(ipc .. "brightness-down"))


-- Noctalia Settings
hl.window_rule({
    match = { class = "dev.noctalia.Noctalia" },
    float = true,
    size = { 1080, 920 },
})
```

## Blur

Enable blur for Noctalia’s bar, panels, dock, and notifications. We also disable
Hyprland’s built-in layer animations for Noctalia so they do not interfere with
Noctalia’s own animations.

![Blurred Noctalia surfaces](/_astro/hyprland-blur-1-v5.BXqZqPGZ_XSCXA.webp)

```text
hl.layer_rule({
  name = "noctalia",
  match = {
    namespace = "^noctalia-(bar-.+|notification|dock|panel|attached-panel|osd|window-switcher)$",
  },
  no_anim = true,
  ignore_alpha = 0.5,
  blur = true,
  blur_popups = true,
})
```
