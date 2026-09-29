{
  den.aspects.core.hardware.hid.keyboards.qmk = {
    nixos = { pkgs, ... }: {
      hardware.keyboard.qmk = {
        enable = true;
        keychronSupport = true;
      };
      environment.systemPackages = [ pkgs.via ];
      services.udev.packages = [ pkgs.via ];
    };
  };
}
