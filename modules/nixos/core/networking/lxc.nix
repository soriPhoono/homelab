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
    assertions = [
      {
        assertion = !config.core.networking.network-manager.enable;
        message = "NetworkManager cannot be enabled with this module";
      }
      {
        assertion = !config.core.networking.qemu.enable;
        message = "QEMU cannot be enabled with this module";
      }
    ];

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
      firewall.enable = false;
    };

    services.resolved.enable = true;

    systemd.services.nsncd = {
      serviceConfig = {
        # This stops systemd from attempting to create a new User Namespace
        PrivateUsers = lib.mkForce false;

        # This prevents systemd from using 'unshare' to restrict namespaces
        RestrictNamespaces = lib.mkForce false;

        # Standard LXC overrides for systemd units
        ProcSubset = "all";
        ProtectControlGroups = lib.mkForce false;
        ProtectKernelTunables = lib.mkForce false;
        NoNewPrivileges = lib.mkForce false;
      };
    };
  };
}
