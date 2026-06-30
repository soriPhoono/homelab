{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.core;
in
  with lib; {
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
      enable = mkEnableOption "Enable core system configuration";

      timeZone = mkOption {
        type = with types; nullOr str;
        description = ''
          The system time zone used for container TZ environment variables,
          system logging timestamps, and scheduled task scheduling.
          Set to null to use the systemd default (usually UTC).
        '';
        default = null;
        example = "America/Chicago";
      };

      stateVersion = mkOption {
        type = with types; nullOr str;
        description = ''
          The NixOS release version to use for system state management.
        '';
        default = null;
        example = "23.05";
      };
    };

    config = mkIf cfg.enable (mkMerge [
      {
        environment.systemPackages = with pkgs; [
          wget

          pciutils
          usbutils
        ];

        console = {
          keyMap = "us";
          packages = with pkgs; [
            terminus_font
          ];
          font = "Lat2-Terminus16";
        };

        i18n.defaultLocale = "en_US.UTF-8";

        time.timeZone = mkIf (cfg.timeZone != null) cfg.timeZone;

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
      }
    ]);
  }
