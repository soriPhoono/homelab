{
  lib,
  config,
  ...
}: let
  modulePath = "userapps.development.editors.antigravity";
  cfg = config.${modulePath};
in
  with lib; {
    options.${modulePath} = {
      enable = mkEnableOption "Enable antigravity editor configuration and vscode extension integration";
    };

    config = mkIf cfg.enable (mkMerge [
      {
      }
    ]);
  }
