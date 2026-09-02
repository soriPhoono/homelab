{
  lib,
  pkgs,
  config,
  ...
}: let
  inherit (lib.homelab.containers) mkContainer mkContainerOption;

  name = "homepage";
  cfg = config.hosting.services.${name};
  serviceHostname = "${config.networking.hostName}-${name}";

  dockerConfiguration = pkgs.writeText "homepage-docker.yaml" ''
    local:
      socket: /var/run/docker.sock
  '';
  servicesConfiguration = pkgs.writeText "homepage-services.yaml" "[]\n";
  settingsConfiguration = pkgs.writeText "homepage-settings.yaml" ''
    title: Homelab
  '';
  configuration = pkgs.runCommand "homepage-config" {} ''
    mkdir -p "$out"
    cp ${dockerConfiguration} "$out/docker.yaml"
    cp ${servicesConfiguration} "$out/services.yaml"
    cp ${settingsConfiguration} "$out/settings.yaml"
  '';
in
  with lib; {
    options.hosting.services.${name} = mkContainerOption {
      inherit name;
      description = "A dashboard for published homelab services";
    };

    config = mkIf cfg.enable {
      virtualisation.oci-containers.containers.${name} = mkMerge [
        (mkContainer {
          inherit name cfg config;
          image = "ghcr.io/gethomepage/homepage:v2.2.0";
          serviceName = name;
          servicePort = 3000;
        })
        {
          environment = {
            HOMEPAGE_ALLOWED_HOSTS = "${serviceHostname}.xerus-augmented.ts.net,localhost,127.0.0.1";
          };
          user = "0:0";
          volumes = [
            "${configuration}:/app/config:ro"
            "/var/run/docker.sock:/var/run/docker.sock:ro"
          ];
        }
      ];
    };
  }
