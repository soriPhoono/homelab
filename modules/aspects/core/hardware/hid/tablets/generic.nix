{
  den.aspects.core.hardware.hid.tablets.generic = {
    nixos = _: {
      hardware.opentabletdriver = {
        enable = true;
        daemon.enable = true;
      };
    };
  };
}
