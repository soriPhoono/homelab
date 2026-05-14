{
  lib,
  pkgs,
  config,
  ...
}:
with lib; let
  cfg = config.core;
in {
  imports = [
    ./hardware
    ./networking
    ./boot.nix
    ./clamav.nix
    ./gitops.nix
    ./nixconf.nix
    ./security.nix
    ./secrets.nix
    ./users.nix
  ];

  options.core = {
    context = lib.mkOption {
      type = with types; nullOr str;
      description = "System-level context to be included in agent guidance.";
      default = null;
      example = ''
        This system is a NixOS server running in a homelab environment. It is used for hosting various services and applications, and is managed using NixOps for deployment and configuration. The server has limited resources, so efficiency and security are important considerations when making changes to the system.
      '';
    };
    timeZone = lib.mkOption {
      type = with types; nullOr str;
      description = "The current system time zone";
      default = null;
      example = "America/Chicago";
    };
  };

  config = {
    environment.systemPackages = with pkgs; [
      wget

      pciutils
      usbutils
    ];

    hardware.enableAllFirmware = true;

    console = {
      keyMap = "us";
      packages = with pkgs; [
        terminus_font
      ];
      font = "Lat2-Terminus16";
    };

    i18n.defaultLocale = "en_US.UTF-8";

    time.timeZone = lib.mkIf (cfg.timeZone != null) cfg.timeZone;

    programs = {
      nix-ld.enable = true;
      nh = {
        enable = true;

        clean = {
          enable = true;
          dates = "daily";
          extraArgs = "--keep-since 3d --keep 3";
        };
      };
    };

    system.stateVersion = config.system.nixos.release;
  };
}
