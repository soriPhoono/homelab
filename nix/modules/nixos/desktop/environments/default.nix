{
  lib,
  config,
  ...
}: let
  desktopCfg = config.desktop;
  cfg = desktopCfg.environments;
in
  with lib; {
    imports = [
      ./display_managers
      ./managers

      ./cosmic.nix
      ./kde.nix
    ];

    options.desktop.environments = {
      selectedEnvironment = mkOption {
        type = with types; nullOr (enum ["kde" "gnome" "cosmic"]);
        default = null;
        description = "The resolved desktop environment selected for display managers and features.";
      };
    };

    config = mkIf desktopCfg.enable (mkMerge [
      {
        desktop.environments = {
          display_managers = {
            greetd.enable = mkIf (cfg.selectedEnvironment == null) true;
            sddm.enable = mkIf (cfg.selectedEnvironment == "kde") true;
          };
        };
      }
    ]);
  }
