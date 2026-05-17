# Systems Directory

This directory contains the top-level NixOS configurations for all physical machines managed by this flake. Each subdirectory represents a machine and serves as the root module for that host's complete system state.

## Adding a New System

1. Create a new directory: `nix/systems/<hostname>`
1. Generate hardware facts: `nixos-facter > nix/systems/<hostname>/facter.json`
1. Create a `default.nix` file with the host configuration
1. Create a `disko.nix` file with the disk layout definition (required for initial provisioning)
1. Create a `meta.json` file to declare the target architecture

### `meta.json` Format

```json
{
  "system": "x86_64-linux"
}
```

Supported fields:

- `system` — Target architecture (default: `x86_64-linux`)

## Discovery

The flake automatically discovers any directory in `nix/systems/` that contains a `default.nix` file and creates a `nixosConfiguration` for it with the same name as the directory.

## Current Systems

### zephyrus

Primary development workstation. ASUS ROG Zephyrus G14 (`GA401QM`).

- **Dual GPU**: AMD Radeon iGPU + NVIDIA RTX 3060 (laptop mode)
- **Desktop**: Hyprland Wayland compositor with SDDM (sddm-astronaut, jake_the_dog theme)
- **Services**: Media stack (Jellyfin, \*arr suite) with Caddy reverse proxy on `cryptic-coders.net`, Homepage dashboard
- **Laptop**: ASUS daemon for hardware controls
- **Tools**: Docker, VirtualBox, gaming profile with console support
- **Networking**: Tailscale Serve with pinned origin
- **Theme**: Catppuccin Macchiato via Stylix
- **User**: `sphoono` (admin, fish shell)
- **Disk**: Declarative partitioning via [`disko.nix`](zephyrus/disko.nix)
- **Hardware facts**: [`facter.json`](zephyrus/facter.json)
- **Secrets**: [`secrets.yml`](zephyrus/secrets.yml)

### lg-laptop

Secondary workstation. LG laptop with Intel Arc GPU.

- **GPU**: Intel Arc (device ID `a7a0`)
- **Desktop**: KDE Plasma
- **Services**: Media stack (Jellyfin, \*arr suite) with Caddy reverse proxy on `cryptic-coders.net`, Homepage dashboard
- **Features**: Gaming profile, printing, tablet HID support
- **Networking**: Tailscale Serve with pinned origin
- **User**: `spookyskelly` (admin, fish shell)
- **Disk**: Declarative partitioning via [`disko.nix`](lg-laptop/disko.nix)
- **Hardware facts**: [`facter.json`](lg-laptop/facter.json)
- **Secrets**: [`secrets.yml`](lg-laptop/secrets.yml)
