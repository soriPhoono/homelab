{
  lib,
  config,
  ...
}: let
  uids = import ../uids.nix;
  cfg = config.hosting.ai.mongodb;
in
  with lib; {
    options.hosting.ai.mongodb = {
      enable = mkEnableOption "MongoDB database for AI memory/vector store";

      image = mkOption {
        type = types.str;
        default = "mongo:7";
        description = ''
          Docker image for MongoDB.
          Uses the official MongoDB Community image from Docker Hub.
        '';
      };

      port = mkOption {
        type = types.port;
        default = 27017;
        description = "MongoDB port";
      };

      configDir = mkOption {
        type = types.str;
        default = "/var/lib/mongodb";
        description = "Host directory for MongoDB data persistence";
      };

      userUid = mkOption {
        type = types.int;
        default = uids.ai.mongodb.uid;
        description = "UID for the MongoDB data directory ownership";
      };

      userGid = mkOption {
        type = types.int;
        default = uids.ai.mongodb.gid;
        description = "GID for the MongoDB data directory ownership";
      };
    };

    config = mkIf cfg.enable {
      hosting.platforms.docker.enable = mkDefault true;

      systemd.tmpfiles.rules = [
        "d ${cfg.configDir} 0755 ${toString cfg.userUid} ${toString cfg.userGid} -"
        # MongoDB container runs as UID 999 (mongodb user inside the image).
        # Match ownership so the container can write to the bind-mounted volume.
        "d ${cfg.configDir}/data 0755 999 999 -"
      ];

      virtualisation.oci-containers.containers.mongodb = {
        inherit (cfg) image;
        autoStart = true;
        networks = ["mongodb"];

        cmd = [
          "mongod"
          "--port"
          (toString cfg.port)
          "--bind_ip"
          "0.0.0.0"
        ];

        volumes = [
          "${cfg.configDir}/data:/data/db"
        ];
      };
    };
  }
