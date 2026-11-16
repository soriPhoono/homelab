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
      # Saved connections with their secrets, and the stable-MAC seed.
      environment.persistence."/persist".directories = [
        {
          directory = "/etc/NetworkManager/system-connections";
          mode = "0700";
        }
        "/var/lib/NetworkManager"
      ];
    };
  };
}
