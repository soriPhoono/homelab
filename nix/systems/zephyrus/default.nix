{pkgs, ...}: {
  imports = [
    ./disko.nix
  ];

  core = {
    nixconf.determinate.enable = true;

    boot = {
      enable = true;
      plymouth = {
        enable = true;
        theme = {
          name = "cross_hud";
          package = pkgs.adi1090x-plymouth-themes.override {
            selected_themes = ["cross_hud"];
          };
        };
      };
    };

    hardware = {
      enable = true;
      reportPath = ./facter.json;

      cpu.vendor = "amd";

      gpu = {
        amd.integrated.enable = true;
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

    secrets = {
      enable = true;
      defaultSopsFile = ./secrets.yml;
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
        publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMsLDpds7sJGuczBvZEIkqEBwjdk22MbiML/WYzHwzkT Personal Key";
      };
    };

    clamav.enable = true;
  };

  desktop = {
    environments = {
      display_managers.sddm = {
        theme = {
          package = pkgs.sddm-astronaut.override {
            embeddedTheme = "pixel_sakura";
          };
          name = "sddm-astronaut-theme";
        };
        extraPackages = with pkgs.kdePackages; [
          qtmultimedia
          qtvirtualkeyboard
          qtsvg
        ];
      };
      kde.enable = true;
    };
    features = {
      printing.enable = true;
      virtualisation.enable = true;
      gaming.enable = true;
    };
    services.asusd.enable = true;
    tools.partition-manager.enable = true;
  };

  hosting.docker.enable = true;
}
