{
  den.aspects.core.hardware.gpu.intel = {
    nixos = { pkgs, ... }: {
      imports = [
        ../_private
      ];
      hardware = {
        intel-gpu-tools.enable = true;
        graphics = {
          extraPackages = with pkgs; [
            intel-media-driver
            intel-compute-runtime
            libvdpau-va-gl
          ];
          extraPackages32 = with pkgs.pkgsi686Linux; [
            intel-media-driver
            libvdpau-va-gl
          ];
        };
      };
      environment.variables = {
        LIBVA_DRIVER_NAME = "iHD";
        VDPAU_DRIVER = "va_gl";
      };
      services.xserver.videoDrivers = [ "intel" ];
    };
  };
}
