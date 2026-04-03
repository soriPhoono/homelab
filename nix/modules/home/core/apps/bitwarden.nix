{
  lib,
  config,
  ...
}: let
  cfg = config.core.apps.bitwarden;
in
  with lib; {
    options.core.apps.bitwarden = {
      enable = mkEnableOption "Enable bitwarden";

      email = mkOption {
        type = with types; nullOr str;
        description = "Email to use for bitwarden";
        default = null;
        example = "johnDoe@gmail.com";
      };
    };

    config = mkIf cfg.enable {
      programs.rbw = {
        enable = true;
        settings.email =
          if config.core.email.enable
          then
            (
              if (config.accounts.email.accounts ? "bitwarden")
              then config.accounts.email.accounts.bitwarden.address
              else config.accounts.email.accounts.primary.address
            )
          else cfg.email;
      };
    };
  }
