{ den, lib, ... }: {
  den.aspects.core.hardware.gpu.amd.dedicated = { host, ... }: {
    nixos =
      { pkgs, ... }:
      (lib.mkMerge [
        {
          imports = [
            ../_private
          ];
          hardware.amdgpu.opencl.enable = true;
          systemd.tmpfiles.rules = [
            "L+ /opt/rocm/hip - - - - ${pkgs.rocmPackages.clr}"
          ];
          services.xserver.videoDrivers = [ "amdgpu" ];
        }
        (lib.mkIf
          (
            !(
              (host.hasAspect den.aspects.core.hardware.gpu.amd.integrated)
              || (host.hasAspect den.aspects.core.hardware.gpu.intel.integrated)
            )
          )
          {

          }
        )
      ]);
  };
}
