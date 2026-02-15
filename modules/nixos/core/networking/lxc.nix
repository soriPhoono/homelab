{
  config,
  lib,
  ...
}: let
  cfg = config.core.networking.lxc;
in {
  options.core.networking.lxc = {
    enable = lib.mkEnableOption "LXC container networking profile";
  };

  config = lib.mkIf cfg.enable {
    # LXC containers often don't support standard NetworkManager features well
    # or don't need them. systemd-networkd is lighter and more suitable.
    networking = {
      useDHCP = false;
      useNetworkd = true;

      # Disable wifi/wpa_supplicant explicitly
      wireless.enable = false;
      wireless.iwd.enable = false;

      # Configure eth0 for DHCP (standard for LXC)
      interfaces.eth0.useDHCP = true;

      # Disable firewall by default in LXC? No, keep it configurable.
      # But often LXC containers are behind a bridge/NAT.
      firewall.enable = lib.mkDefault true;
    };

    services.resolved.enable = true;

    # Ensure NetworkManager is disabled if this is enabled
    core.networking.network-manager.enable = false;
  };
}
