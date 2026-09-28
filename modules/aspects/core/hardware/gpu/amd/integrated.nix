{
  den.aspects.core.hardware.gpu.amd.integrated = {
    nixos = { pkgs, ... }: {
      imports = [
        ../_private
      ];
      hardware = {
        amdgpu.initrd.enable = true;
        graphics = {
          extraPackages = with pkgs; [
            libvdpau-va-gl
          ];
          extraPackages32 = with pkgs; [
            driversi686Linux.libvdpau-va-gl
          ];
        };
      };
      environment.variables = {
        LIBVA_DRIVER_NAME = "radeonsi";
        VDPAU_DRIVER = "va_gl";
      };
      services.xserver.videoDrivers = [ "amdgpu" ];
    };
  };
}
