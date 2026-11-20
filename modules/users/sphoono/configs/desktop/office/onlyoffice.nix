{
  den.aspects.sphoono.desktop.office = {
    homeManager = { pkgs, ... }: {
      home.packages = [ pkgs.onlyoffice-desktopeditors ];
    };
  };
}
