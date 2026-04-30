{
  lib,
  config,
  ...
}: let
  cfg = config.hosting.automation;
in
  with lib; {
    imports = [
      ./n8n.nix
    ];

    options.hosting.automation = {
      enable = mkEnableOption "Enable hosting   automation for edge devices.";
    };

    config = mkIf cfg.enable {
      hosting = {
        automation = {
          n8n.enable = true;
        };
      };

      # systemd.tmpfiles.rules = [
      #   "d /mnt/local 0775 - - -"
      #   "d /mnt/local/automation 0775 - ${config.users.groups.automation.name} -"
      # ];

      hosting.proxy = {
        enable = true;
        services = {
          automation = {
            proxyPort = toInt config.services.n8n.environment.N8N_PORT;
            extraPaths = {};
          };
        };
      };
    };
  }
