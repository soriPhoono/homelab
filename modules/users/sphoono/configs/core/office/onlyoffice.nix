{
  den.aspects.sphoono.core.office.onlyoffice = {
    homeManager = { pkgs, ... }: {
      home.packages = [ pkgs.onlyoffice-desktopeditors ];
    };
  };
}
