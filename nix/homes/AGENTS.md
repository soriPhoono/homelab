# Home Configurations

This directory contains Home Manager user configurations. The flake evaluates these directories using a naming convention that determines whether a configuration is exported as standalone or integrated into a NixOS system.

## Architecture

### Builder Pattern

The `mkHome` function in `flake.nix` constructs Home Manager configurations:

```
mkHome = username: homeName: inputs.home-manager.lib.homeManagerConfiguration {
  modules = homeManagerModules ++ [
    { home = { inherit username; homeDirectory = ...; }; }
  ]
  ++ lib.optional hasBase (./nix/homes/${username}/default.nix)
  ++ lib.optional hasHome (./nix/homes/${username}@${homeName}/default.nix);
};
```

### Naming Convention and Export Rules

The flake applies a single-pass evaluation of `nix/homes/` directory entries:

| Pattern | Export Behavior | Use Case |
| :--- | :--- | :--- |
| `user` | Not exported standalone | Base configuration layer, shared across all deployments |
| `user@home-name` | Exported as `homeConfigurations.user@home-name` | Standalone Home Manager (hostname not in `nix/systems/`) |
| `user@hostname` | **Not** exported standalone | System-bound overrides, imported by NixOS config via `core.users` |

**Key distinction:** A `user@hostname` directory is only exported as a standalone `homeConfiguration` if `hostname` does **not** exist in `nix/systems/` or equals `droid`. Otherwise, it is consumed by the NixOS system configuration and deployed via `nh os switch`.

### Configuration Layering

When both a base directory (`user/`) and a host-specific directory (`user@hostname/`) exist, their modules are composed in order:

1. **Shared Home Manager modules**: sops-nix, stylix, noctalia, and the flake's own `homeModules.default`
1. **Base arguments**: `username`, `homeDirectory`, `_module.args.lib`
1. **Base configuration**: `nix/homes/user/default.nix`
1. **Host-specific overrides**: `nix/homes/user@hostname/default.nix`

Later layers can override earlier values via `lib.mkForce` or standard NixOS option precedence rules.

### meta.json Support

Home directories may include a `meta.json` file to override build parameters:

```json
{
  "system": "x86_64-linux"
}
```

Supported fields:

- `system` — Target architecture for the Home Manager build (default: `x86_64-linux`)

Meta is read from the host-specific directory first, then the base directory, with fallback to defaults.

## Current Configurations

### sphoono

Base user configuration for the primary operator.

**Contents:**

- Git identity (soriphoono), email (soriphoono@gmail.com)
- sops-nix secret integration
- Theme configuration
- Hyprland configuration
- Zen Browser configuration
- Zed editor configuration
- Agent context, MCP server definitions, and skill configurations

### sphoono@zephyrus

Zephyrus-specific overrides for the sphoono user. Deployed as part of the `zephyrus` NixOS configuration.

**Contents:**

- Git aliases, docker/lazygit shell aliases
- Starship prompt and Fastfetch configuration
- Hyprland monitor-specific settings and keybind configurations
- User application enablement

### spookyskelly

Base user configuration for the secondary operator.

**Contents:**

- sops-nix secret integration
- Zen Browser configuration

### spookyskelly@lg-laptop

LG-laptop-specific overrides for the spookyskelly user. Deployed as part of the `lg-laptop` NixOS configuration.

**Contents:**

- Starship prompt and Fastfetch configuration
- Full user application suite activation

## Adding a User Configuration

### For a NixOS System User

1. Create base config: `nix/homes/user/default.nix` (if not exists)
1. Create host-specific config: `nix/homes/user@hostname/`
1. Add user definition to `core.users.user` in `nix/systems/<hostname>/default.nix`
1. The system will automatically import the home configuration

### For a Standalone Home Manager User

1. Create base config: `nix/homes/user/default.nix` (if not exists)
1. Create standalone config: `nix/homes/user@home-name/` where `home-name` is **not** a directory in `nix/systems/`
1. Deploy with: `nh home switch .#user@home-name`

## Secrets

User-level secrets are managed via sops-nix. Each user directory may contain a `secrets.yml` file with encrypted secrets. Decryption is performed using age keys associated with the user.
