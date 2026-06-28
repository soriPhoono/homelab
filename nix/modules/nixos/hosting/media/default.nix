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

      ./navidrome.nix

      ./lidarr.nix

      ./bookshelf.nix
      ./booklore.nix
    ];

    options.hosting.media = {
      enable = mkEnableOption "Enable media server stack on device";
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
          navidrome = {
            enable = true;
          };
          lidarr = {
            enable = true;
          };
          bookshelf = {
            enable = true;
          };
          booklore = {
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
        "d /mnt/local/media/music 0775 ${toString config.hosting.media.lidarr.userUid} ${toString config.users.groups.media.gid} -"
        "d /mnt/local/media/books 0775 ${toString config.hosting.media.bookshelf.userUid} ${toString config.users.groups.media.gid} -"
        "d /mnt/local/media/bookdrop 0775 ${toString config.hosting.media.bookshelf.userUid} ${toString config.users.groups.media.gid} -"
      ];
    };
  }
