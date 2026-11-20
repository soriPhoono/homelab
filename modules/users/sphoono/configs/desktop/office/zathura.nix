{
  den.aspects.sphoono.desktop = {
    homeManager = {
      programs.zathura.enable = true;
      xdg.mimeApps.defaultApplications =
        let
          pdfReader = [ "org.pwmt.zathura.desktop" ];
        in
        {
          "application/pdf" = pdfReader;
        };
    };
  };
}
