{
  lib,
  config,
  ...
}: let
  cfg = config.hosting.automation.n8n;
in
  with lib; {
    options.hosting.automation.n8n = {
      enable = mkEnableOption "Enable n8n workflow automation.";
    };

    config = mkIf cfg.enable {
      sops.secrets."hosting/n8n-auth-token" = {};

      services.n8n = {
        enable = true;
        taskRunners.enable = true;
        environment.N8N_RUNNERS_AUTH_TOKEN_FILE = config.sops.secrets."hosting/n8n-auth-token".path;
      };
    };
  }
