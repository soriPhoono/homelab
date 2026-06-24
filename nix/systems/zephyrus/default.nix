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
      };
    };
  };

  # vpower default threshold (0.5%) is too low for ASUS battery transient read glitches
  environment.etc."vpower.toml".text = ''
    request_shutdown_battery_percent = 5.0
    force_shutdown_timeout_secs = 10
  '';

  # Required for MediaTek MT7921 Bluetooth (USB 13d3:3563) — HCI reset + USB core autosuspend break WMT function control
  # boot.extraModprobeConfig = "options btusb enable_autosuspend=0 reset=0";
  # boot.kernelParams = ["usbcore.quirks=13d3:3563:k"];

  desktop = {
    environments = {
      display_managers.greetd.regreet = {
        enable = true;
        background.path = "/etc/greetd/background.jpg";
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
    };
  };

  hosting = {
    platforms.docker.enable = true;
    media = {
      enable = true;
      jellyfin.acceleration.enable = true;
    };
    proxy = {
      enable = true;
      type = "traefik";
      dns = {
        baseDomain = "cryptic-coders.net";
        email = "soriphoono@gmail.com";
      };
    };
  };

  themes = {
    enable = true;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-macchiato.yaml";
  };
}
