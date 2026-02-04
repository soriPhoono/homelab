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
    ./boot.nix
    ./gitops.nix
    ./nixconf.nix
    ./secrets.nix
    ./users.nix
    ./networking
    ./hardware
  ];

  options.core = {
    timeZone = lib.mkOption {
      type = types.str;
      description = "The current system time zone";
      default = "America/Chicago";
    };
  };

  config = {
    hardware.enableAllFirmware = true;

    console = {
      keyMap = "us";
      packages = with pkgs; [
        terminus_font
      ];
      font = "Lat2-Terminus16";
    };

    i18n.defaultLocale = "en_US.UTF-8";

    time.timeZone = cfg.timeZone;

    programs = {
      nix-ld.enable = true;
      nh = {
        enable = true;

        clean = {
          enable = true;
          dates = "daily";
          extraArgs = "--keep-since 3d --keep 5";
        };
      };
    };

    system.stateVersion = config.system.nixos.release;
  };
}
