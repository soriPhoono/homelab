{ lib, ... }: {
  den.aspects.core.networking.tailscale = {
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
        (lib.mkIf config.networking.networkmanager.enable {
          networking.networkmanager.unmanaged = [ config.services.tailscale.interfaceName ];
        })
      ]);
  };
}
