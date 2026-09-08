{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.core.hardware.hid.razer;
in
  with lib; {
    options.core.hardware.hid.razer = {
      enable = mkEnableOption "Enable openrazer support";
    };

    config = mkIf cfg.enable (mkMerge [
      {
        environment.systemPackages = with pkgs; [
          polychromatic
        ];

        hardware.openrazer = {
          enable = true;
          users = builtins.attrNames config.core.users;
        };
      }
    ]);
  }
