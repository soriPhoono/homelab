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
          "d ${configurationDirectory} 0755 microserver microserver -"
        ];

        virtualisation.oci-containers.containers.${name} = mkMerge [
          (mkContainer {
            inherit name cfg config;
            image = "linuxserver/jellyfin:10.11.11";
            serviceName = "media";
            servicePort = 8096;
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
          "--device=${cfg.acceleration.renderDevice}:${cfg.acceleration.renderDevice}"
          "--device=${cfg.acceleration.cardDevice}:${cfg.acceleration.cardDevice}"
        ];
      })
    ]);
  }
