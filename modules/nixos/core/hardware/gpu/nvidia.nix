{
  lib,
  config,
  ...
}: let
  cfg = config.core.hardware.gpu.nvidia;
in
  with lib; {
    options.core.hardware.gpu.nvidia = {
      enable = mkEnableOption "Enable NVIDIA GPU support (dedicated only)";

      mode = mkOption {
        type = enum ["desktop" "laptop"];
        default = "laptop";
        description = "NVIDIA GPU mode";
      };

      allowExternalGpu = mkEnableOption "Enable external GPU support";
    };

    config = lib.mkIf cfg.enable (mkMerge [
      {
        core.hardware.gpu.enable = true;

        services.xserver.videoDrivers = ["nvidia"];

        hardware.nvidia = {
          open = true;

          nvidiaPersistenced = true;

          powerManagement = {
            enable = true;
            finegrained = true;
          };

          prime = {
            intelBusId = "PCI:0@0:2:0";
            amdgpuBusId = "PCI:4@0:0:0";
            nvidiaBusId = "PCI:1@0:0:0";
          };
        };
      }
      (mkIf (cfg.mode == "desktop") {
        hardware.nvidia.prime = mkIf config.hardware.nvidia.modesetting.enable {
          sync = {
            enable = true;
          };

          reverseSync = {
            enable = true;
          };

          inherit (cfg) allowExternalGpu;
        };
      })
      (mkIf (cfg.mode == "laptop") {
        hardware.nvidia = {
          dynamicBoost.enable = true;

          prime.offload = {
            enable = true;
            enableOffloadCmd = true;
            offloadCmdMainProgram = "prime-run";
          };
        };
      })
    ]);
  }
