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
    imports = [
      ./zram.nix
      ./plymouth.nix
    ];

    options.core.boot = {
      enable = lib.mkEnableOption ''
        Enable system boot configuration with systemd-boot and ZRAM swap
      '';
      secure-boot = lib.mkEnableOption ''
        Enable bootloader hardening features via lanzaboote dependency
      '';

      kernel = {
        packages = lib.mkOption {
          type = lib.types.raw;
          default = pkgs.linuxPackages;
          description = ''
            Linux kernel packages to compile against for the system, use to adjust performance or apply patches via overlays.
          '';
          example = pkgs.linuxPackages-rt_latest;
        };
        params = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [];
          description = ''
            Kernel parameters to use to augment system performance
          '';
        };
      };
    };

    config = lib.mkIf cfg.enable (
      lib.mkMerge [
        {
          security.tpm2 = {
            enable = true;
            pkcs11.enable = true;
          };

          boot = {
            kernelPackages = cfg.kernel.packages;
            kernelParams =
              (optionals config.core.boot.plymouth.enable [
                "quiet"
                "systemd.show_status=false"
                "udev.log_level=3"
              ])
              ++ cfg.kernel.params;

            initrd = {
              verbose = !config.core.boot.plymouth.enable;
              systemd.enable = true;
            };

            consoleLogLevel = 0;

            supportedFilesystems = [
              # Linux
              "ext4"
              "btrfs"
              # Windows
              "ntfs"
              # Apple
              "apfs"
            ];

            loader = {
              efi.canTouchEfiVariables = true;
              systemd-boot = {
                enable = lib.mkForce (!cfg.secure-boot);
                configurationLimit = 3;
              };
            };
          };
        }
        (lib.optionalAttrs (options ? boot.lanzaboote) {
          # TODO: this needs upgrading and refactoring
          boot.lanzaboote = {
            inherit (cfg.secure-boot) enable;
            pkiBundle = "/var/lib/sbctl";
          };
        })
        (mkIf (cfg.secure-boot && !(options ? boot.lanzaboote)) {
          warnings = [
            "secure-boot is enabled but lanzaboote is not available (add lanzaboote to nixos modules)"
          ];
        })
      ]
    );
  }
