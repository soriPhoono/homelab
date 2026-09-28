{
  den.aspects.core.hardware.bluetooth = {
    nixos = {
      hardware.bluetooth = {
        enable = true;
        powerOnBoot = true;

        settings = {
          General = {
            Experimental = true;
          };
        };
      };
    };
  };
}
