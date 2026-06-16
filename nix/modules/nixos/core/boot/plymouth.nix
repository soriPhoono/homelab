{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.core.boot.plymouth;
in
  with lib; {
    options.core.boot.plymouth = {
      enable = lib.mkEnableOption ''
        Enable nice boot splash screen like on Ubuntu Linux
      '';
      theme = mkOption {
        type = with types;
          nullOr (
            submodule (
              {config, ...}: {
                options = {
                  name = mkOption {
                    type = str;
                    default = "connect";
                  };
                  package = mkOption {
                    type = types.package;
                    default = pkgs.adi1090x-plymouth-themes.override {
                      selected_themes = [
                        config.name
                      ];
                    };
                  };
                };
              }
            )
          );
        default = {};
        description = ''
          Theme to use to style plymouth, accepts custom themes from overlays
        '';
        example = {
          name = "nixos-bgrt";
          package = pkgs.nixos-nixos-bgrt-plymouth;
        };
      };
    };

    config = mkIf cfg.enable (mkMerge [
      {
        boot.plymouth = {
          inherit (cfg) enable;

          theme = lib.mkIf (cfg.theme != null) (lib.mkForce cfg.theme.name);
          themePackages = lib.mkIf (cfg.theme != null) (lib.mkForce [cfg.theme.package]);
        };
      }
    ]);
  }
