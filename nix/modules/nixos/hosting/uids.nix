# Centralized UID/GID registry for all hosting services.
#
# Every container service gets a unique, explicit UID and GID so there's
# no risk of collision. Each submodule imports this file for its option
# defaults, and the user/group definitions assign `uid`/`gid` via mkDefault
# so overrides are still possible.
#
# UID range: 901-949 for media services
#             980 for the shared media group
{
  lib,
  config,
  ...
}: let
  hostingCfg = config.hosting;
in
  with lib; {
    users = concatLists [
      (mkIf hostingCfg.media.enable [
        "qbittorrent"
        "prowlarr"
        "sonarr"
        "radarr"
        "jellyfin"
        "seerr"
      ])
    ];

    groups = [
      (mkIf hostingCfg.media.enable "media")
    ];

    # media = {
    #   navidrome = {
    #     uid = 907;
    #     gid = 907;
    #   };

    #   lidarr = {
    #     uid = 908;
    #     gid = 908;
    #   };

    #   bookshelf = {
    #     uid = 909;
    #     gid = 909;
    #   };

    #   booklore = {
    #     uid = 910;
    #     gid = 910;
    #   };
    # };
  }
