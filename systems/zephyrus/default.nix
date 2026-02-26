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
  };

  # nix-on-droid cache — needed to build/evaluate droid activation packages locally
  nix.settings = {
    extra-substituters = ["https://nix-on-droid.cachix.org"];
    extra-trusted-public-keys = ["nix-on-droid.cachix.org-1:56snoMJTXmDRC1Ei24CmKoUqvHJ9XCp+nidK7qkMQrU="];
  };

  hosting.blocks = {
    backends = {
      enableNvidiaSupport = true;
      docker.enable = true;
    };
    features.docker-games-server = {
      enable = true;
      openFirewall = true;
      gpuRenderNode = "/dev/dri/renderD129";
    };
  };
}
