{
  den.aspects.sphoono.desktop = {
    # home-manager has no programs.telegram module; the package is enough.
    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.telegram-desktop ];
      };
  };
}
