{
  lib,
  pkgs,
  ...
}:
with lib; {
  imports = [
    ./disko.nix
  ];

  core = {
    context = ''
      # System Environment: Zephyrus

      ## Hardware Specifications
      - **Device**: ASUS ROG Zephyrus G14 (`GA401QM`)
      - **Firmware**: ASUS BIOS `GA401QM.415`
      - **CPU**: AMD Ryzen 9 5900HS (8 cores / 16 threads)
      - **RAM**: 16GB DDR4-3200 via 2x8GB Micron SODIMMs
      - **Graphics**:
        - Integrated: AMD Radeon Graphics
        - Dedicated: NVIDIA GeForce RTX 3060 (NixOS laptop mode)
      - **Storage**: Samsung NVMe SSD (`SAMSUNG MZVLQ1T0HBLB-00B00`)
      - **Networking**: MediaTek Wi-Fi/Bluetooth hardware with NetworkManager and Tailscale enabled
      - **Peripherals**:
        - Goodix fingerprint reader
        - Xbox Controller support enabled
        - Logitech device support enabled
        - Android ADB support enabled

      ## Operating System & Core Config
      - **OS**: NixOS (`x86_64-linux`)
      - **Timezone**: `America/Chicago`
      - **Nix Configuration**:
        - Determinate Nix enabled with `nix-command` and `flakes`
        - `nh` manages system/home switching and cleanup workflows
        - Build cores are capped at 4 to reduce OOM risk on large evaluations
        - `nix-ld` and `sops-nix` are enabled for binary compatibility and secret management
      - **Boot & Console**:
        - systemd-boot with Plymouth splash screen
        - US keymap and Terminus console font
      - **Security & Access**:
        - Host secrets are sourced from `./secrets.yml`
        - Tailscale Serve origin is pinned for this laptop node

      ## Desktop & Local Services
      - **Session Stack**: Hyprland (Wayland) with SDDM using the `sddm-astronaut-theme` `jake_the_dog` variant
      - **Theming**: System-wide Catppuccin Macchiato base16 scheme
      - **Laptop Integration**: `asusd` enabled for ASUS-specific controls
      - **Desktop Features**:
        - Printing enabled
        - Gaming profile enabled, including console support
      - **Local Tools**:
        - Docker enabled
        - VirtualBox enabled
        - Partition manager enabled

      ## Hosting & Infrastructure
      - **Base Domain**: `cryptic-coders.net`
      - **Hosted Roles**:
        - Homepage dashboard enabled
        - Media stack enabled: Jellyfin, Overseerr, Sonarr, Radarr, Prowlarr, FlareSolverr, qBittorrent
        - Declarative Caddy proxy routes expose media and download services
      - **Media Paths**: Managed under `/mnt/local/media` with service-specific movie, show, and download directories
    '';
    timeZone = "America/Chicago";
    nixconf.determinate.enable = true;

    boot = {
      enable = true;
      # kernel.packages = pkgs.linuxPackages_zen;
      plymouth.enable = true;
    };

    hardware = {
      enable = true;
      reportPath = ./facter.json;

      cpu.vendor = "amd";

      gpu = {
        amd = {
          enable = true;
          integrated.enable = true;
        };
        nvidia = {
          enable = true;
          mode = "laptop";
        };
      };

      hid = {
        xbox_controllers.enable = true;
        logitech.enable = true;
      };

      adb.enable = true;
      bluetooth.enable = true;
    };

    networking = {
      network-manager.enable = true;
      tailscale = {
        enable = true;
        serve.tailnetOrigin = mkForce "https://laptop-sori.xerus-augmented.ts.net";
      };
    };

    secrets = {
      enable = true;
      defaultSopsFile = ./secrets.yml;
    };

    users = {
      sphoono = {
        description = "Sori Phoono";
        hashedPassword = "$6$x7n.SUTMtInzs2l4$Ew3Zu3Mkc4zvuH8STaVpwIv59UX9rmUV7I7bmWyTRjomM7QRn0Jt/Pl/JN./IqTrXqEe8nIYB43m1nLI2Un211";
        secrets = true;
        admin = true;
        shell = pkgs.fish;
        publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMsLDpds7sJGuczBvZEIkqEBwjdk22MbiML/WYzHwzkT Personal Key";
      };
    };
  };

  desktop = {
    environments = {
      display_managers.sddm = {
        enable = true;
        theme = {
          package = pkgs.sddm-astronaut.override {
            embeddedTheme = "jake_the_dog";
          };
          name = "sddm-astronaut-theme";
        };
        extraPackages = with pkgs.kdePackages; [
          qtmultimedia
          qtvirtualkeyboard
          qtsvg
        ];
      };
      managers.hyprland.enable = true;
    };
    services = {
      asusd.enable = true;
      printing.enable = true;
    };
    features.gaming = {
      enable = true;
      console.enable = true;
    };
    tools = {
      partition-manager.enable = true;
      virtualbox.enable = true;
      docker.enable = true;
    };
  };

  hosting = {
    homepage.enable = true;
    media.enable = true;
    proxy.dns = {
      baseDomain = "cryptic-coders.net";
      email = "soriphoono@gmail.com";
    };
  };

  themes = {
    enable = true;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-macchiato.yaml";
  };
}
