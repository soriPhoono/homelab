{
  den.aspects.core.hardware.hid.keyboards.qmk = {
    nixos =
      { pkgs, ... }:
      let
        via = [ pkgs.via ];
      in
      {
        hardware.keyboard.qmk = {
          enable = true;
          keychronSupport = true;
        };
        environment.systemPackages = via;
        services.udev.packages = via;
      };

    homeManager =
      { pkgs, ... }:
      let
        via = [ pkgs.via ];
      in
      {
        home.packages = via;
      };
  };
}
