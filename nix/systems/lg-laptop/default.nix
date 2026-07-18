{pkgs, ...}: {
  imports = [
    ./disko.nix
  ];

  core = {
    enable = true;
    stateVersion = "26.11";
    timeZone = "America/Chicago";

    nixconf.determinate.enable = true;

    boot = {
      enable = true;
      kernel.packages = pkgs.linuxPackages_latest;
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
            deviceID = "a7a0";
          };
        };
      };

      hid = {
        xp-pen.enable = true;
        xbox_controllers.enable = true;
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
      spookyskelly = {
        description = "Spooky Skelly";
        hashedPassword = "$y$j9T$2ClMbK8AGR2tDvxqsQi7N/$VoJZOzxRwbq6GZ9zBR0E2gq0GsZ3Oo27RcjCyG/Gct5";
        secrets = true;
        admin = true;
        shell = pkgs.fish;
        publicKeys = {
          primary = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEe5elK6ZPxVfoUBM1Ytd9/15OjdTeIfyUU61qR3osP8";
        };
        linger = true;
      };
    };
  };

  desktop = {
    environments.kde.enable = true;
    services = {
      printing.enable = true;
      pipewire.enable = true;
    };
    features.gaming.desktop.enable = true;
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

    proxy = {
      enable = true;

      local = {
        provider = "traefik";
        domain = "cryptic-coders.net";
      };

      dns = {
        provider = "cloudflare";
        email = "soriphoono@gmail.com";
      };
    };
  };
}
