{
  lib,
  config,
  ...
}: let
  cfg = config.core.secrets;
in {
  options.core.secrets = {
    enable = lib.mkEnableOption "Enable core secrets management";

    defaultSopsFile = lib.mkOption {
      type = with lib.types; nullOr path;
      description = "Default sops database";
    };

    ageKeyFile = lib.mkOption {
      type = lib.types.path;
      default = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
      description = ''
        The path to the age key file.
        On NixOS, this is automatically provisioned by the system secrets module.
        On non-NixOS systems, you must ensure this key is present.
      '';
    };

    environment = {
      enable = lib.mkEnableOption "Enable environment secrets";

      sopsFile = lib.mkOption {
        type = lib.types.path;
        description = "Sops file for environment secrets";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.defaultSopsFile != null;
        message = "core.secrets.enable is true, but core.secrets.defaultSopsFile is not set.";
      }
    ];

    sops = {
      inherit (cfg) defaultSopsFile;

      # Use the centrally defined age key file
      age.keyFile = cfg.ageKeyFile;

      secrets.environment = lib.mkIf cfg.environment.enable {
        format = "dotenv";

        inherit (cfg.environment) sopsFile;
      };
    };
  };
}
