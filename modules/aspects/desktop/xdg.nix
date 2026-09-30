{ den, ... }: {
  den.aspects.desktop = {
    includes = [
      den.aspects.desktop.xdg
    ];
    xdg = {
      nixos.xdg.portal = {
        enable = true;
        config.common.default = "*";
        xdgOpenUsePortal = true;
      };
      homeManager.xdg = {
        enable = true;
        autostart = {
          enable = true;
          readOnly = true;
        };
        mimeApps.enable = true;
        userDirs = {
          enable = true;
          createDirectories = true;
        };
        portal = {
          enable = true;
          xdgOpenUsePortal = true;
          config.common.default = "*";
        };
        terminal-exec.enable = true;
      };
      portals.gtk = {
        nixos = { pkgs, ... }: {
          xdg.portal.extraPortals = with pkgs; [
            xdg-portal-gtk
          ];
        };
        homeManager = { pkgs, ... }: {
          xdg.portal.extraPortals = with pkgs; [
            xdg-portal-gtk
          ];
        };
      };
      portals.kde = {
        nixos = { pkgs, ... }: {
          xdg.portal.extraPortals = with pkgs.kdePackages; [
            xdg-desktop-portal-kde
          ];
        };
        homeManager = { pkgs, ... }: {
          xdg.portal.extraPortals = with pkgs.kdePackages; [
            xdg-desktop-portal-kde
          ];
        };
      };
    };
  };
}
