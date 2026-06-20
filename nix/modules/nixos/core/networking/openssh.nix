{
  lib,
  config,
  ...
}: let
  cfg = config.core.networking.openssh;
in
  with lib; {
    options.core.networking.openssh = {
      enable = mkEnableOption "Enable OpenSSH server for remote management" // {default = true;};
    };

    config = mkIf cfg.enable (mkMerge [
      {
        services.openssh = {
          enable = true;
          settings = {
            UseDns = true;
            PermitRootLogin = "no";
            PasswordAuthentication = false;
            KbdInteractiveAuthentication = false;
          };
        };
      }
    ]);
  }
