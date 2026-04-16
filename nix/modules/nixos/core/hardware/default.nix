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
        description = "The default report path for facter input modules";
        example = ./facter.json;
      };
    };

    config = mkIf cfg.enable (mkMerge [
      {
        hardware.enableAllFirmware = true;
      }
      (optionalAttrs (options ? facter) {
        facter = {
          report = builtins.fromJSON (builtins.readFile cfg.reportPath);
        };
      })
    ]);
  }
