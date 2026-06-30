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
    services = {
      virtualisation = {
        enable = true;
        mode = "guest";
      };
      pipewire.enable = true;
    };
  };

  themes = {
    enable = true;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-macchiato.yaml";
  };
}
