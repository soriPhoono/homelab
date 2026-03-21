{
  lib,
  config,
  ...
}: let
  cfg = config.core.hardware.hid.logitech;
in {
  options.core.hardware.hid.logitech.enable = lib.mkEnableOption "Enable logitech drivers";

  config = lib.mkIf cfg.enable {
    hardware.logitech.wireless = {
      enable = true;
      enableGraphical = true;
    };
  };
}
