# TODO: create device version specific driver installation flags
# i.e.: xp-pen artist 13.3 pro vs xp-pen artist 15.6 pro drivers
# this is due to some devices only having pen input and no touch or display
{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.core.hardware.hid.xp-pen;
in {
  options.core.hardware.hid.xp-pen.enable = lib.mkEnableOption "Enable XP-Pen tablet official drivers and udev rules";

  config = lib.mkIf cfg.enable {
    # Install the driver package
    environment.systemPackages = [pkgs.xp-pen-driver];

    # Register the driver's udev rules
    services.udev.packages = [pkgs.xp-pen-driver];

    # Ensure the uinput kernel module is loaded so the driver can emulate input devices
    boot.kernelModules = ["uinput"];

    # Create the symlink that the driver binary expects for configs and assets
    systemd.tmpfiles.rules = [
      "L+ /usr/lib/pentablet - - - - ${pkgs.xp-pen-driver}/opt/xp-pen"
    ];
  };
}
