{
  lib,
  pkgs,
  config,
  options,
  ...
}: let
  cfg = config.core.boot;
in
  with lib; {
    options.core.boot = {
      enable = lib.mkEnableOption "Enable system boot configuration with systemd-boot and ZRAM swap";
      secure-boot.enable = lib.mkEnableOption "Enable bootloader hardening features via lanzaboote";

      kernel = {
        package = lib.mkOption {
          type = lib.types.package;
          default = pkgs.linux;
          description = "Kernel package to use";
        };
        params = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [];
          description = "Kernel parameters to use";
        };
      };

      plymouth = {
        enable = lib.mkEnableOption "Enable plymouth boot splash screen";
        theme = mkOption {
          type = with types;
            submodule {
              options = {
                name = mkOption {
                  type = str;
                  default = "bgrt";
                };
                package = mkOption {
                  type = types.package;
                  default = pkgs.plymouth-themes.bgrt;
                };
              };
            };
        };
      };
    };

    config = lib.mkIf cfg.enable (lib.mkMerge [
      {
        boot = {
          kernelPackages = cfg.kernel.package;
          kernelParams =
            (mkMerge [
              (mkIf cfg.plymouth.enable [
                "quiet"
                "systemd.show_status=false"
                "udev.log_level=3"
              ])
            ])
            ++ cfg.kernel.params;

          initrd = {
            verbose = !cfg.plymouth.enable;
            systemd.enable = true;
            network = {
              enable = true;

              ssh.enable = true;
            };
          };

          consoleLogLevel = 0;

          loader = {
            efi.canTouchEfiVariables = true;
            systemd-boot = {
              enable = lib.mkForce (!cfg.secure-boot.enable);
              configurationLimit = 10;
            };
          };

          plymouth.enable = cfg.plymouth.enable;
        };

        zramSwap.enable = true;

        security.sudo.wheelNeedsPassword = lib.mkDefault false;
      }
      (lib.optionalAttrs (options ? boot.lanzaboote) {
        boot.lanzaboote = {
          inherit (cfg.secure-boot) enable;
          pkiBundle = "/var/lib/sbctl";
        };
      })
    ]);
  }
