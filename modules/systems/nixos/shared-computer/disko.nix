{ inputs, lib, ... }:
{
  den.aspects.shared-computer.nixos = { config, ... }: {
    imports = [ inputs.disko.nixosModules.disko ];

    disko.devices.disk.main = {
      type = "disk";
      device = "/dev/disk/by-id/nvme-SAMSUNG_MZVLQ1T0HBLB-00B00_S6F7NE0R217324";
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
              mountOptions = [ "umask=0077" ];
            };
          };
          luks = {
            size = "100%";
            content = {
              type = "luks";
              name = "crypted";
              # Only read when formatting; unlocking at boot prompts interactively.
              passwordFile = "/tmp/password.key";
              settings.allowDiscards = true;
              content = {
                type = "btrfs";
                extraArgs = [ "-f" ];
                subvolumes =
                  let
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                    ];
                  in
                  {
                    "/root" = {
                      mountpoint = "/";
                      inherit mountOptions;
                    };
                    "/home" = {
                      mountpoint = "/home";
                      inherit mountOptions;
                    };
                    "/nix" = {
                      mountpoint = "/nix";
                      inherit mountOptions;
                    };
                    # Only exists on a host installed with core.impermanence.
                    "/persist" = lib.mkIf config.environment.persistence."/persist".enable {
                      mountpoint = "/persist";
                      inherit mountOptions;
                    };
                  };
              };
            };
          };
        };
      };
    };
  };
}
