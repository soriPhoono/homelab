{
  lib,
  config,
  ...
}: let
  inherit (lib.homelab.containers) mkContainer mkContainerOption;

  optionName = "openwebui";
  name = "open-webui";
  cfg = config.hosting.inference.${optionName};
  configurationDirectory = "/var/lib/${name}";
in
  with lib; {
    options.hosting.inference.${optionName} = mkContainerOption {
      inherit name;
      description = "Open WebUI local AI chat interface";
    };

    config = mkIf cfg.enable (mkMerge [
      {
        hosting.enable = true;

        assertions = [
          {
            assertion = config.hosting.platforms.docker.enable;
            message = "openwebui requires the Docker hosting platform to be enabled.";
          }
        ];

        hosting.inference.ollama.enable = true;

        systemd.tmpfiles.rules = [
          "d ${configurationDirectory} 0750 root root -"
        ];

        virtualisation.oci-containers.containers.${name} = mkMerge [
          (mkContainer {
            inherit name cfg config;
            image = "ghcr.io/open-webui/open-webui:v0.11.3";
            serviceName = "chat";
            servicePort = 8080;
            homepage = {
              group = "Inference";
              name = "Open WebUI";
              icon = "open-webui.png";
              description = "Local AI chat";
              serviceName = "chat";
            };
          })
          {
            dependsOn = ["ollama"];
            environment = {
              OLLAMA_BASE_URL = "http://ollama:11434";
              TZ = config.time.timeZone;
              WEBUI_AUTH = "True";
            };
            volumes = [
              "${configurationDirectory}:/app/backend/data"
            ];
          }
        ];
      }
    ]);
  }
