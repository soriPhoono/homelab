# TODO: Fix this
{
  lib,
  config,
  ...
}: let
  cfg = config.desktop.services.printing;
in {
  options.desktop.services.printing = {
    enable = lib.mkEnableOption "Enable printing on the system";
  };

  config = lib.mkIf cfg.enable {
    services.avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };

    services.printing = {
      enable = true;
      cups-pdf.enable = true;
    };
  };
}
