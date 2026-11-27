{
  den.aspects.sphoono.core.office.libreoffice = {
    homeManager = { pkgs, ... }: {
      home.packages = [ pkgs.libreoffice ];
    };
  };
}
