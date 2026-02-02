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
        integrated.intel = {
          enable = true;
          deviceId = "a7a0";
        };
      };

      hid = {
        tablet.enable = true;
        xbox_controllers.enable = true;
      };

      bluetooth.enable = true;
    };

    gitops = {
      enable = true;
      repo = "https://github.com/soriphoono/homelab.git";
      name = "lg-laptop";
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
      spookyskelly = {
        hashedPassword = "$y$j9T$2ClMbK8AGR2tDvxqsQi7N/$VoJZOzxRwbq6GZ9zBR0E2gq0GsZ3Oo27RcjCyG/Gct5";
        admin = true;
        shell = pkgs.fish;
        publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEe5elK6ZPxVfoUBM1Ytd9/15OjdTeIfyUU61qR3osP8";
      };
    };
  };

  desktop = {
    environments.kde.enable = true;
    features = {
      printing.enable = true;
      gaming.enable = true;
    };
  };
}
