{
  lib,
  config,
  ...
}: let
  inherit (lib.homelab.containers) mkContainer mkContainerOption;

  name = "homebox";
  cfg = config.hosting.services.${name};
  configurationDirectory = "/var/lib/${name}";
in
  with lib; {
    options.hosting.services.${name} = mkContainerOption {
      inherit name;
      description = "Home inventory and organization system";
    };

    config = mkIf cfg.enable (mkMerge [
      {
        sops.secrets."api/homebox-api-key-pepper" = {};

        sops.templates."hosting/services/homebox.env".content = ''
          HBOX_MODE=production
          HBOX_AUTH_API_KEY_PEPPER=${config.sops.placeholder."api/homebox-api-key-pepper"}
          HBOX_OPTIONS_ALLOW_ANALYTICS=false
          HBOX_OPTIONS_GITHUB_RELEASE_CHECK=false
        '';

        systemd.tmpfiles.rules = [
          "d ${configurationDirectory} 0750 65532 65532 -"
        ];

        virtualisation.oci-containers.containers.${name} = mkMerge [
          (mkContainer {
            inherit name cfg config;
            image = "sysadminsmedia/homebox:0.26.2";
            serviceName = "inventory";
            servicePort = 7745;
          })
          {
            environmentFiles = [
              config.sops.templates."hosting/services/homebox.env".path
            ];
            volumes = [
              "${configurationDirectory}:/data"
            ];
          }
        ];
      }
    ]);
  }
