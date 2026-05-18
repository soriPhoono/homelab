# Homes Directory

This directory contains Home Manager user configurations. The flake evaluates these directories using a naming convention that determines whether a configuration is exported as a standalone Home Manager environment or integrated into a NixOS system.

## Naming Convention

| Pattern | Export Behavior | Use Case |
| :--- | :--- | :--- |
| `user` | Exported as `homeConfigurations.<user>` | Standalone Home Manager base configuration |
| `user@hostname` where hostname exists in `nix/systems/` | **Not** exported standalone | System-bound overrides, imported by the NixOS config via `core.users` |
| `user@standalone-name` where name is **not** in `nix/systems/` | Exported as `homeConfigurations.<user@standalone-name>` | Standalone Home Manager with a specific profile name |

### How Layering Works

When the flake builds a `homeConfiguration`, it composes modules in this order:

1. **Shared Home Manager modules**: sops-nix, stylix, noctalia, and the flake's `homeModules.default`
1. **Base arguments**: `username`, `homeDirectory`, `lib`
1. **Base configuration** (`nix/homes/<user>/default.nix`) — if it exists
1. **Host/standalone overrides** (`nix/homes/<user>@<name>/default.nix`) — if it exists

Later layers can override earlier values via `lib.mkForce` or standard NixOS option precedence rules. This allows sharing common user configuration in the base directory while keeping machine-specific settings in the override directory.

### Meta Support

Home directories may include a `meta.json` file to override build parameters:

```json
{
  "system": "x86_64-linux"
}
```

Supported fields:

- `system` — Target architecture for the Home Manager build (default: `x86_64-linux`)

Meta is read from the host-specific directory first, then the base directory, with fallback to defaults.

## Adding a New Home Configuration

### For a NixOS System User

1. Create base config: `nix/homes/<user>/default.nix`
1. Create host-specific config: `nix/homes/<user>@<hostname>/default.nix`
1. Add user definition to `core.users.<user>` in `nix/systems/<hostname>/default.nix`
1. The system will automatically import the home configuration — no manual import needed

### For a Standalone Home Manager User

1. Create the directory: `nix/homes/<user>/`
1. Create `nix/homes/<user>/default.nix`
1. Deploy with: `nh home switch .#<user>`

If you need different profiles for different standalone machines, create `nix/homes/<user>@<profile-name>/` where `<profile-name>` does **not** match any directory in `nix/systems/`.

## Current Configurations

### sphoono (`nix/homes/sphoono/`)

Base user configuration for the primary operator (soriphoono).

- **Git**: Identity configured as `soriphoono`
- **Email**: Primary account `soriphoono@gmail.com`
- **Secrets**: sops-nix integration
- **Theme**: Catppuccin Macchiato via Stylix (dark polarity, Papirus icons, custom fonts)
- **Configs**: Agent context, MCP server definitions, Hyprland overrides, Zed editor preferences, Zen Browser configuration, Noctalia shell settings, Helix editor config

### sphoono@zephyrus (`nix/homes/sphoono@zephyrus/`)

Zephyrus-specific overrides for the sphoono user. Deployed automatically via `nh os switch .#zephyrus`.

- **Shell**: Git/docker aliases, Starship prompt, Fastfetch
- **Display**: Hyprland monitor configuration (1920×1080 @ 144Hz, 1.25× scale), ASUS ROG key bindings
- **User Applications**: Full suite — Zen Browser, communication apps (Discord, Telegram, Signal, Matrix), office (LibreOffice, Zathura, Slack), development tools (Zed, Ghostty), media tools, content creation, data fortress apps

### spookyskelly (`nix/homes/spookyskelly/`)

Base user configuration for the secondary operator.

- **Secrets**: sops-nix integration
- **Zen Browser**: Configuration present

### spookyskelly@lg-laptop (`nix/homes/spookyskelly@lg-laptop/`)

LG-laptop-specific overrides for the spookyskelly user. Deployed automatically via `nh os switch .#lg-laptop`.

- **Shell**: Starship prompt, Fastfetch
- **User Applications**: Browsers (Firefox, Zen), communication (Discord, Telegram, Signal, Matrix), office (LibreOffice, OnlyOffice), data fortress apps (Nextcloud, Bitwarden, Obsidian), content creation (GIMP, Blender, Krita, Audacity, Kdenlive, OBS Studio)
