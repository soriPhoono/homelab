{
  lib,
  pkgs,
  ...
}:
with lib; {
  imports = [
    ./disko.nix
  ];

  networking.hostId = "f0470582";

  core = {
    enable = true;
    stateVersion = "26.11";
    timeZone = "America/Chicago";

    nixconf.determinate.enable = true;

    boot = {
      enable = true;
      kernel.packages = pkgs.linuxPackages_zen;
      plymouth.enable = true;
      zram.enable = true;
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
        xp-pen.enable = true;
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
        publicKeys = {primary = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMsLDpds7sJGuczBvZEIkqEBwjdk22MbiML/WYzHwzkT Personal Key";};
        linger = true;
      };
    };
  };

  desktop = {
    environments = {
      display_managers.greetd.regreet = {
        enable = true;
        background.path = ./assets/login-background.jpg;
      };
      managers.hyprland.enable = true;
    };
    services = {
      printing.enable = true;
      pipewire.enable = true;
      virtualization.enable = true;
    };
    features = {
      gaming = {
        desktop = {
          enable = true;
          clients = [
            "steam"
            "lutris"
            "prismlauncher"
            "gzdoom"
          ];
        };
        console.enable = true;
        vr.enable = true;
        streaming.enable = true;
      };
    };
    tools.partition-manager.enable = true;
  };

  hosting = {
    platforms.podman.enable = true;

    media = {
      enable = true;

      jellyfin.acceleration = {
        enable = true;
        renderDevice = "/dev/dri/renderD128";
        cardDevice = "/dev/dri/card1";
      };
    };

    gaming = {
      enable = true;

      wolf = {
        gpu = "mesa-compatible";
        internalMac = "c2:d8:de:57:c6:7c";
      };
    };

    proxy = {
      enable = true;
      tailscale.enable = true;
    };
  };

  themes = {
    enable = true;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-macchiato.yaml";
  };
}
