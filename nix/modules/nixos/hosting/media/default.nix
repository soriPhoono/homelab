{
  lib,
  config,
  ...
}: let
  cfg = config.hosting.media;
in
  with lib; {
    imports = [
      ./qbittorrent.nix
      ./jellyfin.nix
    ];

    options.hosting.media = {
      enable = mkEnableOption "Enable media server stack on device";
    };

    config = mkIf cfg.enable {
      hosting = {
        uuids.media = {};

        media = {
          jellyfin.enable = true;
          qbittorrent.enable = true;
        };
      };

      # Ensure config directory exists
      systemd.tmpfiles.rules = [
        "d /mnt/local/media 0774 - ${config.users.groups.media.name} -"
        # "d /mnt/local/media/movies 0774 ${toString config.hosting.media.radarr.userUid} ${toString config.users.groups.media.gid} -"
        # "d /mnt/local/media/shows 0774 ${toString config.hosting.media.sonarr.userUid} ${toString config.users.groups.media.gid} -"
        # "d /mnt/local/media/downloads 0774 ${toString config.hosting.media.qbittorrent.userUid} ${toString config.users.groups.media.gid} -"
        # "d /mnt/local/media/music 0774 ${toString config.hosting.media.lidarr.userUid} ${toString config.users.groups.media.gid} -"
        # "d /mnt/local/media/books 0774 ${toString config.hosting.media.bookshelf.userUid} ${toString config.users.groups.media.gid} -"
        # "d /mnt/local/media/bookdrop 0774 ${toString config.hosting.media.bookshelf.userUid} ${toString config.users.groups.media.gid} -"
      ];
    };
  }
