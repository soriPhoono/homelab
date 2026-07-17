{
  lib,
  config,
  ...
}: let
  inherit (lib.homelab.containers) mkContainerOption mkContainer;

  mediaCfg = config.hosting.media;
  cfg = mediaCfg.jellyfin;

  name = "jellyfin";
  configurationDirectory = "/var/lib/${name}";
in
  with lib; {
    options.hosting.media.jellyfin = mkContainerOption {
      inherit name;
      description = "Enable jellyfin container for media streaming";
      extraOptions = {
        acceleration.enable = mkEnableOption "Enable hardware acceleration (VAAPI/QSV) on the integrated GPU";
      };
    };

    config = mkIf mediaCfg.enable (mkMerge [
      {
        systemd.tmpfiles.rules = [
          "d ${configurationDirectory} 0755 microserver microserver -"
        ];

        virtualisation.oci-containers.containers.${name} = mkMerge [
          (mkContainer {
            inherit name cfg config;
            image = "linuxserver/jellyfin:10.11.11";
            subdomain = "media";
            port = 8096;
            publish = true;
          })
          {
            volumes = [
              "${configurationDirectory}:/config"
              "/mnt/local/media/shows:/data/tvshows"
              "/mnt/local/media/movies:/data/movies"
              "/mnt/local/media/music:/data/music"
            ];

            environment = {
              PUID = "0";
              PGID = "0";
              TZ = config.core.timeZone;
            };
          }
        ];
      }
      # ── Hardware acceleration (VAAPI/QSV) ────────────────
      (mkIf cfg.acceleration.enable {
        users.users.microserver.extraGroups = ["render" "video"];
        # Use mkBefore so this is prepended to (not override) any user-set extraOptions
        virtualisation.oci-containers.containers.${name}.extraOptions = mkBefore [
          # Pass the integrated GPU device for VAAPI (AMD/Intel) or QSV (Intel)
          "--device=/dev/dri/renderD128:/dev/dri/renderD128"
          "--device=/dev/dri/card0:/dev/dri/card0"
        ];
      })
    ]);
  }
