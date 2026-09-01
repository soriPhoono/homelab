{
  lib,
  config,
  ...
}: let
  inherit (lib.homelab.containers) mkContainer mkContainerOption;

  name = "dozzle";
  cfg = config.hosting.monitoring.${name};
in
  with lib; {
    options.hosting.monitoring.${name} = mkContainerOption {
      inherit name;
      description = "Real-time Docker log viewer";
    };

    config = mkIf cfg.enable {
      assertions = [
        {
          assertion = config.hosting.platforms.docker.enable;
          message = "dozzle requires the Docker hosting platform to be enabled.";
        }
      ];

      virtualisation.oci-containers.containers.${name} = mkMerge [
        (mkContainer {
          inherit name cfg config;
          image = "amir20/dozzle:v10.8.0";
          serviceName = "logs";
          servicePort = 8080;
        })
        {
          environment = {
            DOZZLE_NO_ANALYTICS = "true";
            DOZZLE_LEVEL = "info";
          };
          volumes = [
            "/var/run/docker.sock:/var/run/docker.sock:ro"
          ];
        }
      ];
    };
  }
