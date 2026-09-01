{
  lib,
  config,
  ...
}: let
  inherit (lib.homelab.containers) mkContainer mkContainerOption;

  name = "forgejo";
  cfg = config.hosting.services.${name};
  configurationDirectory = "/var/lib/${name}";
in
  with lib; {
    options.hosting.services.${name} =
      (mkContainerOption {
        inherit name;
        description = "Self-hosted Git forge with Forgejo Actions support";
      })
      // {
        hostname = mkOption {
          type = types.str;
          default = "${config.networking.hostName}-forgejo.xerus-augmented.ts.net";
          description = "Hostname used for Forgejo's public URL and SSH configuration.";
        };

        sshPort = mkOption {
          type = types.port;
          default = 2222;
          description = "Host port exposed for Forgejo SSH access.";
        };
      };

    config = mkIf cfg.enable {
      assertions = [
        {
          assertion = config.hosting.platforms.docker.enable;
          message = "forgejo requires the Docker hosting platform to be enabled.";
        }
        {
          assertion = cfg.sshPort != 22;
          message = "forgejo.sshPort must not be 22 because the host OpenSSH server uses port 22.";
        }
      ];

      systemd.tmpfiles.rules = [
        "d ${configurationDirectory} 0750 1000 1000 -"
      ];

      virtualisation.oci-containers.containers.${name} = mkMerge [
        (mkContainer {
          inherit name cfg config;
          image = "codeberg.org/forgejo/forgejo:16.0.3";
          serviceName = "forgejo";
          servicePort = 3000;
        })
        {
          environment = {
            USER_UID = "1000";
            USER_GID = "1000";
            FORGEJO__actions__ENABLED = "true";
            FORGEJO__database__DB_TYPE = "sqlite3";
            FORGEJO__security__INSTALL_LOCK = "true";
            FORGEJO__server__DOMAIN = cfg.hostname;
            FORGEJO__server__HTTP_PORT = "3000";
            FORGEJO__server__ROOT_URL = "https://${cfg.hostname}/";
            FORGEJO__server__SSH_DOMAIN = cfg.hostname;
            FORGEJO__server__SSH_PORT = toString cfg.sshPort;
            FORGEJO__server__SSH_LISTEN_PORT = toString cfg.sshPort;
            FORGEJO__server__START_SSH_SERVER = "true";
          };
          volumes = [
            "${configurationDirectory}:/data"
          ];
          ports = [
            "${toString cfg.sshPort}:${toString cfg.sshPort}"
          ];
        }
      ];
    };
  }
