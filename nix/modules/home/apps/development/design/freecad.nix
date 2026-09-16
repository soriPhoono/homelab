{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.apps.development.design.freecad;
in
  with lib; {
    options.apps.development.design.freecad = {
      enable = mkEnableOption "description";
    };

    config = mkIf cfg.enable (mkMerge [
      {
        home.packages = with pkgs; [
          freecad
        ];
      }
    ]);
  }
