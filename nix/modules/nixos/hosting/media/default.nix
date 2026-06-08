{
  lib,
  config,
  ...
}: let
  uids = import ../uids.nix;
  cfg = config.hosting.media;
in
  with lib; {
    imports = [
      ./qbittorrent.nix
      ./prowlarr.nix

      ./flaresolverr.nix
      ./sonarr.nix
      ./radarr.nix

      ./seerr.nix

      ./jellyfin.nix
    ];

    options.hosting.media = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable media hosting services";
      };
    };

    config = mkIf cfg.enable {
      # Jellyfin
      hosting = {
        media = {
          qbittorrent.enable = true;
          prowlarr.enable = true;
          sonarr.enable = true;
          radarr.enable = true;
          seerr.enable = true;
          jellyfin = {
            enable = true;
          };
        };
      };

      # Create groups
      users.groups.media = {
        gid = mkDefault uids.media.group.gid;
      };

      # Ensure config directory exists
      systemd.tmpfiles.rules = [
        "d /mnt/local 0775 - - -"
        "d /mnt/local/media 0775 - ${config.users.groups.media.name} -"
        "d /mnt/local/media/movies 0775 ${toString config.hosting.media.radarr.userUid} ${toString config.users.groups.media.gid} -"
        "d /mnt/local/media/shows 0775 ${toString config.hosting.media.sonarr.userUid} ${toString config.users.groups.media.gid} -"
        "d /mnt/local/media/downloads 0775 ${toString config.hosting.media.qbittorrent.userUid} ${toString config.users.groups.media.gid} -"
      ];
    };
  }
