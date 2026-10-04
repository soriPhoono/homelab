# Stylix palette mapping

The Stylix `noctalia` target turns the base16 scheme into a noctalia custom
palette named `stylix`, and switches noctalia's theme to it.

## What the target writes

Source:
`/nix/store/hpim3alj3lwyr5indz2lirg2l842za8m-source/modules/noctalia/hm.nix`.

- `customPalettes.stylix.dark`: Material-style roles from base16. `mPrimary`
  is `base0D`, `mSecondary` `base0E`, `mTertiary` `base0C`, `mError`
  `base08`, `mSurface` `base00`, `mOnSurface` `base05`, and so on, plus a
  terminal palette.
- `settings.theme`: `source = "custom"`, `custom_palette = "stylix"`, and
  `mode` from polarity.
- `settings.shell.font_family`: Stylix's `sansSerif` font.
- `dock`, `notification` and `osd` `background_opacity`: from Stylix opacity.
- `settings.wallpaper.default.path`: from `stylix.image`, if one is set.

See [palette](../raw/theming-palette.md) for the palette file format.

## The polarity trap

The target only writes a `dark` palette variant, but sets `theme.mode` to
`"light"` for any polarity other than `"dark"`. That includes the default
`"either"`. Noctalia then looks for a light variant that does not exist.

`stylix.polarity` is unset in this repo, so the noctalia aspect sets
`stylix.targets.noctalia.polarity.override = "dark"`. That is a per-target
override and leaves global polarity, and every other target, alone.

## Do not double-set

Because the target owns `theme.*`, `shell.font_family` and those opacities,
the aspect must not set them itself or the definitions conflict. Noctalia's
own app templates are turned off (`theme.templates.*`), so Stylix stays the
only theming source for other applications.
