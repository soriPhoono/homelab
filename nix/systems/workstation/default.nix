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
      # System Environment: Workstation

      ## Hardware Specifications
      - **Device**: Custom Workstation (MSI `PRO Z790-P WIFI DDR4`)
      - **Firmware**: AMI BIOS `1.G0`
      - **CPU**: Intel Core i9-14900K (24 cores / 32 threads)
      - **RAM**: 32GB DDR4
      - **Graphics**:
        - Integrated: Intel UHD Graphics 770 (Raptor Lake-S GT1)
        - Dedicated: AMD Radeon RX 7900 XTX (XFX Speedster MERC 310)
      - **Storage**:
        - System: Samsung SSD 970 EVO Plus 1TB NVMe
        - Project Pool: 2x Samsung SSD 870 EVO 1TB SATA SSDs (ZFS mirror)
        - Storage Pool: 2x Seagate BarraCuda 2TB SATA HDDs (ZFS stripe)
      - **Networking**: Intel Ethernet & Wi-Fi/Bluetooth hardware with NetworkManager and Tailscale enabled
      - **Peripherals**:
        - Keychron Q10 keyboard
        - Razer Basilisk V3 Pro mouse
        - Depstech webcam
        - Xbox Controller support enabled
        - Logitech device support enabled
        - Android ADB support enabled

      ## Operating System & Core Config
      - **OS**: NixOS (`x86_64-linux`)
      - **Timezone**: `America/Chicago`
      - **Nix Configuration**:
        - Determinate Nix enabled with `nix-command` and `flakes`
        - `nh` manages system/home switching and cleanup workflows
        - `nix-ld` and `sops-nix` are enabled for binary compatibility and secret management
      - **Boot & Console**:
        - systemd-boot with Plymouth splash screen and Linux Zen kernel
        - US keymap and Terminus console font
      - **Security & Access**:
        - Host secrets are sourced from `./secrets.yml`

      ## Desktop & Local Services
      - **Session Stack**: Hyprland (Wayland) with SDDM using the `sddm-astronaut-theme` `jake_the_dog` variant
      - **Theming**: System-wide Catppuccin Macchiato base16 scheme
      - **Desktop Features**:
        - Printing enabled
        - Gaming profile enabled, including Virtual Reality (VR) support
      - **Local Tools**:
        - Docker enabled
        - VirtualBox enabled
        - Partition manager enabled
    '';
    stateVersion = "26.05";
    timeZone = "America/Chicago";
    nixconf.determinate.enable = true;

    boot = {
      enable = true;
      kernel.packages = pkgs.linuxPackages_zen;
      plymouth.enable = true;
    };

    hardware = {
      enable = true;
      reportPath = ./facter.json;

      cpu.vendor = "intel";

      gpu = {
        intel = {
          enable = true;
          integrated = {
            enable = true;
            deviceID = "a780";
          };
        };
        amd = {
          enable = true;
          dedicated.enable = true;
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
      tailscale.enable = true;
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
    services.printing.enable = true;
    features = {
      gaming = {
        enable = true;
        vr.enable = true;
      };
    };
    tools = {
      partition-manager.enable = true;
      virtualbox.enable = true;
    };
  };

  networking.hostId = "f0470582";

  themes = {
    enable = true;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-macchiato.yaml";
  };
}
