{ den, ... }: {
  den.aspects.desktop.environments.kde = _: {
    includes = [
      den.aspects.desktop

      den.aspects.desktop.greeters.sddm

      den.aspects.desktop.platforms.flatpak

      den.aspects.desktop.xdg.portals.kde
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
