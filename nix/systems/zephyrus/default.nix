{pkgs, ...}: {
  imports = [
    ./disko.nix
  ];

  core = {
    nixconf.determinate-nix.enable = true;

    boot = {
      enable = true;
      plymouth.enable = true;
    };

    hardware = {
      enable = true;
      reportPath = ./facter.json;

      gpu = {
        amd.integrated.enable = true;
        nvidia = {
          enable = true;
          mode = "laptop";
        };
      };
      cpu.vendor = "amd";

      hid = {
        xbox_controllers.enable = true;
        logitech.enable = true;
      };

      adb.enable = true;
      bluetooth.enable = true;
    };

    secrets = {
      enable = true;
      defaultSopsFile = ./secrets.yaml;
    };

    networking = {
      network-manager.enable = true;
      tailscale.enable = true;
    };

    users = {
      sphoono = {
        hashedPassword = "$6$x7n.SUTMtInzs2l4$Ew3Zu3Mkc4zvuH8STaVpwIv59UX9rmUV7I7bmWyTRjomM7QRn0Jt/Pl/JN./IqTrXqEe8nIYB43m1nLI2Un211";
        admin = true;
        shell = pkgs.fish;
        extraGroups = [
          "docker"
        ];
        publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEgxxFcqHVwYhY0TjbsqByOYpmWXqzlVyGzpKjqS8mO7";
        subUidRanges = [
          {
            startUid = 100000;
            count = 65536;
          }
        ];
        subGidRanges = [
          {
            startGid = 100000;
            count = 65536;
          }
        ];
      };
    };

    clamav.enable = true;
  };

  desktop = {
    environments.kde.enable = true;
    features = {
      printing.enable = true;
      virtualisation.enable = true;
      gaming.enable = true;
    };
    services.asusd.enable = true;
    tools.partition-manager.enable = true;
  };
}
