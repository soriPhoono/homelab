{ den, ... }:
{
  den.aspects.core.hardware.hid.keyboards.qmk = {
    includes = [ (den.batteries.unfree [ "via" ]) ];
    nixos = { pkgs, ... }: {
      hardware.keyboard.qmk = {
        enable = true;
        keychronSupport = true;
      };
      environment.systemPackages = [
        pkgs.via
        pkgs.vial
      ];
      services.udev.packages = [ pkgs.via ];
      # pkgs.vial ships no udev rules; grant the logged-in seat raw HID access
      # to any Vial-enabled firmware (serial contains the Vial magic number).
      services.udev.extraRules = ''
        KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{serial}=="*vial:f64c2b3c*", MODE="0660", GROUP="users", TAG+="uaccess", TAG+="udev-acl"
      '';
    };
  };
}
