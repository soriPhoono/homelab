{
  lib,
  pkgs,
  config,
  ...
}: let
  inherit (lib.homelab.containers) mkContainer mkContainerOption;

  name = "forgejo-actions-runner";
  cfg = config.hosting.development.${name};
  configurationDirectory = "/var/lib/${name}";
  instanceUrl = "https://${cfg.instanceHostname}";
  runnerConfig = pkgs.writeText "forgejo-runner-config.yaml" ''
    log:
      level: info
    runner:
      file: /data/.runner
      capacity: 2
      timeout: 3h
      labels:
        - "docker:docker://data.forgejo.org/oci/node:22-bookworm@sha256:8a34c4ab3ea2c5cd194f07e317b2a8f09461d3c8b05c4e34c8ccd56d56024c4d"
        - "nix:docker://nixos/nix:2.30.1"
    container:
      network: tailscale
      docker_host: unix:///var/run/docker.sock
      force_pull: true
      valid_volumes:
        - "**"
  '';
in
  with lib; {
    options.hosting.development.${name} =
      (mkContainerOption {
        inherit name;
        description = "Forgejo Actions CI runner";
      })
      // {
        instanceHostname = mkOption {
          type = types.str;
          default = "${config.networking.hostName}-forgejo.xerus-augmented.ts.net";
          description = "Hostname of the Forgejo instance used by this runner.";
        };

        runnerName = mkOption {
          type = types.str;
          default = "${config.networking.hostName}-docker";
          description = "Name shown for this runner in Forgejo.";
        };

        registrationTokenSecret = mkOption {
          type = types.str;
          default = "api/forgejo-runner-registration-token";
          description = "SOPS secret containing the Forgejo runner registration token.";
        };
      };

    config = mkIf cfg.enable {
      assertions = [
        {
          assertion = config.hosting.platforms.docker.enable;
          message = "forgejo-actions-runner requires the Docker hosting platform to be enabled.";
        }
      ];

      sops.secrets.${cfg.registrationTokenSecret} = {};

      systemd.tmpfiles.rules = [
        "d ${configurationDirectory} 0750 1000 1000 -"
      ];

      virtualisation.oci-containers.containers.${name} = mkMerge [
        (mkContainer {
          inherit name cfg config;
          image = "data.forgejo.org/forgejo/runner:13.1.0";
        })
        {
          networks = ["tailscale"];
          dependsOn = ["buildkit"];
          entrypoint = "/bin/sh";
          cmd = [
            "-ec"
            ''
              while [ -z "''${FORGEJO_RUNNER_REGISTRATION_TOKEN:-}" ]; do
                echo "Waiting for a Forgejo runner registration token..."
                sleep 30
              done
              if [ ! -f /data/.runner ]; then
                forgejo-runner register --no-interactive \
                  --instance "${instanceUrl}" \
                  --token "''${FORGEJO_RUNNER_REGISTRATION_TOKEN}" \
                  --name "${cfg.runnerName}" \
                  --labels "docker:docker://data.forgejo.org/oci/node:22-bookworm@sha256:8a34c4ab3ea2c5cd194f07e317b2a8f09461d3c8b05c4e34c8ccd56d56024c4d,nix:docker://nixos/nix:2.30.1"
              fi
              exec forgejo-runner --config /data/config.yaml daemon
            ''
          ];
          environment = {
            DOCKER_HOST = "unix:///var/run/docker.sock";
          };
          environmentFiles = [
            config.sops.templates."hosting/development/forgejo-actions-runner.env".path
          ];
          volumes = [
            "${configurationDirectory}:/data"
            "${runnerConfig}:/data/config.yaml:ro"
            "/var/run/docker.sock:/var/run/docker.sock"
          ];
        }
      ];

      sops.templates."hosting/development/forgejo-actions-runner.env".content = ''
        FORGEJO_RUNNER_REGISTRATION_TOKEN=${config.sops.placeholder.${cfg.registrationTokenSecret}}
      '';
    };
  }
