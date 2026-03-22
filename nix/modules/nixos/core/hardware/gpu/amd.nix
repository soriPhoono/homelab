{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.core.hardware.gpu.amd;
in
  with lib; {
    options.core.hardware.gpu.amd = {
      enable = mkEnableOption "Enable amdgpu support";

      integrated = {
        enable = mkEnableOption "Enable integrated gpu features";
      };

      dedicated = {
        enable = mkEnableOption "Enable dedicated gpu features";
      };
    };

    config = mkIf cfg.enable (mkMerge [
      {
        warnings = [
          {
            warning = !cfg.integrated.enable && !cfg.dedicated.enable;
            message = ''
              A machine with the amd gpu configuration is advised to declare
              in what nature the support is requested, either integrated or
              dedicated
            '';
          }
        ];

        core.hardware.gpu.enable = true;

        services.xserver.videoDrivers = ["amdgpu"];
      }
      (mkIf cfg.integrated.enable {
        hardware.amdgpu.initrd.enable = true;

        environment.variables = {
          LIBVA_DRIVER_NAME = "radeonsi";
          VDPAU_DRIVER = "radeonsi";
        };
      })
      (mkIf cfg.dedicated.enable {
        hardware.amdgpu.opencl.enable = true;

        systemd.tmpfiles.rules = [
          "L+    /opt/rocm/hip   -    -    -     -    ${pkgs.rocmPackages.clr}"
        ];
      })
    ]);
  }
