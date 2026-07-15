{lib, ...}: let
  stacks = {
    media = {
      users = [
        "qbittorrent"
        "prowlarr"
        "sonarr"
        "radarr"
        "jellyfin"
        "seerr"
      ];
    };

    proxy = {
      users = [
        "traefik"
      ];
    };
  };
in
  with lib; {
    options.hosting.uuids = mkOption {
      type = types.attrsOf (types.submodule ({name, ...}: {
        options = {
          users = mkOption {
            type = types.listOf types.str;
            default = [];
            description = "List of users to assign UIDs to";
          };

          groups = mkOption {
            type = types.listOf types.str;
            default = [];
            description = "List of groups to assign GIDs to";
          };
        };

        config = {
          users = stacks.${name}.users;
          groups = [name] ++ stacks.${name}.users;
        };
      }));

      description = "Hosts the user and group ids for all hosting services";
      default = {};
    };
  }
