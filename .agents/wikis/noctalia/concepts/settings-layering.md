# Settings layering

Noctalia merges a declarative config layer with a GUI-owned override layer, so
a read-only Nix config and settings changed in the GUI can coexist.

## Load order

From [configuration](../raw/configuration.md), later layers win:

1. Built-in defaults.
2. Every `*.toml` in `~/.config/noctalia/`, sorted, with `[include]` files
   merged first under each file.
3. `~/.local/state/noctalia/settings.toml`, written by the GUI and by IPC
   actions that persist.

When the GUI writes a value equal to the lower layers, noctalia drops the
redundant key instead of keeping an override.

## How this repo uses it

- Home Manager writes `programs.noctalia.settings` to
  `~/.config/noctalia/config.toml` as a read-only store symlink. That is the
  curated base.
- Personal or experimental values stay in the GUI layer and out of git, for
  example the weather location and the wallpaper choice.
- Workflow: prototype a change in the GUI, then copy it from
  `noctalia config export` into the aspect, then delete the matching
  override from `settings.toml`.
- If a Nix value seems to be ignored, a stale GUI override in `settings.toml`
  is the usual cause.

## Validation

With `checkConfig` (default on), the HM module runs
`noctalia config validate` on the generated file at build time. Unknown keys
are only warnings and still pass, so after porting settings, read the build log
or run the validator by hand to catch renamed keys. The v1 to v5 port renamed,
for example, `centered` panel placement to `floating`, and idle behaviours now
use `action = "lock"` rather than `command = "noctalia:session lock"`.
