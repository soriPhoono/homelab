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
      ./prowlarr.nix
      ./sonarr.nix
      ./radarr.nix
      ./jellyfin.nix
      ./seerr.nix
      ./lidarr.nix
      ./navidrome.nix
      ./bookshelf.nix
      ./kavita.nix
    ];

    options.hosting.media = {
      enable = mkEnableOption "Enable media server stack on device";
    };

    config = mkIf cfg.enable {
      hosting = {
        enable = true;
        media = {
          qbittorrent.enable = true;
          prowlarr.enable = true;
          radarr.enable = true;
          sonarr.enable = true;
          jellyfin.enable = true;
          seerr.enable = true;

          lidarr.enable = true;
          navidrome.enable = true;

          bookshelf.enable = true;
          kavita.enable = true;
        };
      };

      systemd.tmpfiles.rules = [
        "d /mnt/local/media 0755 microserver microserver -"
        "d /mnt/local/media/downloads 0755 microserver microserver -"
        "d /mnt/local/media/movies 0755 microserver microserver -"
        "d /mnt/local/media/shows 0755 microserver microserver -"
        "d /mnt/local/media/music 0755 microserver microserver -"
        "d /mnt/local/media/books 0755 microserver microserver -"
      ];
    };
  }
