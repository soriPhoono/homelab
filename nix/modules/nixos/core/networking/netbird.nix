{
  lib,
  config,
  ...
}: let
  cfg = config.core.networking.netbird;
in
  with lib; {
    options.core.networking.netbird = {
      enable = mkEnableOption "Enable netbird client daemon";
    };

    config = mkIf cfg.enable {
      services.netbird.enable = true;

      # Allow necessary firewall traffic
      # Netbird uses a random port for peer-to-peer connection, but WireGuard standard is 51820.
      # However, for client usage usually random port is fine.
      # Also checkReversePath is often needed for VPNs.
      networking.firewall.checkReversePath = "loose";
    };
  }
