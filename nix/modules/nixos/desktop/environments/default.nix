{
  lib,
  config,
  ...
}: let
  inherit (lib) attrNames filterAttrs;

  desktopCfg = config.desktop;
  cfg = desktopCfg.environments;

  environments = map (name: builtins.substring 0 ((builtins.stringLength name) - 4) name) (
    attrNames (
      filterAttrs (name: type: type == "regular" && name != "default.nix") (builtins.readDir ./.)
    )
  );
in
  with lib; {
    imports = [
      ./display_managers
      ./managers

      ./cosmic.nix
      ./kde.nix
    ];

    options.desktop.environments = {
      variant = lib.mkOption {
        type = with types; nullOr (enum environments);
        default = null;
        description = "The desktop environment to be installed.";
      };
    };

    config = mkIf desktopCfg.enable (mkMerge [
      {
        desktop.environments = {
          display_managers.greetd.enable = mkIf (cfg.variant == null) true;
        };
      }
    ]);
  }
