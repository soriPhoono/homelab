# Implementation Plan: Fix Media Services File System Permissions

## Background & Motivation

The Jellyfin service was failing to start because it was configured with `ProtectSystem = "strict"`, which mounts the entire filesystem as read-only for the service. Without explicitly declaring `StateDirectory` and `CacheDirectory`, Jellyfin could not write to its necessary configuration and state files in `/var/lib` and `/var/cache`. While investigating and fixing Jellyfin, it was discovered that `qbittorrent`, `radarr`, and `sonarr` also use `ProtectSystem = "strict"` without these declarations, which will lead to similar write failures when they attempt to save state or configuration.

## Scope & Impact

This plan will update the NixOS module definitions for `qbittorrent`, `radarr`, and `sonarr` to explicitly declare their `StateDirectory` in their respective `systemd.services.<name>.serviceConfig` blocks. This ensures they function correctly under the strict protection mode by whitelisting their `/var/lib/<name>` directories for write access.

## Proposed Solution

Modify the following files to include `StateDirectory = "<service_name>";` within their `serviceConfig`:

### 1. `nix/modules/nixos/hosting/media/qbittorrent.nix`

Add `StateDirectory = "qbittorrent";` to `systemd.services.qbittorrent.serviceConfig`.

### 2. `nix/modules/nixos/hosting/media/radarr.nix`

Add `StateDirectory = "radarr";` to `systemd.services.radarr.serviceConfig`.

### 3. `nix/modules/nixos/hosting/media/sonarr.nix`

Add `StateDirectory = "sonarr";` to `systemd.services.sonarr.serviceConfig`.

## Verification

1. Rebuild the system configuration using the standard deployment method (e.g., `nh os switch`).
1. Verify that the services (`qbittorrent`, `radarr`, `sonarr`) start successfully without `Read-only file system` errors by checking their status and logs (`systemctl status <service>` and `journalctl -u <service> -b`).
