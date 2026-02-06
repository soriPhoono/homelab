{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.core.boot;
in {
  options.core.boot = {
    enable = lib.mkEnableOption "Enable system boot configuration with systemd-boot and ZRAM swap";
    plymouth = {
      enable = lib.mkEnableOption "Enable plymouth";
    };
    secure-boot = {
      enable = lib.mkEnableOption "Enable bootloader hardening features via lanzaboote";
    };
    kernel = {
      package = lib.mkOption {
        type = lib.types.attrs;
        default = pkgs.linuxPackages_zen;
        description = "Kernel package to use";
      };
      params = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default =
          if cfg.plymouth.enable
          then [
            "quiet"
            "systemd.show_status=false"
            "udev.log_level=3"
          ]
          else [];
        description = "Kernel parameters to use";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    boot = {
      kernelPackages = cfg.kernel.package;
      kernelParams = cfg.kernel.params;

      initrd = {
        verbose = !cfg.plymouth.enable;
        systemd.enable = true;
      };

      consoleLogLevel = 0;

      loader = {
        efi.canTouchEfiVariables = true;
        systemd-boot = {
          enable = lib.mkIf cfg.enable (lib.mkForce (!cfg.secure-boot.enable));
          configurationLimit = 10;
        };
      };

      lanzaboote = {
        inherit (cfg.secure-boot) enable;
        pkiBundle = "/var/lib/sbctl";
      };

      plymouth.enable = cfg.plymouth.enable;
    };

    zramSwap.enable = true;

    security.sudo.wheelNeedsPassword = lib.mkDefault false;
  };
}
