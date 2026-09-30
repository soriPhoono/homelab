{ den, ... }: {
  den.aspects.desktop.environments.kde = {
    includes = [
      den.aspects.desktop

      den.aspects.desktop.greeters.sddm

      den.aspects.desktop.platforms.flatpak
    ];
    nixos = { pkgs, ... }: {
      environment.systemPackages =
        with pkgs;
        with kdePackages;
        [
          discover
          ksystemlog
        ];
      services.desktopManager.plasma6.enable = true;
    };
  };
}
