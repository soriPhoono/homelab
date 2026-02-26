{
  lib,
  config,
  ...
}: let
  cfg = config.hosting.blocks.backends;
in
  with lib; {
    imports = [
      ./docker.nix
      ./podman.nix
    ];

    options.hosting.blocks.backends = {
      enableNvidiaSupport = mkEnableOption "Enable nvidia support for blocks";
    };

    config = {
      hardware.nvidia-container-toolkit.enable = cfg.enableNvidiaSupport && config.core.hardware.gpu.dedicated.nvidia.enable;
    };
  }
