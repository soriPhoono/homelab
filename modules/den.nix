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
        console = {
          keyMap = lib.mkDefault "us";
          packages = with pkgs; [
            terminus_font
          ];
          font = "Lat2-Terminus16";
        };
        i18n.defaultLocale = lib.mkDefault "en_US.UTF-8";
        security.sudo = {
          execWheelOnly = true;
          extraConfig = ''
            Defaults timestamp_timeout=15
            Defaults lecture=always
          '';
        };
        users.mutableUsers = lib.mkDefault false;
        system.stateVersion = lib.mkDefault "26.11";
      };
      homeManager = {
        programs.home-manager.enable = true;
        home.stateVersion = lib.mkDefault "26.11";
      };
    };
    schema.user.classes = lib.mkDefault [ "homeManager" ];
  };
}
