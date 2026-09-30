{ den, ... }: {
  den.aspects.desktop.platforms.flatpak = {
    includes = [
      den.aspects.desktop
    ];
    nixos.services.flatpak.enable = true;
  };
}
