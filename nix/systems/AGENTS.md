# System Configurations

This directory contains top-level NixOS host configurations. Each subdirectory represents a physical or virtual machine and serves as the root module for that host's complete system state.

## Architecture

### Builder Pattern

The flake constructs NixOS configurations via the `mkSystem` function defined in `flake.nix`:

```
mkSystem = hostName: lib.nixosSystem {
  modules = nixosModules ++ [
    { networking.hostName = hostName; home-manager = { ... }; }
    ./nix/systems/${hostName}
  ];
};
```

Each host directory is imported as a module into the `lib.nixosSystem` evaluation, composing:

1. **External input modules**: disko, sops-nix, stylix, jovian, comin, hyprland, nix-index-database, home-manager, nixos-facter, determinate
1. **Internal module exports**: `self.nixosModules.default` (aggregates `core`, `desktop`, `hosting`, `themes`)
1. **Host-specific configuration**: The host directory's `default.nix`

### Home Manager Integration

System configurations integrate Home Manager via `home-manager.nixosModules.home-manager` with:

- `sharedModules` — All Home Manager modules from `self.homeModules.default`
- `useGlobalPkgs = true` — Shares the NixOS package set
- `useUserPackages = true` — Evaluates `home.packages` within the NixOS context
- `backupFileExtension = "bak"` — Preserves existing config files with `.bak` suffix

User configurations for system-bound users are defined in `nix/homes/user@hostname/` and imported automatically via the `core.users` module.

### Hardware Facts

Hardware specifications are captured via `nixos-facter` and stored as `facter.json` in each host directory. The `core.hardware.reportPath` option points to this file, enabling the `nixos-facter-modules` to generate accurate hardware-specific configuration.

**To regenerate hardware facts:**

```bash
nixos-facter > nix/systems/<hostname>/facter.json
```

### Disk Provisioning

Declarative disk layouts are defined in `disko.nix` within each host directory. The `disko` module consumes these definitions to partition and format storage devices during initial deployment or disk reconfiguration.

## Host Configurations

### zephyrus

Primary development workstation. ASUS ROG Zephyrus G14 (`GA401QM`).

**Configuration highlights:**

- Dual GPU: AMD iGPU + NVIDIA RTX 3060 (laptop mode)
- Hyprland Wayland compositor with SDDM (sddm-astronaut, jake_the_dog theme)
- Full media stack with Caddy reverse proxy on `cryptic-coders.net`
- Docker, VirtualBox, gaming profile with console support
- ASUS daemon for laptop-specific controls
- Tailscale Serve with pinned origin
- User: `sphoono` (admin, fish shell)

**Hardware facts:** [`facter.json`](zephyrus/facter.json)

### lg-laptop

Secondary workstation. LG laptop with Intel Arc GPU.

**Configuration highlights:**

- Intel Arc GPU (device ID `a7a0`)
- KDE Plasma desktop
- Media stack with Caddy reverse proxy on `cryptic-coders.net`
- Gaming profile, printing, tablet HID support
- Tailscale Serve with pinned origin
- User: `spookyskelly` (admin, fish shell)

**Hardware facts:** [`facter.json`](lg-laptop/facter.json)

## Adding a New Host

1. Create a directory: `nix/systems/<hostname>/`
1. Generate hardware facts: `nixos-facter > nix/systems/<hostname>/facter.json`
1. Create `default.nix` with host configuration
1. Create `disko.nix` with disk layout definition
1. Define users via `core.users.<username>`
1. Enable required modules: `core`, `desktop`, `hosting`, `themes`
1. Create corresponding `nix/homes/<username>@<hostname>/` for user overrides

The flake automatically discovers and exports any directory in `nix/systems/` containing a `default.nix` as a `nixosConfiguration`.

## meta.json Support

Host directories may include a `meta.json` file to override default build parameters:

```json
{
  "system": "x86_64-linux"
}
```

Supported fields:

- `system` — Target architecture (default: `x86_64-linux`)
