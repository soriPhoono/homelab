{ den, ... }: {
  den.aspects.core.hardware.gpu.intel = {
    nixos = { pkgs, ... }: {
      imports = [
        ./_private
      ];
      # VA-API driver (iHD) for hardware video decode/encode. Mesa covers
      # rendering but ships no VA driver for Intel; libva picks iHD itself.
      hardware.graphics.extraPackages = with pkgs; [
        intel-media-driver
      ];
      environment.systemPackages = with pkgs; [
        nvtopPackages.full
      ];
    };
    gpgpu = {
      includes = [
        den.aspects.core.hardware.gpu.intel
      ];
      nixos = { pkgs, ... }: {
        # Split mirrors nixpkgs' own hardware/cpu/intel-npu.nix: the compute
        # backend goes in the driver link, the Level Zero loader goes on the
        # system path. libze_loader.so is built with addDriverRunpath, so it
        # finds libze_intel_gpu.so under /run/opengl-driver/lib from there.
        hardware.graphics.extraPackages = with pkgs; [
          intel-compute-runtime # OpenCL ICD (libigdrcl.so) + Level Zero backend
        ];
        environment.systemPackages = with pkgs; [
          level-zero # Level Zero loader (libze_loader.so), for oneAPI/SYCL
        ];
      };
    };
  };
}
