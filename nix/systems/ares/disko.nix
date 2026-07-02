{
  disko.devices = {
    mdadm = {
      games = {
        type = "mdadm";
        level = 0;
        metadata = "1.2";

        content = {
          type = "btrfs";
          extraArgs = ["-f"];
          subvolumes = {
            "/wolf-fs" = {
              mountOptions = [
                "compress=zstd"
                "noatime"
              ];
              mountpoint = "/etc/wolf";
            };
          };
        };
      };

      storage = {
        type = "mdadm";
        level = 0;
        metadata = "1.2";

        content = {
          type = "btrfs";
          extraArgs = ["-f"];
          subvolumes = {
            "/media" = {
              mountOptions = [
                "compress=zstd"
                "noatime"
              ];
              mountpoint = "/mnt/local";
            };
          };
        };
      };
    };

    disk = {
      main = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-Samsung_SSD_970_EVO_Plus_1TB_S6S1NS0T513796P";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = ["umask=0077"];
              };
            };
            luks = {
              size = "100%";
              content = {
                type = "luks";
                name = "crypted";
                passwordFile = "/tmp/password.key"; # Interactive
                settings.allowDiscards = true;
                content = {
                  type = "btrfs";
                  extraArgs = ["-f"];
                  subvolumes = {
                    "/root" = {
                      mountpoint = "/";
                      mountOptions = [
                        "compress=zstd"
                        "noatime"
                      ];
                    };
                    "/home" = {
                      mountpoint = "/home";
                      mountOptions = [
                        "compress=zstd"
                        "noatime"
                      ];
                    };
                    "/nix" = {
                      mountpoint = "/nix";
                      mountOptions = [
                        "compress=zstd"
                        "noatime"
                      ];
                    };
                  };
                };
              };
            };
          };
        };
      };

      games-1 = {
        type = "disk";
        device = "/dev/disk/by-id/ata-Samsung_SSD_870_EVO_1TB_S6PTNM0T318657N";
        content = {
          type = "gpt";
          partitions = {
            primary = {
              size = "100%";
              content = {
                type = "mdraid";
                name = "games";
              };
            };
          };
        };
      };
      games-2 = {
        type = "disk";
        device = "/dev/disk/by-id/ata-Samsung_SSD_870_EVO_1TB_S6PTNM0T904070F";
        content = {
          type = "gpt";
          partitions = {
            primary = {
              size = "100%";
              content = {
                type = "mdraid";
                name = "games";
              };
            };
          };
        };
      };

      storage-1 = {
        type = "disk";
        device = "/dev/disk/by-id/ata-ST2000DM008-2FR102_ZFL5RYF2";
        content = {
          type = "gpt";
          partitions = {
            primary = {
              size = "100%";
              content = {
                type = "mdraid";
                name = "storage";
              };
            };
          };
        };
      };
      storage-2 = {
        type = "disk";
        device = "/dev/disk/by-id/ata-ST2000DM008-2UB102_ZFL8NHGS";
        content = {
          type = "gpt";
          partitions = {
            primary = {
              size = "100%";
              content = {
                type = "mdraid";
                name = "storage";
              };
            };
          };
        };
      };
    };
  };
}
