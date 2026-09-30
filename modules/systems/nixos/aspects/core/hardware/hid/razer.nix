{ lib, ... }: {
  den.aspects.core.hardware.hid.razer = { host, ... }: {
    nixos = { pkgs, ... }: {
      environment.systemPackages = with pkgs; [
        polychromatic
      ];
      hardware.openrazer = {
        enable = true;
        users = lib.mapAttrsToList (_: user: user.userName) host.users;
      };
    };
  };
}
