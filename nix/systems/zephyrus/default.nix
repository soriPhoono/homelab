{
  lib,
  pkgs,
  inputs,
  ...
}:
with lib; {
  imports = [
    ./disko.nix
  ];

  core = {
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
      tailscale = {
        enable = true;
        serve = {
          enable = true;
          services.hermes-dashboard.proxy = {
            "tcp:9119" = "http://127.0.0.1:9119";
          };
        };
      };
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
        publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMsLDpds7sJGuczBvZEIkqEBwjdk22MbiML/WYzHwzkT Personal Key";
      };
    };
  };

  # Required for MediaTek MT7921 Bluetooth (USB 13d3:3563) — HCI reset + USB core autosuspend break WMT function control
  boot.extraModprobeConfig = "options btusb enable_autosuspend=0 reset=0";
  boot.kernelParams = ["usbcore.quirks=13d3:3563:k"];

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
    ai.enable = true;
    homepage.enable = true;
    platforms.docker.enable = true;
    media.enable = true;
    proxy.dns = {
      baseDomain = "cryptic-coders.net";
      email = "soriphoono@gmail.com";
    };

    hermes-agent = {
      # Nous Portal — model + tool gateway + auth
      portal.enable = true;
      model = "deepseek/deepseek-v4-flash";

      # Skip LSP/MCP for now — testing phase
      lsp.enable = false;

      # Web dashboard — all interfaces with Portal OAuth login screen
      dashboard = {
        enable = true;
        host = "0.0.0.0";
        oauthClientId = "agent:cmq33vtz8002wjf0b2vykn6pi";
      };

      # Caddy proxy — routes ai.local.cryptic-coders.net to dashboard
      enableProxy = true;

      # OpenAI-compatible API gateway
      gateway.enableApi = true;

      # Desktop Electron app — run with `hermes-desktop`
      desktopPackage = inputs.hermes-agent.packages.${pkgs.system}.desktop;

      # CLI + desktop app access for sphoono
      hostUsers = ["sphoono"];

      # Container backend (Docker already enabled above)
      container.backend = "docker";
    };
  };

  themes = {
    enable = true;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-macchiato.yaml";
  };
}
