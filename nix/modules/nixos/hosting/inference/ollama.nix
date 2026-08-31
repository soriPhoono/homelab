{
  lib,
  config,
  ...
}: let
  cfg = config.hosting.inference.ollama;
  inherit (lib.homelab.containers) mkContainer mkContainerOption;

  name = "ollama";
  configurationDirectory = "/var/lib/${name}";
  image =
    if cfg.acceleration == "rocm"
    then "ollama/ollama:0.15.2-rocm"
    else "ollama/ollama:0.15.2";
in
  with lib; {
    options.hosting.inference.ollama = mkContainerOption {
      inherit name;
      description = "Ollama inference server via Docker";
      extraOptions = {
        acceleration = mkOption {
          type = types.enum ["cpu" "cuda" "rocm"];
          default = "cpu";
          description = "Whether to use CPU or GPU acceleration for Ollama.";
        };
      };
    };

    config = mkIf cfg.enable (mkMerge [
      {
        assertions = [
          {
            assertion = config.hosting.platforms.docker.enable;
            message = "ollama requires the Docker hosting platform to be enabled.";
          }
        ];

        systemd.tmpfiles.rules = [
          "d ${configurationDirectory} 0750 root root -"
        ];

        virtualisation.oci-containers.containers.${name} = mkMerge [
          (mkContainer {
            inherit name cfg config image;
            serviceName = "inference";
            servicePort = 11434;
          })
          {
            environment = {
              OLLAMA_HOST = "0.0.0.0:11434";
            };

            volumes = [
              "${configurationDirectory}:/root/.ollama"
            ];

            devices = optionals (cfg.acceleration == "rocm") [
              "/dev/kfd:/dev/kfd"
              "/dev/dri:/dev/dri"
            ];

            extraOptions = optional (cfg.acceleration == "cuda") "--gpus=all";
          }
        ];
      }
    ]);
  }
