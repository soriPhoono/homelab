{
  lib,
  config,
  ...
}: let
  inherit (lib.homelab.containers) mkContainer mkContainerOption;

  name = "memos";
  cfg = config.hosting.services.${name};
  configurationDirectory = "/var/lib/${name}";
in
  with lib; {
    options.hosting.services.${name} = mkContainerOption {
      inherit name;
      description = "Markdown-first personal notes and memory service";
    };

    config = mkIf cfg.enable (mkMerge [
      {
        systemd.tmpfiles.rules = [
          "d ${configurationDirectory} 0750 10001 10001 -"
        ];

        virtualisation.oci-containers.containers.${name} = mkMerge [
          (mkContainer {
            inherit name cfg config;
            image = "neosmemo/memos:stable";
            serviceName = "notes";
            servicePort = 5230;
          })
          {
            environment = {
              MEMOS_DATA = "/var/opt/memos";
              MEMOS_DRIVER = "sqlite";
              MEMOS_LOG_LEVEL = "info";
              MEMOS_PORT = "5230";
            };
            volumes = [
              "${configurationDirectory}:/var/opt/memos"
            ];
          }
        ];
      }
    ]);
  }
