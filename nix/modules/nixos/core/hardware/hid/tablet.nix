{
  lib,
  config,
  ...
}: let
  cfg = config.core.hardware.hid.tablet;
in {
  options.core.hardware.hid.tablet.enable = lib.mkEnableOption "Enable opentabletdriver for drawing tablets";

  config = lib.mkIf cfg.enable {
    hardware.opentabletdriver.enable = true;
  };
}
