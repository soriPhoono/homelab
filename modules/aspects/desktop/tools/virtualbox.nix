{
  den = {
    aspects.desktop.tools.virtualbox.nixos.virtualization.virtualbox.host = {
      enable = true;
      enableExtensionPack = true;
    };
    schema.host.includes = [
      ({ user, ... }: {
        nixos.users.groups.vboxusers.members = [
          user.userName
        ];
      })
    ];
  };
}
