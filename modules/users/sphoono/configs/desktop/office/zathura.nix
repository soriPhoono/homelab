{
  den.aspects.sphoono.desktop.office = {
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
