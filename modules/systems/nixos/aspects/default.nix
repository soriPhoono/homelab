{ inputs, lib, ... }: {
  flake-file.inputs.nix-index-database.url = "github:nix-community/nix-index-database";
  den.default.nixos = { pkgs, ... }: {
    imports = [
      inputs.nix-index-database.nixosModules.nix-index
    ];
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
  };
}
