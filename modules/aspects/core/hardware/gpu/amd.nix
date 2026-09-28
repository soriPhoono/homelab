{
  den.aspects.core.hardware.gpu.amd = {
    nixos = { pkgs, ... }: {
      imports = [
        ../_private
      ];
      hardware = {
        amdgpu = {
          initrd.enable = true;
          opencl.enable = true;
        };
        graphics = {
          extraPackages = with pkgs; [
            libvdpau-va-gl
          ];
          extraPackages32 = with pkgs.pkgsi686Linux; [
            libvdpau-va-gl
          ];
        };
      };
      systemd.tmpfiles.rules = [
        "L+ /opt/rocm/hip - - - - ${pkgs.rocmPackages.clr}"
      ];
      environment.variables = {
        LIBVA_DRIVER_NAME = "radeonsi";
        VDPAU_DRIVER = "va_gl";
      };
      services.xserver.videoDrivers = [ "amdgpu" ];
    };
  };
}
