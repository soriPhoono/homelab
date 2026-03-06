{
  config,
  lib,
  ...
}: let
  cfg = config.core.networking.qemu;
in
  with lib; {
    options.core.networking.qemu = {
      enable = mkEnableOption "QEMU VM networking profile";
      interface = mkOption {
        type = types.str;
        default = "ens18";
        description = "The network interface to configure for DHCP (standard for Proxmox QEMU)";
      };
    };

    config = mkIf cfg.enable {
      assertions = [
        {
          assertion = !config.core.networking.network-manager.enable;
          message = "NetworkManager cannot be enabled with this module";
        }
        {
          assertion = !config.core.networking.lxc.enable;
          message = "LXC cannot be enabled with this module";
        }
      ];

      # QEMU VMs on Proxmox typically use systemd-networkd for reliable cloud-init/DHCP
      networking = {
        useDHCP = false;
        useNetworkd = true;

        # Disable wifi/wpa_supplicant
        wireless.enable = false;
        wireless.iwd.enable = false;

        # Configure the primary interface for DHCP
        interfaces."${cfg.interface}".useDHCP = true;

        firewall.enable = false;
      };

      services.resolved.enable = true;

      # Enable QEMU Guest Agent for Proxmox integration
      services.qemuGuest.enable = true;
    };
  }
