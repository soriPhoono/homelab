# Modules Directory

This directory contains reusable NixOS and Home Manager modules that compose to form complete system and user configurations.

## Structure

```
modules/
├── nixos/          # System-level modules (NixOS)
│   ├── core/       #   Base system: hardware, networking, boot, users, secrets, security, nix config
│   ├── desktop/    #   Desktop environments: window managers, display managers, services, tools
│   ├── hosting/    #   Self-hosted services: Caddy proxy, media stack, dashboard
│   └── themes/     #   System-wide theming via Stylix
└── home/           # User-level modules (Home Manager)
    ├── core/       #   Base user environment: shells, apps, email, SSH, secrets
    └── userapps/   #   User applications: desktop, development, data-fortress, content-creation
```

## NixOS Modules

Modules are gated behind enable-style options. They are designed to be composable — enabling a module imports all its sub-modules and activates the necessary system services.

| Module Group | Namespace | Description |
| :--- | :--- | :--- |
| **core** | `core.*` | Foundational system layer. Hardware abstraction (CPU/GPU/HID/Bluetooth/ADB), networking (NetworkManager, OpenSSH, Tailscale), bootloader (systemd-boot), users, secrets, Nix daemon config, security hardening, ClamAV antivirus, GitOps deployment |
| **desktop** | `desktop.*` | Desktop environment stack (gated by `desktop.enable`). Display managers (SDDM, greetd), window managers (Hyprland), desktop environments (KDE Plasma, COSMIC), gaming, printing, PipeWire, Flatpak, Docker, VirtualBox, ASUS daemon |
| **hosting** | `hosting.*` | Self-hosted services. Caddy reverse proxy with declarative DNS routes, media stack (Jellyfin, \*arr suite, FlareSolverr, qBittorrent), Homepage dashboard |
| **themes** | `themes.*` | Stylix integration with base16 scheme selection |

## Home Manager Modules

| Module Group | Namespace | Description |
| :--- | :--- | :--- |
| **core** | `core.*` | Base user environment. Shells (Bash, Fish, Starship, Fastfetch), apps (Git, Yazi), email accounts, SSH key management, sops-nix secrets, GitOps timers |
| **userapps** | `userapps.*` | User-facing applications organized by category. Desktop apps (browsers, communication, office, media), development tools (editors, AI agents, terminals, MCP servers), data fortress (Bitwarden, Nextcloud, Obsidian), content creation (Blender, GIMP, Kdenlive, OBS Studio) |

## Usage

Modules are automatically exported via the flake's `nixosModules` and `homeModules` outputs. They can be imported in configurations like:

```nix
{
  core.hardware.gpu.amd.enable = true;
  desktop.environments.managers.hyprland.enable = true;
  hosting.media.enable = true;
  themes.base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-macchiato.yaml";
}
```

### Auto-Discovery

No manual `imports` registration is required. The `lib.homelab.core.discover` function automatically scans the module directories and imports any `.nix` file or directory containing a `default.nix`. Adding a new module file to any subdirectory is sufficient to make it available.
