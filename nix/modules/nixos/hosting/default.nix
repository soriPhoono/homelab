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

    options.hosting.enable = mkEnableOption "Enable shared hosting services and hardware-level hosting features";

    config = mkIf cfg.enable {
      hosting.services.homepage.enable = true;
    };
  }
