{
  lib,
  config,
  ...
}: let
  cfg = config.hosting;
in
  with lib; {
    imports = [
      ./platforms
      ./gaming
      ./proxy
      ./media
      ./monitoring
      ./services
      ./development
      ./inference
    ];

    options.hosting.enable = mkEnableOption "Enable hardware level features that respond to hosting module's presence";

    config = mkIf cfg.enable (mkMerge [
      {
      }
    ]);
  }
