{
  den.aspects.sphoono.desktop.wm.supporting = {
    homeManager = _: {
      programs.ghostty.enable = true;
      xdg.mimeApps.defaultApplications =
        let
          terminal = [ "com.mitchellh.ghostty.desktop" ];
        in
        {
          "x-scheme-handler/terminal" = terminal;
          "application/x-terminal-emulator" = terminal;
        };
    };
  };
}
