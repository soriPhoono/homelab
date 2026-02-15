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
    ./gitops.nix
    ./nixconf.nix
    ./secrets.nix
    ./users.nix
  ];

  options.core = {
    timeZone = lib.mkOption {
      type = with types; nullOr str;
      description = "The current system time zone";
      default = null;
      example = "America/Chicago";
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

    time.timeZone = lib.mkIf (cfg.timeZone != null) cfg.timeZone;

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
