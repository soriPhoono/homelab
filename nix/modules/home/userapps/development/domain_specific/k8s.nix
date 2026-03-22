{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.userapps.development.domain_specific.k8s;
in
  with lib; {
    options.userapps.development.domain_specific.k8s = {
      enable = mkEnableOption "Enable k8s desktop tools";
    };

    config = mkIf cfg.enable {
      home.packages = with pkgs; [
        lens
      ];
    };
  }
