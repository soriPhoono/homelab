{
  lib,
  config,
  ...
}: let
  cfg = config.core.checks;
in {
  options.core.checks = {
    enable = lib.mkEnableOption "Enable general environment health checks";

    checkAgeKey = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Check if the age key file exists if secrets are enabled";
    };
  };

  config = lib.mkIf cfg.enable {
    # Home-level warnings and assertions can go here
    warnings =
      lib.optional (cfg.checkAgeKey && config.core.secrets.enable && !(builtins.pathExists config.core.secrets.ageKeyFile))
      "Age key file '${config.core.secrets.ageKeyFile}' does not exist. Secrets decryption may fail.";
  };
}
