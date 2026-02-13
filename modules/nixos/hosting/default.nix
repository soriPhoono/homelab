{
  lib,
  config,
  ...
}:
with lib; {
  imports = [
    ./blocks
  ];

  options.hosting = {
    enable = mkEnableOption "Enable hosting features";
  };

  config = mkIf config.hosting.enable {
    hardware.nvidia-container-toolkit.enable = mkIf config.core.hardware.gpu.dedicated.nvidia.enable true;
  };
}
