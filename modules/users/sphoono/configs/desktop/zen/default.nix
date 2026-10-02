{ inputs, den, ... }: {
  flake-file.inputs.zen-browser.url = "github:0xc000022070/zen-browser-flake";
  den.aspects.sphoono.configs.zen-browser = {
    includes = [
      den.aspects.nur
    ];
    homeManager = { ... }: {
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
      services.psd = {
        enable = true;
        resyncTimer = "10m";
      };
      stylix.targets.zen-browser.enable = false;
    };
  };
}
