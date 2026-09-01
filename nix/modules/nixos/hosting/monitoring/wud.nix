{
  lib,
  config,
  ...
}: let
  inherit (lib.homelab.containers) mkContainer mkContainerOption;

  name = "wud";
  cfg = config.hosting.monitoring.${name};
  configurationDirectory = "/var/lib/${name}";
in
  with lib; {
    options.hosting.monitoring.${name} = mkContainerOption {
      inherit name;
      description = "Docker image update monitoring and notifications";
      extraOptions = {
        recipient = mkOption {
          type = types.str;
          default = "soriphoono@gmail.com";
          description = "Email address that receives Docker image update notifications.";
        };
      };
    };

    config = mkIf cfg.enable (mkMerge [
      {
        assertions = [
          {
            assertion = config.hosting.platforms.docker.enable;
            message = "wud requires the Docker hosting platform to be enabled.";
          }
        ];

        sops.secrets = {
          "api/smtp-password" = {};
          "api/smtp-from-email" = {};
        };

        sops.templates."hosting/monitoring/wud.env".content = ''
          WUD_TRIGGER_SMTP_RESEND_HOST=smtp.resend.com
          WUD_TRIGGER_SMTP_RESEND_PORT=465
          WUD_TRIGGER_SMTP_RESEND_TLS_ENABLED=true
          WUD_TRIGGER_SMTP_RESEND_USER=resend
          WUD_TRIGGER_SMTP_RESEND_PASS=${config.sops.placeholder."api/smtp-password"}
          WUD_TRIGGER_SMTP_RESEND_FROM_ADDRESS=${config.sops.placeholder."api/smtp-from-email"}
          WUD_TRIGGER_SMTP_RESEND_FROM_NAME=Homelab Docker updates
          WUD_TRIGGER_SMTP_RESEND_TO=${cfg.recipient}
          WUD_TRIGGER_SMTP_RESEND_AUTO=true
          WUD_TRIGGER_SMTP_RESEND_MODE=batch
          WUD_TRIGGER_SMTP_RESEND_ONCE=true
          WUD_TRIGGER_SMTP_RESEND_THRESHOLD=all
        '';

        systemd.tmpfiles.rules = [
          "d ${configurationDirectory} 0750 root root -"
        ];

        virtualisation.oci-containers.containers.${name} = mkMerge [
          (mkContainer {
            inherit name config;
            cfg = cfg // {container = cfg.container // {publication = [];};};
            image = "getwud/wud:8.3.1";
          })
          {
            environment = {
              TZ = config.time.timeZone;
              WUD_LOG_LEVEL = "info";
              WUD_SERVER_PORT = "3000";
              # Check for image updates once daily at 08:00 in the configured timezone.
              WUD_WATCHER_LOCAL_CRON = "0 8 * * *";
              WUD_WATCHER_LOCAL_WATCHALL = "false";
              WUD_WATCHER_LOCAL_WATCHATSTART = "true";
              WUD_WATCHER_LOCAL_WATCHBYDEFAULT = "true";
              WUD_WATCHER_LOCAL_WATCHEVENTS = "true";
            };

            environmentFiles = [
              config.sops.templates."hosting/monitoring/wud.env".path
            ];

            labels = {
              "wud.watch" = "true";
              "wud.tag.include" = ''^\d+\.\d+\.\d+$'';
              "wud.link.template" = ''https://github.com/getwud/wud/releases/tag/''${major}.''${minor}.''${patch}'';
            };

            volumes = [
              "${configurationDirectory}:/store"
              "/var/run/docker.sock:/var/run/docker.sock:ro"
            ];
          }
        ];
      }
    ]);
  }
