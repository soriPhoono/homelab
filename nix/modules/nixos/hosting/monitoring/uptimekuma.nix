{
  lib,
  config,
  ...
}: let
  inherit (lib.homelab.containers) mkContainer mkContainerOption;

  optionName = "uptimekuma";
  containerName = "uptime-kuma";
  cfg = config.hosting.monitoring.${optionName};
  configurationDirectory = "/var/lib/${containerName}";
in
  with lib; {
    options.hosting.monitoring.${optionName} = mkContainerOption {
      name = containerName;
      description = "Website and service uptime monitoring";
    };

    config = mkIf cfg.enable {
      assertions = [
        {
          assertion = config.hosting.platforms.docker.enable;
          message = "uptimekuma requires the Docker hosting platform to be enabled.";
        }
      ];

      systemd.tmpfiles.rules = [
        "d ${configurationDirectory} 0750 1000 1000 -"
      ];

      virtualisation.oci-containers.containers.${containerName} = mkMerge [
        (mkContainer {
          name = containerName;
          inherit cfg config;
          image = "louislam/uptime-kuma:2.0.0";
          serviceName = "uptime";
          servicePort = 3001;
        })
        {
          environment = {
            TZ = config.time.timeZone;
          };
          labels = {
            "wud.watch" = "true";
            "wud.tag.include" = ''^\d+\.\d+\.\d+$'';
          };
          volumes = [
            "${configurationDirectory}:/app/data"
          ];
        }
      ];
    };
  }
