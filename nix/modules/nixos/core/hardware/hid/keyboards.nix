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

    config = lib.mkIf cfg.enable {
      hardware.keyboard.qmk = {
        enable = true;
        keychronSupport = elem "qmk" cfg.vendors;
      };

      environment.systemPackages = with pkgs; [
        via
      ];

      services.udev.packages = [pkgs.via];
    };
  }
