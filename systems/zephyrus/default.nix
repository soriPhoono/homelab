{
  pkgs,
  config,
  ...
}: {
  imports = [
    ./disko.nix
  ];

  core = {
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

    sops.secrets."users/soriphoono/password" = {
      neededForUsers = true;
    };

    networking = {
      network-manager.enable = true;
      tailscale.enable = true;
    };

    users = {
      soriphoono = {
        passwordFile = config.sops.secrets."users/soriphoono/password".path;
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
      type = "docker";
      nvidiaSupport = true;
    };
    features.docker-games-server = {
      enable = true;
      openFirewall = true;
      gpuRenderNode = "/dev/dri/renderD129";
    };
  };
}
