# Weylus: use a phone or tablet's browser as a stylus/touch input and
# screen mirror for this host. https://github.com/H-M-H/Weylus
{ lib, ... }: {
  den.aspects.core.hardware.hid.tablets.weylus = { host, ... }: {
    nixos = { config, ... }: {
      programs.weylus = {
        enable = true;
        # Members of the uinput group can synthesize input system-wide,
        # so only the host's own users are granted it.
        users = lib.mapAttrsToList (_: user: user.userName) host.users;
      };

      # Weylus serves plain HTTP (1701) and WebSocket (9001) with only an
      # optional access code, so expose it on the tailnet rather than on
      # whatever network a travelling host happens to be joined to.
      networking.firewall.interfaces.${config.services.tailscale.interfaceName}.allowedTCPPorts = [
        1701
        9001
      ];
    };
  };
}
