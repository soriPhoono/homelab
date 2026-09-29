{ den, ... }: {
  den.aspects.desktop = {
    includes = [
      den.aspects.desktop.xdg-portal
    ];
    xdg-portal = {
      nixos = {
        xdg.portal = {
          enable = true;
          config.common.default = "*";
          xdgOpenUsePortal = true;
        };
      };
      gtk = {
        nixos = { pkgs, ... }: {
          xdg.portal = {
            extraPortals = with pkgs; [
              xdg-portal-gtk
            ];
          };
        };
      };
    };
  };
}
