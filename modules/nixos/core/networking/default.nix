{
  lib,
  config,
  hostName,
  ...
}: let
  cfg = config.core.networking;
in
  with lib; {
    imports = [
      ./openssh.nix
      ./network-manager.nix
      ./tailscale.nix
    ];

    options.core.networking = {
      ipv4_address = mkOption {
        type = with types; nullOr str;
        default = null;
        description = "The static ipv4 address to give to the basic ethernet adapter, NOT compatable with network manager as that demands control over all network devices on host";
        example = "192.168.1.34";
      };

      ipv6_address = mkOption {
        type = with types; nullOr str;
        default = null;
        description = "The static ipv6 address to give to the basic ethernet adapter, NOT compatable with network manager as that demands control over all network devices on host";
        example = "2a01:4f8:1c1b:16d0::1";
      };
    };

    config = {
      networking = mkMerge [
        {
          inherit hostName;
          nftables.enable = true;
        }

        (mkIf (!cfg.network-manager.enable) {
          interfaces.eth0 = {
            ipv4.addresses = mkIf (cfg.ipv4_address != null) [
              {
                address = cfg.ipv4_address;
                prefixLength = 24;
              }
            ];
            ipv6.addresses = mkIf (cfg.ipv6_address != null) [
              {
                address = cfg.ipv6_address;
                prefixLength = 64;
              }
            ];
          };
        })
      ];

      services.resolved.enable = true;
    };
  }
