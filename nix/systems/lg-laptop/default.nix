{
  pkgs,
  lib,
  ...
}:
with lib; {
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
        tablet.enable = true;
        xbox_controllers.enable = true;
      };

      adb.enable = true;
      bluetooth.enable = true;
    };

    secrets = {
      enable = true;
      defaultSopsFile = ./secrets.yml;
    };

    networking = {
      network-manager.enable = true;
      tailscale = {
        enable = true;
        serve.tailnetOrigin = mkForce "https://laptop-spooky.xerus-augmented.ts.net";
      };
    };

    users = {
      spookyskelly = {
        hashedPassword = "$y$j9T$2ClMbK8AGR2tDvxqsQi7N/$VoJZOzxRwbq6GZ9zBR0E2gq0GsZ3Oo27RcjCyG/Gct5";
        admin = true;
        description = "Spooky Skelly";
        shell = pkgs.fish;
        publicKeys = {primary = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEe5elK6ZPxVfoUBM1Ytd9/15OjdTeIfyUU61qR3osP8";};
      };
    };
  };

  desktop = {
    environments.kde.enable = true;
    features.gaming.enable = true;
    services.printing.enable = true;
  };

  hosting = {
    media.enable = true;
    proxy.dns = {
      baseDomain = "cryptic-coders.net";
      email = "soriphoono@gmail.com";
    };
  };
}
