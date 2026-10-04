{
  den.aspects.core.networking.network-manager = {
    nixos = { pkgs, ... }: {
      networking = {
        networkmanager = {
          enable = true;
          dns = "systemd-resolved";
          plugins = with pkgs; [
            networkmanager-openconnect
          ];
          wifi = {
            powersave = true;
            macAddress = "random";
          };
          ethernet.macAddress = "stable";
        };
      };
      services.resolved.enable = true;
    };
  };
}
