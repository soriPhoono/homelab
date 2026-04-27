{pkgs, ...}: {
  imports = [
    ./disko.nix
  ];

  core = {
    nixconf.determinate.enable = true;

    boot = {
      enable = true;
      # kernel.packages = pkgs.linuxPackages_zen;
      plymouth.enable = true;
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
        hashedPassword = "$6$x7n.SUTMtInzs2l4$Ew3Zu3Mkc4zvuH8STaVpwIv59UX9rmUV7I7bmWyTRjomM7QRn0Jt/Pl/JN./IqTrXqEe8nIYB43m1nLI2Un211";
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
    services.asusd.enable = true;
    features = {
      printing.enable = true;
      virtualisation.enable = true;
      gaming.enable = true;
    };
    tools = {
      partition-manager.enable = true;
      virtualbox.enable = true;
      docker.enable = true;
    };
  };

  hosting = {
    media.enable = true;
    proxy.dns = {
      baseDomain = "cryptic-coders.net";
      email = "soriphoono@gmail.com";
    };
  };

  themes = {
    enable = true;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-macchiato.yaml";
  };
}
