{ lib, ... }: {
  den.aspects.core.networking.network-manager = {
    nixos = { pkgs, ... }: {
      imports = [
        ./_private
      ];
      systemd.network.wait-online.enable = lib.mkForce false; # ASK
      networking.networkmanager = {
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
  };
}
