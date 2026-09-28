{ den, lib, ... }: {
  den.aspects.core.networking.tailscale = { host, ... }: {
    nixos =
      { config, ... }:
      (lib.mkMerge [
        {
          services.tailscale = {
            enable = true;
            useRoutingFeatures = "both";
            openFirewall = true;
            disableUpstreamLogging = true;
          };
        }
        (lib.mkIf (host.hasAspect den.aspects.core.networking.network-manager) {
          networking.networkmanager.unmanaged = [ config.services.tailscale.interfaceName ];
        })
      ]);
  };
}
