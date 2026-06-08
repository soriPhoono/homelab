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
  media = {
    # Shared media group — members are the service users
    group = {gid = 980;};

    qbittorrent = {
      uid = 901;
      gid = 901;
    };
    sonarr = {
      uid = 902;
      gid = 902;
    };
    radarr = {
      uid = 903;
      gid = 903;
    };
    prowlarr = {
      uid = 904;
      gid = 904;
    };
    seerr = {
      uid = 905;
      gid = 905;
    };
    jellyfin = {
      uid = 906;
      gid = 906;
    };
  };
}
