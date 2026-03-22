{
  lib,
  config,
  ...
}: let
  cfg = config.hosting;
in
  with lib; {
    imports = [
      ./docker.nix
      ./k3s.nix
    ];

    options.hosting = {
      enableNvidiaSupport = mkEnableOption "Enable nvidia support for single-node backends";
    };

    config = mkIf (cfg.enableNvidiaSupport && config.core.hardware.gpu.dedicated.nvidia.enable) {
      hardware.nvidia-container-toolkit.enable = true;
    };
  }
