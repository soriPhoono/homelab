{ inputs, den, ... }: {
  den.aspects.spookyskelly = {
    includes = [
      den.aspects.nur
    ];
    homeManager = {
      imports = [
        inputs.zen-browser.homeModules.twilight

        ./_private
      ];
      xdg.mimeApps.defaultApplications =
        let
          browser = [ "zen-twilight.desktop" ];
        in
        {
          "text/html" = browser;
          "text/xml" = browser;
          "x-scheme-handler/http" = browser;
          "x-scheme-handler/https" = browser;
          "x-scheme-handler/about" = browser;
          "x-scheme-handler/unknown" = browser;
        };
    };
  };
}
