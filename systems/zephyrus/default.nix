{pkgs, ...}: {
  imports = [
    ./disko.nix
  ];

  core = {
    boot.enable = true;

    hardware = {
      enable = true;
      reportPath = ./facter.json;

      gpu = {
        integrated.amd.enable = true;
        dedicated.nvidia = {
          enable = true;
          laptopMode = true;
        };
      };

      hid = {
        xbox_controllers.enable = true;
      };

      adb.enable = true;
      bluetooth.enable = true;
    };

    gitops = {
      enable = true;
      repo = "https://github.com/soriphoono/homelab.git";
      name = "zephyrus";
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
      soriphoono = {
        hashedPassword = "$6$x7n.SUTMtInzs2l4$Ew3Zu3Mkc4zvuH8STaVpwIv59UX9rmUV7I7bmWyTRjomM7QRn0Jt/Pl/JN./IqTrXqEe8nIYB43m1nLI2Un211";
        admin = true;
        shell = pkgs.fish;
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
  };

  desktop = {
    environments = {
      kde.enable = true;
      managers.hyprland.enable = true;
    };
    features = {
      virtualisation.enable = true;
      gaming.enable = true;
    };
    services.asusd.enable = true;
  };

  hosting.features.single-use.docker-games-server = {
    enable = true;
    gpuRenderNode = "/dev/dri/renderD129";
  };
}
