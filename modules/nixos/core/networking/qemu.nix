{
  config,
  lib,
  ...
}: let
  cfg = config.core.networking.qemu;
in {
  options.core.networking.qemu = {
    enable = lib.mkEnableOption "QEMU VM networking profile";
    interface = lib.mkOption {
      type = lib.types.str;
      default = "enp6s18";
      description = "The network interface to configure for DHCP (standard for Proxmox QEMU)";
    };
  };

  config = lib.mkIf cfg.enable {
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

      firewall.enable = lib.mkDefault true;
    };

    services.resolved.enable = true;

    # Enable QEMU Guest Agent for Proxmox integration
    services.qemuGuest.enable = true;
  };
}
