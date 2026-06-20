{
  lib,
  config,
  ...
}: let
  cfg = config.core.hardware;
in
  with lib; {
    imports = [
      ./cpu.nix
      ./gpu
      ./hid
      ./adb.nix
      ./bluetooth.nix
    ];

    options.core.hardware = {
      enable = mkEnableOption "Enable hardware support";

      reportPath = mkOption {
        type = types.path;
        description = ''
          Path to a nixos-facter JSON report used for automatic hardware
          detection and configuration. The facter tool generates a hardware
          report (facter.json) that this module reads to enable appropriate
          kernel modules, firmware, and driver settings for the detected
          hardware. Generate one with `nixos-facter` on the target system.
        '';
        example = ./facter.json;
      };
    };

    config = mkIf cfg.enable (mkMerge [
      {
        hardware = {
          enableAllFirmware = true;
          facter = {
            inherit (cfg) reportPath;
          };
        };
      }
    ]);
  }
