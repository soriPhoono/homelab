{
  lib,
  config,
  ...
}: let
  cfg = config.hosting.gaming;
in
  with lib; {
    imports = [
      ./wolf.nix
    ];

    options.hosting.gaming = {
      enable = mkEnableOption "Enable gaming services on device";
    };

    config = mkIf cfg.enable {
      hosting.gaming.wolf.enable = mkDefault true;
    };
  }
