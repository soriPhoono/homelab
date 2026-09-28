{ den, lib, ... }: {
  den.aspects.core.hardware.gpu.nvidia = {
    includes = [
      # nvidia-x11 is unfreeRedistributable; nvidiaSettings defaults on, so
      # nvidia-settings needs allowing too. den merges unfree.packages across
      # every usage, so this composes with the list in modules/den.nix.
      (den.batteries.unfree [
        "nvidia-x11"
        "nvidia-settings"
      ])
    ];
    nixos = { pkgs, ... }: {
      imports = [
        ./_private
      ];

      # Unlike amd/intel, this is not just an Xorg DDX choice: the upstream
      # module keys `hardware.nvidia.enabled` off this list, so it is the
      # module's on-switch and stays even on a Wayland-only host.
      services.xserver.videoDrivers = [ "nvidia" ];

      hardware.nvidia = {
        open = true;

        # Fine-grained power management asserts that PRIME offload is enabled,
        # so it lives in the laptop aspect, not here.
        powerManagement.enable = true;
      };

      environment.systemPackages = with pkgs; [
        nvtopPackages.nvidia # NVIDIA gpu monitoring tool
      ];
    };

    gpgpu = {
      includes = [
        den.aspects.core.hardware.gpu.nvidia
      ];
      nixos = { pkgs, ... }: {
        # Every runtime rail already ships inside nvidia_x11.out, which the
        # upstream module puts in hardware.graphics.extraPackages:
        #   OpenCL  libnvidia-opencl.so + etc/OpenCL/vendors/nvidia.icd
        #   CUDA    libcuda.so (driver API)
        #   NVDEC   libnvcuvid.so
        #   NVENC   libnvidia-encode.so
        # The toolkit is the only piece the driver does not carry.
        environment.systemPackages = with pkgs; [
          cudaPackages.cudatoolkit # nvcc, cuBLAS, cuFFT, ...
        ];
      };
    };

    desktop = {
      includes = [
        den.aspects.core.hardware.gpu.nvidia
      ];
      nixos = _: {
        # PRIME sync and reverse sync are mutually exclusive upstream; sync
        # also precludes powerManagement.finegrained. Enabling any PRIME mode
        # additionally requires per-host bus IDs, which cannot live here.
        hardware.nvidia.prime = {
          sync.enable = true;
          allowExternalGpu = true;
        };
      };
    };

    laptop = {
      includes = [
        den.aspects.core.hardware.gpu.nvidia
      ];
      nixos = { host, ... }: {
        hardware.nvidia = {
          dynamicBoost.enable = true;
          powerManagement.finegrained = true;
          prime = {
            intelBusId = lib.mkIf (host.hasAspect den.aspects.core.hardware.gpu.intel) "PCI:0@0:2:0";
            amdgpuBusId = lib.mkIf (host.hasAspect den.aspects.core.hardware.gpu.amd) "PCI:4@0:0:0";
            nvidiaBusId = "PCI:1@0:0:0";
            offload = {
              enable = true;
              enableOffloadCmd = true;
              offloadCmdMainProgram = "prime-run";
            };
          };
        };
      };
    };
  };
}
