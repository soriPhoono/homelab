{
  lib,
  config,
  ...
}: let
  cfg = config.core.hardware.hid.xbox_controllers;
in {
  options.core.hardware.hid.xbox_controllers.enable = lib.mkEnableOption "Enable gamepad drivers";

  config = lib.mkIf cfg.enable {
    hardware = {
      uinput.enable = true;
      xone.enable = true;
      xpad-noone.enable = true;
    };
  };
}
