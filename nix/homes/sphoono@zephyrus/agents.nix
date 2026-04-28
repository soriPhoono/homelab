{
  userapps.development.agents.context = {
    system = ''
      # System Environment: Zephyrus

      ## Hardware Specifications
      - **Device**: ASUS ROG Zephyrus G14 (GA401QM)
      - **CPU**: AMD Ryzen 9 5900HS (8 Cores, 16 Threads)
      - **RAM**: 16GB DDR4-3200 (Micron Technology)
      - **Graphics**:
        - Integrated: AMD Radeon Graphics
        - Dedicated: NVIDIA GeForce RTX 3060 (Laptop mode enabled)
      - **Storage**: mass storage controller via NVMe SSD
      - **Networking**: MediaTek MT7921 (Wireless), Integrated Bluetooth
      - **Peripherals**:
        - Goodix Fingerprint Sensor
        - Xbox Controller support enabled
        - Logitech device support (via Solaar/Logitech module)

      ## Operating System & Core Config
      - **OS**: NixOS (x86_64-linux)
      - **Nix Configuration**:
        - Experimental features: `nix-command`, `flakes`
        - Package management: `nh` (Nix Helper) enabled with daily automatic cleaning (keep 3 days/3 versions).
        - Substituters: nix-community, numtide, and determinate-systems caches enabled.
        - Build configuration: `cores` limited to 4 to prevent OOM during heavy compilations.
        - Security: `nix-ld` enabled for running non-nix binaries; ClamAV integration available.
      - **Boot & Console**:
        - Bootloader: Systemd-boot with Plymouth splash screen enabled.
        - Console: US Keymap, Terminus font (Lat2-Terminus16).
      - **Networking**: NetworkManager for primary control, Tailscale for private mesh networking.

      ## Desktop Environment
      - **Window Manager**: Hyprland (Wayland)
      - **Display Manager**: SDDM with `sddm-astronaut-theme` (jake_the_dog theme variant).
      - **Theming**: System-wide Catppuccin Macchiato (base16-scheme).
      - **Audio**: Pipewire-based audio stack.
      - **Services**: `asusd` enabled for ASUS-specific hardware control (anime matrix, power profiles).

      ## Hosting & Infrastructure
      - **Base Domain**: `cryptic-coders.net` (Cloudflare-proxied)
      - **Reverse Proxy**: Caddy (managed via declarative modules).
      - **Media Stack**:
        - **Jellyfin**: Hardware acceleration enabled.
        - **Management**: Overseerr (`/media`), Sonarr (`/shows`), Radarr (`/movies`), Prowlarr (`/indexers`), FlareSolverr.
        - **Downloader**: qBittorrent (`/downloads`).
      - **Virtualization**:
        - **Docker**: Rootless mode/standard service as configured.
        - **VirtualBox**: System-level integration.

      ## User Details
      - **Primary User**: `sphoono` (Admin/Trusted User).
      - **Storage Paths**: Media mounted at `/mnt/local/media`.
    '';
  };
}
