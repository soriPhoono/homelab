{ den, ... }: {
  den.aspects.core.hardware.hid.controllers.xbox = {
    includes = [
      # hardware.xone pulls in xone-dongle-firmware, which is unfree.
      (den.batteries.unfree [ "xone-dongle-firmware" ])
    ];
    nixos.hardware.xone.enable = true;
  };
}
