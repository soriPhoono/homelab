{ den, ... }: {
  den.aspects.core.hardware.cpu.intel = {
    nixos = {
      hardware.cpu.intel.updateMicrocode = true;
    };

    npu = {
      includes = [
        den.aspects.core.hardware.cpu.intel
      ];
      nixos = {
        hardware.cpu.intel.npu.enable = true;
      };
    };
  };
}
