{ den, ... }: {
  den.aspects.desktop.platforms.flatpak = {
    includes = [
      den.aspects.desktop
    ];
    nixos = {
      services.flatpak.enable = true;
      # System-wide installations and remotes.
      environment.persistence."/persist".directories = [ "/var/lib/flatpak" ];
    };
  };
}
