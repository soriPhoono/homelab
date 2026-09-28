{
  den.aspects.core.hardware.hid.mice.logitech = {
    nixos = _: {
      hardware.logitech.wireless.enable = true;
      programs.solaar = {
        enable = true;
        userService.enable = true;
      };
    };
    homeManager = { pkgs, ... }: {
      home.packages = with pkgs; [
        solaar
      ];
    };
  };
}
