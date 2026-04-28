# Implementation Plan: Zephyrus System Security Hardening

## Objective

Implement strict security hardening measures for the Zephyrus system, addressing points 2-5 from the recent security audit. This includes restricting privilege escalation, enforcing strict firewall isolation on specific interfaces, verifying secret integrity, and applying strict systemd sandboxing to media services.

## Key Files & Context

- `nix/modules/nixos/core/security.nix` (new file)
- `nix/modules/nixos/core/default.nix`
- `nix/modules/nixos/desktop/features/gaming.nix`
- `nix/modules/nixos/desktop/features/printing.nix`
- `nix/modules/nixos/core/networking/tailscale.nix`
- `nix/modules/nixos/hosting/media/qbittorrent.nix`
- `nix/modules/nixos/hosting/media/jellyfin.nix`
- `nix/modules/nixos/hosting/media/*.nix` (Radarr, Sonarr, Prowlarr, etc.)

## Implementation Steps

### 1. Privilege Escalation (Sudo) Hardening (Item 2)

- **Action**: Create `nix/modules/nixos/core/security.nix`.
- **Details**: Configure `security.sudo` with `execWheelOnly = true` and `extraConfig` to enforce a 15-minute timestamp timeout and always require a lecture.
- **Action**: Import `security.nix` in `nix/modules/nixos/core/default.nix`.

### 2. Networking and Firewall Isolation (Item 3)

- **Action**: Audit and modify `gaming.nix`, `printing.nix`, `tailscale.nix`, and `qbittorrent.nix`.
- **Details**:
  - Remove `openFirewall = true` globally.
  - Explicitly open required ports (e.g., 8080 for qBittorrent, 631 for CUPS, Steam/LAN play ports) exclusively on the `tailscale0` interface or specific trusted LAN interfaces via `networking.firewall.interfaces."<interface>".allowedTCPPorts` and `allowedUDPPorts`.

### 3. Secret Management Integrity (Item 4)

- **Action**: Verification complete.
- **Details**: The audit confirmed that `caddy.nix` correctly uses SOPS templates (`config.sops.templates`). No plain-text secrets were found in the `hosting/` modules. No file modifications are required for this item.

### 4. Service Sandboxing (Item 5)

- **Action**: Update all service modules in `nix/modules/nixos/hosting/media/*.nix`.
- **Details**: Inject `systemd.services.<service_name>.serviceConfig` to include:
  - `ProtectSystem = "strict"`
  - `ProtectHome = true`
  - `PrivateDevices = true`
  - *Crucial Addition*: Add `ReadWritePaths = [ "/mnt/local/media" ]` to ensure the media services can still read and write to the external media mount, circumventing the strict read-only OS protection.

## Verification & Testing

1. **Evaluation**: Run `nh os switch .` or `nixos-rebuild dry-activate` to verify the Nix evaluation is successful.
1. **Sudo**: Run a sudo command to verify the lecture triggers and test the 15-minute timeout.
1. **Firewall**: Use `nft list ruleset` or `iptables -L` to confirm the ports are no longer open globally but are restricted to `tailscale0` and the LAN.
1. **Sandboxing**: Check `systemctl status qbittorrent` and `jellyfin` to ensure they start without permission errors, and verify they can write files to `/mnt/local/media`.
