{
  den.aspects.spookyskelly.core.office.onlyoffice = {
    homeManager = { pkgs, ... }: {
      home.packages = [ pkgs.onlyoffice-desktopeditors ];
    };
  };
}
