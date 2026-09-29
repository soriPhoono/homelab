{ den, ... }: {
  den.aspects.core.hardware.gpu.amd = {
    nixos = { ... }: {
      imports = [
        ./_private
      ];
    };
    homeManager = { pkgs, ... }: {
      home.packages = with pkgs; [
        nvtopPackages.amd
      ];
    };
    gpgpu = {
      includes = [
        den.aspects.core.hardware.gpu.amd
      ];
      nixos = { pkgs, ... }: {
        hardware.amdgpu = {
          opencl.enable = true;
          zluda.enable = true;
        };
        systemd.tmpfiles.rules = [
          "L+ /opt/rocm/hip - - - - ${pkgs.rocmPackages.clr}"
        ];
      };
    };
  };
}
