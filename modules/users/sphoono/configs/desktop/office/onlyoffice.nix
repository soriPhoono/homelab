{
  den.aspects.sphoono.desktop = {
    homeManager = { pkgs, ... }: {
      home.packages = [ pkgs.onlyoffice-desktopeditors ];
    };
  };
}
