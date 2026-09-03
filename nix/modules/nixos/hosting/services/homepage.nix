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
  caddyRoute = {
    name = serviceHostname;
    host = "${serviceHostname}.xerus-augmented.ts.net";
    port = 3000;
    policy = "one_factor";
  };

  dockerConfiguration = pkgs.writeText "homepage-docker.yaml" ''
    local:
      socket: /var/run/docker.sock
  '';
  bookmarksConfiguration = pkgs.writeText "homepage-bookmarks.yaml" "[]\n";
  customCssConfiguration = pkgs.writeText "homepage-custom.css" "";
  customJsConfiguration = pkgs.writeText "homepage-custom.js" "";
  kubernetesConfiguration = pkgs.writeText "homepage-kubernetes.yaml" ''
    # Kubernetes integration disabled.
  '';
  proxmoxConfiguration = pkgs.writeText "homepage-proxmox.yaml" ''
    # Proxmox integration disabled.
  '';
  servicesConfiguration = pkgs.writeText "homepage-services.yaml" "[]\n";
  widgetsConfiguration = pkgs.writeText "homepage-widgets.yaml" "[]\n";
  settingsConfiguration = pkgs.writeText "homepage-settings.yaml" ''
    title: Homelab
  '';
  configuration = pkgs.runCommand "homepage-config" {} ''
    mkdir -p "$out"
    mkdir "$out/logs"
    cp ${bookmarksConfiguration} "$out/bookmarks.yaml"
    cp ${customCssConfiguration} "$out/custom.css"
    cp ${customJsConfiguration} "$out/custom.js"
    cp ${dockerConfiguration} "$out/docker.yaml"
    cp ${kubernetesConfiguration} "$out/kubernetes.yaml"
    cp ${proxmoxConfiguration} "$out/proxmox.yaml"
    cp ${servicesConfiguration} "$out/services.yaml"
    cp ${settingsConfiguration} "$out/settings.yaml"
    cp ${widgetsConfiguration} "$out/widgets.yaml"
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
          caddy = caddyRoute;
        })
        {
          environment = {
            HOMEPAGE_ALLOWED_HOSTS = "${serviceHostname}.xerus-augmented.ts.net,localhost,127.0.0.1";
          };
          user = "0:0";
          volumes = [
            "${configuration}:/app/config:ro"
            "homepage-logs:/app/config/logs"
            "/var/run/docker.sock:/var/run/docker.sock:ro"
          ];
        }
      ];

      hosting.proxy.caddy.routes.${name} = caddyRoute;
    };
  }
