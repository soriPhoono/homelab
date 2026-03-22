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
        packages = lib.mkOption {
          type = lib.types.raw;
          default = pkgs.linuxPackages;
          description = "Kernel packages to use";
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
          default = {
            name = "bgrt";
            package = pkgs.plymouth-themes.bgrt;
          };
          description = "Plymouth theme to use";
        };
      };

      initrd = {
        ssh.enable = mkEnableOption "Enable SSH in initrd";
      };
    };

    config = lib.mkIf cfg.enable (lib.mkMerge [
      {
        security = {
          sudo.wheelNeedsPassword = lib.mkDefault false;
          tpm2 = {
            enable = true;
            pkcs11.enable = true; # NOTE: Required for things like secure boot and TPM-backed TOTP
          };
        };

        boot = {
          kernelPackages = cfg.kernel.packages;
          kernelParams =
            (optionals cfg.plymouth.enable [
              "quiet"
              "systemd.show_status=false"
              "udev.log_level=3"
            ])
            ++ cfg.kernel.params;

          initrd = {
            verbose = !cfg.plymouth.enable;
            systemd.enable = true;
            network = {
              enable = true;
              ssh.enable = cfg.initrd.ssh.enable;
            };
          };

          consoleLogLevel = 0;

          loader = {
            efi.canTouchEfiVariables = true;
            systemd-boot = {
              enable = lib.mkForce (!cfg.secure-boot.enable);
              configurationLimit = 3;
            };
          };

          plymouth = {
            inherit (cfg.plymouth) enable;

            font = "${pkgs.nerdfonts}/share/fonts/truetype/NerdFonts/SauceCodePro/SauceCodeProNerdFontMono-Regular.ttf";
            theme = cfg.plymouth.theme.name;
            themePackages = [
              cfg.plymouth.theme.package
            ];
          };
        };

        zramSwap.enable = true;
      }
      (lib.optionalAttrs (options ? boot.lanzaboote) {
        # TODO: this needs upgrading and refactoring
        boot.lanzaboote = {
          inherit (cfg.secure-boot) enable;
          pkiBundle = "/var/lib/sbctl";
        };
      })
    ]);
  }
