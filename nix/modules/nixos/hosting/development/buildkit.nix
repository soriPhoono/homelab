{
  lib,
  config,
  ...
}: let
  inherit (lib.homelab.containers) mkContainer mkContainerOption;

  name = "buildkit";
  cfg = config.hosting.development.${name};
  configurationDirectory = "/var/lib/${name}";
in
  with lib; {
    options.hosting.development.${name} = mkContainerOption {
      inherit name;
      description = "Rootless BuildKit daemon for Forgejo Actions image builds";
    };

    config = mkIf cfg.enable {
      assertions = [
        {
          assertion = config.hosting.platforms.docker.enable;
          message = "buildkit requires the Docker hosting platform to be enabled.";
        }
      ];

      systemd.tmpfiles.rules = [
        "d ${configurationDirectory} 0750 1000 1000 -"
      ];

      virtualisation.oci-containers.containers.${name} = mkMerge [
        (mkContainer {
          inherit name cfg config;
          image = "moby/buildkit:v0.24.0-rootless";
        })
        {
          networks = ["tailscale"];
          environment = {
            BUILDKITD_FLAGS = "--addr tcp://0.0.0.0:1234 --root /var/lib/buildkit --oci-worker-no-process-sandbox";
          };
          volumes = [
            "${configurationDirectory}:/var/lib/buildkit"
          ];
          extraOptions = [
            "--security-opt=seccomp=unconfined"
            "--security-opt=apparmor=unconfined"
            "--security-opt=systempaths=unconfined"
          ];
        }
      ];
    };
  }
