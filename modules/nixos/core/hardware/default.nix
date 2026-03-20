{
  lib,
  config,
  options,
  ...
}: let
  cfg = config.core.hardware;
in
  with lib; {
    imports = [
      ./gpu
      ./hid
      ./cpu.nix
      ./adb.nix
      ./bluetooth.nix
    ];

    options.core.hardware = {
      enable = mkEnableOption "Enable hardware support";

      reportPath = mkOption {
        type = types.path;
        description = "The default report path for facter input modules";
        example = ./facter.json;
      };

      i2c.enable = mkEnableOption "Enable i2c support";
    };

    config = mkIf cfg.enable (mkMerge [
      {
        hardware.enableAllFirmware = true;
      }
      (optionalAttrs (options ? facter) {
        facter = {
          enable = true;
          inherit (cfg) reportPath;
        };
      })
      (mkIf cfg.i2c.enable {
        hardware.i2c.enable = true;
      })
    ]);
  }
