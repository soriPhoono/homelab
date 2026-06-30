{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.core.hardware.hid.keyboards;
in
  with lib; {
    options.core.hardware.hid.keyboards = {
      enable = mkEnableOption "Enable keyboard userspace drivers";
      vendors = mkOption {
        type = with types; listOf (enum ["qmk"]);
        description = "List of keyboard vendors to enable userspace drivers for";
        default = [];
      };
    };

    config = mkIf cfg.enable (mkMerge [
      (mkIf (elem "qmk" cfg.vendors) {
        hardware.keyboard.qmk = {
          enable = true;
          keychronSupport = true;
        };

        environment.systemPackages = with pkgs; [
          via
        ];

        services.udev.packages = [pkgs.via];
      })
    ]);
  }
