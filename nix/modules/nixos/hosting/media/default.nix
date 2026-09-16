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
      ./bookshelf.nix
    ];

    options.hosting.media = {
      enable = mkEnableOption "Enable media server stack on device";
    };

    config = mkIf cfg.enable {
      hosting.media = {
        qbittorrent = {
          enable = true;
          container.publication = [
            "tailscale"
          ];
        };
        prowlarr = {
          enable = true;
          container.publication = [
            "tailscale"
          ];
        };
        radarr = {
          enable = true;
          container.publication = [
            "tailscale"
          ];
        };
        sonarr = {
          enable = true;
          container.publication = [
            "tailscale"
          ];
        };
        lidarr = {
          enable = true;
          container.publication = [
            "tailscale"
          ];
        };
        bookshelf = {
          enable = true;
          container.publication = [
            "tailscale"
          ];
        };
        jellyfin = {
          enable = true;
          container.publication = [
            "tailscale"
          ];
        };
        seerr = {
          enable = true;
          container.publication = [
            "tailscale"
          ];
        };
      };

      systemd.tmpfiles.rules = [
        "d /mnt/local/media 0755 root root -"
        "d /mnt/local/media/downloads 0755 root root -"
        "d /mnt/local/media/movies 0755 root root -"
        "d /mnt/local/media/shows 0755 root root -"
        "d /mnt/local/media/music 0755 root root -"
        "d /mnt/local/media/books 0755 root root -"
      ];
    };
  }
