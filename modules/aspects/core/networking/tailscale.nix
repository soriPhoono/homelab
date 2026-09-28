{
  den.aspects.core.networking.tailscale = {
    nixos = {
      services.tailscale = {
        enable = true;
        openFirewall = true;
        disableUpstreamLogging = true;
      };
    };
  };
}
