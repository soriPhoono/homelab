{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.core.hardware.gpu.intel;
in
  with lib; {
    options.core.hardware.gpu.intel = {
      enable = mkEnableOption "Enable intel gpu support";

      integrated = {
        enable = mkEnableOption "Enable integrated gpu features";

        deviceID = mkOption {
          type = types.str;
          description = "The device ID of the integrated gpu (for 12th gen onward)";
          default = null;
        };
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
              A machine with the intel gpu configuration is
              advised to declare in what nature the support is requested,
              either integrated or dedicated
            '';
          }
        ];

        core.hardware.gpu.enable = true;

        services.xserver.videoDrivers = ["intel"];

        hardware.intel-gpu-tools.enable = true;
      }
      (mkIf cfg.integrated.enable {
        boot.kernelParams = lib.mkIf (cfg.deviceID != null) [
          "i915.force_probe=${cfg.deviceID}"
        ];

        hardware.graphics.extraPackages = with pkgs; [
          intel-media-driver
          libvdpau-va-gl
        ];

        environment.variables = {
          LIBVA_DRIVER_NAME = "iHD";
          VDPAU_DRIVER = "va_gl";
        };
      })
      (mkIf cfg.dedicated.enable {
        hardware.graphics.extraPackages = mkIf config.core.hardware.gpu.dedicated.hardwareAcceleration.enable (with pkgs; [
          intel-media-driver
          libvdpau-va-gl
        ]);

        hardware.graphics.extraPackages32 = mkIf config.core.hardware.gpu.dedicated.hardwareAcceleration.enable (with pkgs; [
          driversi686Linux.intel-media-driver
          driversi686Linux.libvdpau-va-gl
        ]);
      })
    ]);
  }
