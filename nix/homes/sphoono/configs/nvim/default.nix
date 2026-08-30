{
  lib,
  pkgs,
  ...
}: {
  imports = map (settings: {programs.nvf.settings = settings;}) (
    import ./modules.nix {inherit lib pkgs;}
  );
}
