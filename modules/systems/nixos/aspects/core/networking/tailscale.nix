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
          # Node key and tailnet login.
          environment.persistence."/persist".directories = [
            {
              directory = "/var/lib/tailscale";
              mode = "0700";
            }
          ];
        }
        (lib.mkIf config.networking.networkmanager.enable {
          networking.networkmanager.unmanaged = [ config.services.tailscale.interfaceName ];
        })
      ]);
  };
}
