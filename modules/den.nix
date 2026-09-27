{
  den,
  lib,
  ...
}:
{
  den = {
    default = {
      includes = [
        den.batteries.define-user
        den.batteries.hostname
        (den.batteries.unfree [ "rar" ])
      ];
      nixos = { pkgs, ... }: {
        environment.systemPackages = with pkgs; [
          wget
          git
          p7zip
          rar
        ];
        console = {
          keyMap = lib.mkDefault "us";
          packages = with pkgs; [
            terminus_font
          ];
          font = "Lat2-Terminus16";
        };
        i18n.defaultLocale = lib.mkDefault "en_US.UTF-8";
        system.stateVersion = lib.mkDefault "26.11";
      };
      homeManager = { pkgs, ... }: {
        home.packages = with pkgs; [
          wget
          git
          p7zip
          rar
        ];
        xdg = {
          enable = true;
          mimeApps.enable = true;
          userDirs = {
            enable = true;
            createDirectories = true;
          };
        };
        programs.home-manager.enable = true;
        home.stateVersion = lib.mkDefault "26.11";
      };
    };
    schema.user.classes = lib.mkDefault [ "homeManager" ];
  };
}
