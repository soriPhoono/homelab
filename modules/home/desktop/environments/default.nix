{
  lib,
  config,
  ...
}: let
  cfg = config.desktop.environments;
in
  with lib; {
    imports = [
      ./hyprland
    ];

    options.desktop.environments = {
      enable = mkEnableOption "Enable desktop environments module";
    };

    config = mkIf cfg.enable {
      desktop.enable = true;
    };
  }
