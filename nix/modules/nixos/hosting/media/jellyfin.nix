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
        acceleration = {
          enable = mkEnableOption "Enable hardware acceleration (VAAPI/QSV) on the integrated GPU";

          renderDevice = mkOption {
            type = types.str;
            default = "/dev/dri/renderD128";
            description = ''
              The render device to use for hardware acceleration
            '';
          };

          cardDevice = mkOption {
            type = types.str;
            default = "/dev/dri/card0";
            description = ''
              The card device to use for hardware acceleration
            '';
          };
        };
      };
    };

    config = mkIf mediaCfg.enable (mkMerge [
      {
        systemd.tmpfiles.rules = [
          "d ${configurationDirectory} 0755 root root -"
        ];

        virtualisation.oci-containers.containers.${name} = mkMerge [
          (mkContainer {
            inherit name cfg config;
            image = "jellyfin/jellyfin:12";
            serviceName = "media";
            containerPort = 8096;
            homepage = {
              group = "Media";
              name = "Jellyfin";
              icon = "jellyfin.png";
              description = "Media streaming server";
            };
          })
          {
            volumes = [
              "${configurationDirectory}:/config"
              "/mnt/local/media/shows:/data/tvshows"
              "/mnt/local/media/movies:/data/movies"
              "/mnt/local/media/music:/data/music"
              "/mnt/local/media/books:/data/books"
            ];

            environment = {
              TZ = config.core.timeZone;

              # Preserve the LinuxServer volume layout while migrating to the
              # official image.
              JELLYFIN_CONFIG_DIR = "/config";
              JELLYFIN_DATA_DIR = "/config/data";
              JELLYFIN_CACHE_DIR = "/config/cache";
              JELLYFIN_LOG_DIR = "/config/log";
            };
          }
        ];
      }
      # ── Hardware acceleration (VAAPI/QSV) ────────────────
      (mkIf cfg.acceleration.enable {
        # Use mkBefore so this is prepended to (not override) any user-set extraOptions
        virtualisation.oci-containers.containers.${name}.extraOptions = mkBefore [
          # Pass the integrated GPU device for VAAPI (AMD/Intel) or QSV (Intel)
          "--device=${cfg.acceleration.renderDevice}:${cfg.acceleration.renderDevice}"
          "--device=${cfg.acceleration.cardDevice}:${cfg.acceleration.cardDevice}"
        ];
      })
    ]);
  }
