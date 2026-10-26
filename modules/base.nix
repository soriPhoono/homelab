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
      ];
      nixos = {
        system.stateVersion = lib.mkDefault "26.11";
        # Desktop sessions (KDE's GTK sync) write files HM also manages.
        home-manager.backupFileExtension = lib.mkDefault "hm-backup";
      };
      homeManager = {
        programs.home-manager.enable = true;
        home.stateVersion = lib.mkDefault "26.11";
      };
    };
    schema.user.classes = lib.mkDefault [ "homeManager" ];
  };
}
