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
    ./boot
    ./hardware
    ./networking
    ./clamav.nix
    ./gitops.nix
    ./nixconf.nix
    ./security.nix
    ./secrets.nix
    ./users.nix
  ];

  options.core = {
    stateVersion = mkOption {
      type = with types; nullOr str;
      description = ''
        The NixOS release version to use for system state management.
      '';
      default = null;
      example = "23.05";
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

    system.stateVersion =
      if cfg.stateVersion != null
      then cfg.stateVersion
      else config.system.nixos.release;
  };
}
