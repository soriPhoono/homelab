{
  den = {
    aspects.systemd-boot = _: {
      includes = [ ];
      nixos = _: {
        boot = {
          kernelParams = [
            "quiet"
            "systemd.show_status=false"
            "udev.log_level=3"
          ];
          initrd = {
            verbose = false;
            systemd.enable = true;
          };
          consoleLogLevel = 0;
          loader = {
            efi.canTouchEfiVariables = true;
            systemd-boot = {
              enable = true;
              configurationLimit = 3;
            };
          };
          plymouth.enable = true;
        };
      };
    };
  };
}
