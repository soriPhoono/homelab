{ den, lib, ... }: {
  den = {
    aspects.desktop.tools.virtualbox = {
      # enableExtensionPack pulls in virtualbox-extpack, which is unfree.
      includes = [ (den.batteries.unfree [ "virtualbox-extpack" ]) ];
      nixos.virtualisation.virtualbox.host = {
        enable = true;
        enableExtensionPack = true;
      };
    };
    schema.host.includes = [
      ({ user, ... }: {
        nixos = { config, ... }: {
          users.groups.vboxusers.members = lib.mkIf config.virtualisation.virtualbox.host.enable [
            user.userName
          ];
        };
      })
    ];
  };
}
