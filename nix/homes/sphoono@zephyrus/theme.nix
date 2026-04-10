{
  home.sessionVariables = {
    GTK_THEME = "adwaita-dark";
  };

  dconf = {
    enable = true;
    settings = {
      "org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
      };
    };
  };
}
